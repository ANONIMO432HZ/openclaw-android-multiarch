#!/usr/bin/env bash
# oa.sh — OpenClaw Management Orchestrator for Android
set -euo pipefail

# Cambiamos esto para que no falle si se usa 'curl | bash'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"


PROJECT_DIR="$HOME/.openclaw-android"
if [ -f "$PROJECT_DIR/scripts/lib.sh" ]; then
    source "$PROJECT_DIR/scripts/lib.sh"
fi

# Fallback values if lib.sh is NOT found
OA_VERSION="${OA_VERSION:-1.0.12}"
RED="${RED:-\033[0;31m}"
GREEN="${GREEN:-\033[0;32m}"
YELLOW="${YELLOW:-\033[1;33m}"
BLUE="${BLUE:-\033[0;34m}"
PURPLE="${PURPLE:-\033[0;35m}"
BOLD="${BOLD:-\033[1m}"
NC="${NC:-\033[0m}"

# Fallback banner if lib.sh is not available
if ! command -v banner &>/dev/null; then
    banner() {
        echo -e "${BOLD}========================================${NC}"
        echo -e "${BOLD}  $1 v${2:-$OA_VERSION}${NC}"
        echo -e "${BOLD}========================================${NC}"
    }
fi

show_help() {
    banner "OpenClaw Android Professional CLI" "$PURPLE"
    echo "Usage: oa [command]"
    echo ""
    echo "Commands:"
    echo "  update       Update everything (OpenClaw + tools + patches)"
    echo "  install      Install optional components (code-server, tmux, etc.)"
    echo "  start        Start OpenClaw Gateway (Background)"
    echo "  start:fg     Start OpenClaw gateway (Foreground debug)"
    echo "  stop         Stop background processes"
    echo "  restart      Restart the Gateway"
    echo "  logs         View real-time background logs"
    echo "  status       Show comprehensive system and service status"
    echo "  fix-android  Apply essential Android compatibility patches"
    echo "  backup       Create a full backup of OpenClaw data"
    echo "  restore      Restore OpenClaw data from a backup"
    echo "  uninstall    Completely remove OpenClaw from Android"
    echo "  v|version    Show version info"
    echo "  help|-h      Show this help message"
    echo ""
}

# ── Command Implementations ──

cmd_update() {
    banner "OpenClaw — Update Module" "$PURPLE"
    echo "Checking for updates..."
    
    # Check current repo for oa/lib changes
    git pull origin main || true
    
    # Self-clean CRLF line endings (Windows to Linux fix)
    find "$PROJECT_DIR" -maxdepth 2 -name "*.sh" -exec sed -i 's/\r$//' {} + 2>/dev/null || true
    sed -i 's/\r$//' "$PREFIX/bin/oa" 2>/dev/null || true
    
    # Propagate changes to tools
    if command -v openclaw &>/dev/null; then
        echo "Updating OpenClaw Core..."
        npm install -g openclaw@latest
    fi
    
    # Re-patch just in case
    # Note: Using patch-android.sh as primary, fallback to old patch-core.sh
    if [ -f "$PROJECT_DIR/scripts/patch-android.sh" ]; then
        bash "$PROJECT_DIR/scripts/patch-android.sh"
    elif [ -f "$PROJECT_DIR/scripts/patch-core.sh" ]; then
        bash "$PROJECT_DIR/scripts/patch-core.sh"
    fi
    
    echo -e "${GREEN}[OK]${NC} Update cycle completed."
}

cmd_install() {
    if [ -f "$PROJECT_DIR/scripts/install-tools.sh" ]; then
        bash "$PROJECT_DIR/scripts/install-tools.sh"
    else
        echo -e "${RED}[FAIL]${NC} install-tools.sh not found."
        exit 1
    fi
}

cmd_start() {
    echo -e "${CYAN}Starting OpenClaw gateway in background...${NC}"
    # Prevent double starting
    cmd_stop >/dev/null 2>&1 || true
    
    mkdir -p "$PROJECT_DIR/logs"
    nohup openclaw gateway > "$PROJECT_DIR/server.log" 2>&1 &
    
    echo -e "  Waiting for server to initialize (approx. 5s)..."
    sleep 5
    
    if pgrep -f "openclaw gateway|node.*openclaw" >/dev/null; then
        echo -e "${GREEN}[OK]${NC} OpenClaw is running in the background."
        echo -e "     Logs: ${BOLD}oa logs${NC}"
    else
        echo -e "${RED}[FAIL]${NC} Failed to start. Check server.log"
    fi
}

cmd_start_fg() {
    echo -e "${YELLOW}Starting OpenClaw gateway in foreground...${NC}"
    openclaw gateway
}

cmd_stop() {
    echo -e "${YELLOW}Stopping OpenClaw gateway processes...${NC}"
    
    local PIDS=""
    local ALL_CANDIDATES
    ALL_CANDIDATES=$(pgrep -f "openclaw gateway|node.*openclaw" || echo "")
    
    if [ -n "$ALL_CANDIDATES" ]; then
        echo -e "Cleaning up lingering processes ($ALL_CANDIDATES)..."
        kill -9 $ALL_CANDIDATES 2>/dev/null || true
    else
        echo -e "No active gateway processes found."
    fi
    echo -e "${GREEN}[OK]${NC} Stopped."
}

