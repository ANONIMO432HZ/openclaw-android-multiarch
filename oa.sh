#!/usr/bin/env bash
set -euo pipefail

# ── Configuration ──
PROJECT_DIR="$HOME/.openclaw-android"

# Load shared library (Single Source of Truth)
if [ -f "$HOME/.openclaw-android/scripts/lib.sh" ]; then
    # shellcheck source=/dev/null
    source "$HOME/.openclaw-android/scripts/lib.sh"
fi

# Fallback and common colors (if lib was not found or as common base)
OA_VERSION="${OA_VERSION:-1.0.12}"
RED="${RED:-\033[0;31m}"
GREEN="${GREEN:-\033[0;32m}"
YELLOW="${YELLOW:-\033[1;33m}"
BLUE="${BLUE:-\033[0;34m}"
PURPLE="${PURPLE:-\033[0;35m}"
CYAN="${CYAN:-\033[0;36m}"
BOLD="${BOLD:-\033[1m}"
NC="${NC:-\033[0m}"
REPO_BASE="${REPO_BASE:-https://raw.githubusercontent.com/ANONIMO432HZ/openclaw-android-multiarch/main}"

# Load optional backup functions
if [ -f "$HOME/.openclaw-android/scripts/backup.sh" ]; then
    # shellcheck source=/dev/null
    source "$HOME/.openclaw-android/scripts/backup.sh"
fi

# ── CLI Core Functions ──
show_help() {
    show_banner "OpenClaw on Android Professional CLI" "$PURPLE"
    echo "Usage: oa [command]"
    echo ""
    echo "Options:"
    echo "  --update|update        Update OpenClaw and Android patches"
    echo "  --install|install       Install optional tools (tmux, code-server, AI CLIs, etc.)"
    echo "  --uninstall|uninstall     Remove OpenClaw on Android"
    echo "  --backup|backup        Create a full backup of OpenClaw data"
    echo "  --restore|restore       Restore from a backup"
    echo "  --fix-android|fix-android   Patch OpenClaw core to fix 'not supported on Android' crash"
    echo "  --setup-service|setup-service Configure OpenClaw as a background service"
    echo "  --start|start           Start the OpenClaw gateway (background)"
    echo "  --stop|stop            Stop the background Gateway"
    echo "  --restart|restart         Restart the Gateway"
    echo "  --status|status          Show full installation and service status"
    echo "  --logs|logs            View live Gateway service logs"
    echo "  --version|version|v     Show version info"
    echo "  --help, -h     Show all available options"
    echo ""
}

show_version() {
    echo "oa v${OA_VERSION} (OpenClaw on Android)"

    local latest
    latest=$(curl -sfL --max-time 3 "$REPO_BASE/scripts/lib.sh" 2>/dev/null \
        | grep -m1 '^OA_VERSION=' | cut -d'"' -f2) || true

    if [ -n "${latest:-}" ]; then
        if [ "$latest" = "$OA_VERSION" ]; then
            echo -e "  ${GREEN}Up to date${NC}"
        else
            echo -e "  ${YELLOW}v${latest} available${NC} - run: oa --update"
        fi
    fi
}

cmd_update() {
    if ! command -v curl &>/dev/null; then
        echo -e "${RED}[FAIL]${NC} curl not found. Install it with: pkg install curl"
        exit 1
    fi

    mkdir -p "$PROJECT_DIR"
    local LOGFILE="$PROJECT_DIR/update.log"

    local TMPFILE
    TMPFILE=$(mktemp "${TMPDIR:-${PREFIX:-/tmp}/tmp}/update-core.XXXXXX.sh" 2>/dev/null) \
        || TMPFILE=$(mktemp "/tmp/update-core.XXXXXX.sh")

    if ! curl -sfL "$REPO_BASE/update-core.sh" -o "$TMPFILE"; then
        rm -f "$TMPFILE"
        echo -e "${RED}[FAIL]${NC} Failed to download update-core.sh"
        exit 1
    fi

    bash "$TMPFILE" 2>&1 | tee "$LOGFILE"
    rm -f "$TMPFILE"

    echo ""
    echo -e "${YELLOW}Log saved to $LOGFILE${NC}"
}

cmd_uninstall() {
    local UNINSTALL_SCRIPT="$PROJECT_DIR/uninstall.sh"

    if [ ! -f "$UNINSTALL_SCRIPT" ]; then
        echo -e "${RED}[FAIL]${NC} Uninstall script not found at $UNINSTALL_SCRIPT"
        echo ""
        echo "You can download it manually:"
        echo "  curl -sL $REPO_BASE/uninstall.sh -o $UNINSTALL_SCRIPT && chmod +x $UNINSTALL_SCRIPT"
        exit 1
    fi

    bash "$UNINSTALL_SCRIPT"
}

