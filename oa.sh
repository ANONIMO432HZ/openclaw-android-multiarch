#!/usr/bin/env bash
# oa.sh — OpenClaw Management Orchestrator for Android
set -euo pipefail

PROJECT_DIR="$HOME/.openclaw-android"

if [ -f "$HOME/.openclaw-android/scripts/lib.sh" ]; then
    # shellcheck source=/dev/null
    source "$HOME/.openclaw-android/scripts/lib.sh"
fi

# Fallback values (Single Source of Truth is in lib.sh)
OA_VERSION="${OA_VERSION:-1.0.12}"
RED="${RED:-\033[0;31m}"
GREEN="${GREEN:-\033[0;32m}"
YELLOW="${YELLOW:-\033[1;33m}"
BLUE="${BLUE:-\033[0;34m}"
PURPLE="${PURPLE:-\033[0;35m}"
CYAN="${CYAN:-\033[0;36m}"
BOLD="${BOLD:-\033[1m}"
NC="${NC:-\033[0m}"

show_help() {
    show_banner "OpenClaw Android Professional CLI" "$PURPLE"
    echo "Usage: oa [command]"
    echo ""
    echo "Commands:"
    echo "  update         Update everything (OpenClaw + tools + patches)"
    echo "  install      Install optional components (code-server, tmux, etc.)"
    echo "  start          Start OpenClaw Gateway (Background/Manual options)"
    echo "  start:manual     Force manual foreground execution (Debug)"
    echo "  stop           Stop the background Gateway service"
    echo "  restart      Restart the Gateway service"
    echo "  logs           View real-time Gateway activity logs"
    echo "  status         Show comprehensive system and service status"
    echo "  setup-service   Configure Gateway as a persistent Termux service"
    echo "  fix-android       Apply essential Android compatibility patches"
    echo "  backup         Create a full backup of OpenClaw data"
    echo "  restore       Restore OpenClaw data from a backup"
    echo "  uninstall     Completely remove OpenClaw from Android"
    echo "  v|version    Show version information"
    echo "  help|-h        Show this help message"
    echo ""
}

# ── Command Implementations ──

cmd_update() {
    show_banner "OpenClaw — Update Module" "$PURPLE"
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
            echo -e "Run: ${CYAN}oa setup-service${NC} once."
            exit 1
        }
    else
        echo -e "${YELLOW}[INFO]${NC} termux-services not installed. Falling back to [Option 2]..."
        cmd_start_manual
    fi
}

cmd_start_manual() {
    echo -e "${YELLOW}Running OpenClaw gateway directly (Foreground)...${NC}"
    openclaw gateway
}

cmd_stop() {
    if command -v sv &>/dev/null; then
        echo -e "${YELLOW}Stopping OpenClaw gateway...${NC}"
        sv stop openclaw-gateway || true
        sleep 1
    fi
    
    # Identify process aggressively (Catches manual 'openclaw gateway' from any session)
    local PIDS
    PIDS=$(pgrep -f "openclaw gateway|node.*openclaw" | grep -v "$$" || echo "")
    
    if [ -n "$PIDS" ]; then
        echo -e "Cleaning up lingering processes ($PIDS)..."
        kill -9 $PIDS 2>/dev/null || true
    fi
    echo -e "${GREEN}[OK]${NC} Stopped."
}

cmd_status() {
    show_banner "OpenClaw Android — Status" "$PURPLE"
    
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
    if command -v sv &>/dev/null; then
        sv status openclaw-gateway || echo -e "  Service info: Not configured."
    else
        echo -e "  ${YELLOW}[WARN]${NC} termux-services not installed."
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

cmd_setup_service() {
    if [ -f "$PROJECT_DIR/scripts/setup-service.sh" ]; then
        bash "$PROJECT_DIR/scripts/setup-service.sh"
    else
        echo -e "${RED}[FAIL]${NC} setup-service.sh not found."
    fi
}

cmd_logs() {
    local LOGFILE="$HOME/.termux/services/openclaw-gateway/log/current"
    if [ ! -f "$LOGFILE" ]; then
         LOGFILE="$PROJECT_DIR/server.log"
    fi
    
    if [ -f "$LOGFILE" ]; then
         tail -f "$LOGFILE"
    else
         echo -e "${RED}[FAIL]${NC} No logs found."
         exit 1
    fi
}

cmd_uninstall() {
    show_banner "OpenClaw — Uninstaller" "$RED"
    echo -e "${YELLOW}[WARNING]${NC} This will remove OpenClaw and all its configuration."
    read -p "Are you sure? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Canceled."
        exit 0
    fi
    
    # 1. Stop and disable service
    echo -e "  Stopping and cleaning up processes..."
    cmd_stop >/dev/null 2>&1 || true
    
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
    start:manual|strt:man)  cmd_start_manual ;;
    stop|--stop|stp)         cmd_stop ;;
    restart|--restart|rst)   cmd_stop && cmd_start ;;
    logs|--logs|log)         cmd_logs ;;
    status|--status|st)      cmd_status ;;
    backup|--backup|bkp)     cmd_backup ;;
    restore|--restore|rst)   cmd_restore ;;
    fix-android|fix)        cmd_fix_android ;;
    setup-service|svc)      cmd_setup_service ;;
    uninstall|--uninstall|uninst) cmd_uninstall ;;
    v|version|--version|-v) echo "oa CLI v$OA_VERSION" ;;
    help|--help|h|"")       show_help ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