cmd_status() {
    banner "OpenClaw Android — Status" "$PURPLE"
    
    echo -e "Version: v$OA_VERSION"
    echo -e "Root Directory: $PROJECT_DIR"
    
    # ── Platform Checks ──
    echo ""
    echo -e "${BOLD}Platform Environment${NC}"
    if [ -f "/data/data/com.termux/files/usr/bin/termux-info" ]; then
        echo -e "  OS: Termux (Android)"
        local ARCH
        ARCH=$(uname -m)
        echo -e "  Architecture: $ARCH"
    else
        echo -e "  OS: Non-Termux / Unsupported"
    fi
    
    # ── Tool Availability ──
    echo ""
    echo -e "${BOLD}Installed Components${NC}"
    local TOOLS=("openclaw" "code-server" "node" "git" "ssh")
    for tool in "${TOOLS[@]}"; do
        if command -v "$tool" &>/dev/null; then
            local VERSION
            VERSION=$($tool --version 2>/dev/null | head -n 1 || echo "unknown")
            echo -e "  ${GREEN}[INSTALLED]${NC} $tool ($VERSION)"
        else
            echo -e "  ${RED}[MISSING]${NC}   $tool"
        fi
    done

    # ── Gateway Status ──
    echo ""
    echo -e "${BOLD}Service Status${NC}"
    if pgrep -f "openclaw gateway|node.*openclaw" >/dev/null; then
        echo -e "  Status: ${GREEN}Running${NC}"
    else
        echo -e "  Status: ${RED}Stopped${NC}"
    fi
    echo ""
}

cmd_backup() {
    if [ -f "$PROJECT_DIR/scripts/backup.sh" ]; then
        source "$PROJECT_DIR/scripts/backup.sh"
        if command -v cmd_backup_create &>/dev/null; then
            cmd_backup_create
        else
            echo -e "${RED}[FAIL]${NC} cmd_backup_create not found in backup.sh."
        fi
    else
        echo -e "${RED}[FAIL]${NC} Backup system not found."
    fi
}

cmd_restore() {
    if [ -f "$PROJECT_DIR/scripts/backup.sh" ]; then
        source "$PROJECT_DIR/scripts/backup.sh"
        if command -v cmd_backup_restore &>/dev/null; then
            cmd_backup_restore
        else
            echo -e "${RED}[FAIL]${NC} cmd_backup_restore not found in backup.sh."
        fi
    else
        echo -e "${RED}[FAIL]${NC} Restore system not found."
    fi
}

cmd_fix_android() {
    if [ -f "$PROJECT_DIR/scripts/patch-android.sh" ]; then
        bash "$PROJECT_DIR/scripts/patch-android.sh"
    elif [ -f "$PROJECT_DIR/scripts/patch-core.sh" ]; then
        bash "$PROJECT_DIR/scripts/patch-core.sh"
    else
        echo -e "${RED}[FAIL]${NC} Patch system not found."
    fi
}

cmd_logs() {
    local LOGFILE="$PROJECT_DIR/server.log"
    # Fallback to old path if present
    if [ ! -f "$LOGFILE" ]; then
         LOGFILE="$HOME/.termux/services/openclaw-gateway/log/current"
    fi
    
    if [ -f "$LOGFILE" ]; then
         tail -f "$LOGFILE"
    else
         echo -e "${RED}[FAIL]${NC} No logs found at $LOGFILE"
         exit 1
    fi
}

cmd_uninstall() {
    banner "OpenClaw — Uninstaller" "$RED"
    echo -e "${YELLOW}[WARNING]${NC} This will remove OpenClaw and all its configuration."
    read -p "Are you sure? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Canceled."
        exit 0
    fi
    
    # 1. Stop and disable processes
    echo -e "  Stopping and cleaning up processes..."
    cmd_stop >/dev/null 2>&1 || true
    
    # Support legacy removal
    if command -v sv &>/dev/null; then
        sv-disable openclaw-gateway 2>/dev/null || true
    fi
    
    # 2. Remove files
    echo -e "  Removing CLI and files..."
    rm -rf "$PROJECT_DIR"
    rm -f "$PREFIX/bin/oa"
    
    # Remove bashrc markers
    if [ -f "$HOME/.bashrc" ]; then
        sed -i "/# >>> OpenClaw on Android >>>/,/# <<< OpenClaw on Android <<</d" "$HOME/.bashrc"
    fi
    
    echo -e "${GREEN}[OK]${NC} OpenClaw has been removed."
}

# ── Main Entry Point ──
case "${1:-}" in
    update|--update|up)     cmd_update ;;
    install|--install|inst)  cmd_install ;;
    start|--start|strt)      cmd_start ;;
    start:fg|--start:fg|strt:fg) cmd_start_fg ;;
    stop|--stop|stp)         cmd_stop ;;
    restart|--restart|rst)   cmd_stop && cmd_start ;;
    logs|--logs|log)         cmd_logs ;;
    status|--status|st)      cmd_status ;;
    backup|--backup|bkp)     cmd_backup ;;
    restore|--restore|rst)   cmd_restore ;;
    fix-android|fix)        cmd_fix_android ;;
    uninstall|--uninstall|uninst) cmd_uninstall ;;
    v|version|--version|-v) echo "oa CLI v$OA_VERSION" ;;
    help|--help|h|"")       show_help ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