cmd_status() {
    show_banner "OpenClaw on Android — Status" "$GREEN"
    echo -e "${BOLD}Version${NC}"
    echo "  oa:          v${OA_VERSION}"

    local PLATFORM
    if command -v detect_platform &>/dev/null; then
        PLATFORM=$(detect_platform 2>/dev/null) || PLATFORM=""
    else
        PLATFORM=""
    fi
    
    if [ -n "$PLATFORM" ]; then
        echo "  Platform:    $PLATFORM"
    else
        echo -e "  Platform:    ${RED}not detected${NC}"
    fi

    echo ""
    echo -e "${BOLD}Environment${NC}"
    echo "  PREFIX:            ${PREFIX:-not set}"
    echo "  TMPDIR:            ${TMPDIR:-not set}"

    echo ""
    echo -e "${BOLD}Paths${NC}"
    local CHECK_DIRS=("$PROJECT_DIR" "${PREFIX:-}/tmp")
    for dir in "${CHECK_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            echo -e "  ${GREEN}[OK]${NC}   $dir"
        else
            echo -e "  ${RED}[MISS]${NC} $dir"
        fi
    done

    echo ""
    echo -e "${BOLD}Configuration${NC}"
    if grep -qF "OpenClaw on Android" "$HOME/.bashrc" 2>/dev/null; then
        echo -e "  ${GREEN}[OK]${NC}   .bashrc environment block present"
    else
        echo -e "  ${RED}[MISS]${NC} .bashrc environment missing"
    fi

    echo ""
    echo -e "${BOLD}Service Status${NC}"
    if command -v sv &>/dev/null; then
        sv status openclaw-gateway || echo -e "  Service info: Not configured."
    else
        echo -e "  ${YELLOW}[WARN]${NC} termux-services not installed."
    fi
    echo ""
}

# ── Main Entry Point ──
case "${1:-}" in
    --update|-update|update)
        cmd_update
        ;;
    --install|-install|install)
        if [ -f "$PROJECT_DIR/scripts/install-tools.sh" ]; then
            bash "$PROJECT_DIR/scripts/install-tools.sh"
        else
            echo -e "${RED}[FAIL]${NC} install-tools.sh not found. Run: oa --update"
            exit 1
        fi
        ;;
    --uninstall|-uninstall|uninstall)
        cmd_uninstall
        ;;
    --backup|-backup|backup)
        if command -v cmd_backup_create &>/dev/null; then
            cmd_backup_create
        else
            echo -e "${RED}[FAIL]${NC} Backup system not loaded."
            exit 1
        fi
        ;;
    --restore|-restore|restore)
        if command -v cmd_backup_restore &>/dev/null; then
            cmd_backup_restore
        else
            echo -e "${RED}[FAIL]${NC} Restore system not loaded."
            exit 1
        fi
        ;;
    --fix-android|-fix-android|fix-android)
        if [ -f "$PROJECT_DIR/scripts/patch-core.sh" ]; then
            bash "$PROJECT_DIR/scripts/patch-core.sh"
        else
            echo -e "${RED}[FAIL]${NC} patch-core.sh not found. Run: oa --update"
            exit 1
        fi
        ;;
    --setup-service|-setup-service|setup-service)
        if [ -f "$PROJECT_DIR/scripts/setup-service.sh" ]; then
            bash "$PROJECT_DIR/scripts/setup-service.sh"
        else
            echo -e "${RED}[FAIL]${NC} setup-service.sh not found. Run: oa --update"
            exit 1
        fi
        ;;
    --start|-start|start)
        show_banner "OpenClaw Initiation Options" "$PURPLE"
        
        echo -e "${CYAN}[Option 1: Background Service (Recommended)]${NC}"
        echo -e "  - Description: Runs as a persistent daemon via termux-services."
        echo -e "  - Benefits: Auto-restart on crash, survives SSH disconnect, auto-start on boot."
        echo -e "  - Usage: ${BOLD}oa start${NC}"
        echo -e ""
        echo -e "${YELLOW}[Option 2: Foreground Manual (Fast Debug)]${NC}"
        echo -e "  - Description: Runs directly in your current terminal session."
        echo -e "  - Benefits: Instant log output, close with Ctrl+C, best for quick debugging."
        echo -e "  - Usage: ${BOLD}oa start:manual${NC}"
        echo -e ""
        echo -e "${BOLD}-----------------------------------------${NC}"
        
        if command -v sv &>/dev/null; then
            echo -e "${GREEN}Executing [Option 1] now...${NC}"
            sv start openclaw-gateway || { 
                echo -e "${RED}[FAIL]${NC} Background service not found."
                echo -e "Run: ${CYAN}oa --setup-service${NC} to enable persistent background mode."
                echo -e "Or run: ${YELLOW}oa start:manual${NC} for manual foreground mode."
                exit 1
            }
        else
            echo -e "${YELLOW}[INFO]${NC} termux-services not detected. Falling back to [Option 2]..."
            $0 start:manual
        fi
        ;;
    --start:manual|start:manual)
        echo -e "${YELLOW}Running OpenClaw gateway directly (Foreground)...${NC}"
        openclaw gateway
        ;;
    --stop|-stop|stop)
        if command -v sv &>/dev/null; then
            echo -e "${YELLOW}Stopping OpenClaw gateway...${NC}"
            sv stop openclaw-gateway || true
            sleep 1
            
            # Identify process and force kill if still alive
            local PIDS
            PIDS=$(pgrep -f "node.*openclaw" || echo "")
            if [ -n "$PIDS" ]; then
                echo -e "${YELLOW}Cleaning up hanging processes ($PIDS)...${NC}"
                kill -9 $PIDS 2>/dev/null || true
            fi
            echo -e "${GREEN}[OK]${NC} Closed."
        else
            echo -e "${RED}[FAIL]${NC} termux-services not installed."
            exit 1
        fi
        ;;
    --logs|-logs|logs)
        local LOGFILE="$HOME/.termux/services/openclaw-gateway/log/current"
        if [ ! -f "$LOGFILE" ]; then
             # Standard location if sv-log is not used
             LOGFILE="$HOME/.termux/services/openclaw-gateway/run"
             echo -e "${YELLOW}[WARN]${NC} Service log file not found. Showing service script instead."
             cat "$LOGFILE"
             exit 0
        fi
        tail -f "$LOGFILE"
        ;;
    --status|-status|status)
        cmd_status
        ;;
    --version|-version|version|-v)
        show_version
        ;;
    --help|-help|help|-h|"")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown option: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
