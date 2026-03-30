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
CYAN="${CYAN:-\033[0;36m}"
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
    echo ""
    echo "  start        Start OpenClaw Gateway (Background)"
    echo "  start:fg     Start OpenClaw gateway (Foreground debug)"
    echo "  stop         Stop background processes"
    echo "  logs         View real-time background logs"
    echo ""
    echo "  ui           Open the OpenClaw Dashboard (Control UI)"
    echo "  ui-config    Open the Configuration Wizard (credentials, channels, etc.)"
    echo "  onboard      Run the interactive Onboarding Wizard"
    echo "  config       Non-interactive config helpers (get/set/validate)"
    echo "  doctor       Health checks + quick fixes"
    echo ""
    echo "  status       Show comprehensive system and service status"
    echo "  fix-env      Fix environment variables in .bashrc"
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
    check_and_fix_env
    banner "OpenClaw — Update Module" "$PURPLE"
    cd "$PROJECT_DIR" || { echo -e "${RED}[FAIL]${NC} Impossible to access $PROJECT_DIR"; exit 1; }

    echo "Checking for script updates..."
    
    # Advanced Version Checking (Ported from omni.sh)
    git fetch --tags --force >/dev/null 2>&1 || true
    
    local LOCAL REMOTE
    LOCAL=$(git rev-parse HEAD 2>/dev/null || echo "0")
    REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "1")

    if [ "$LOCAL" != "$REMOTE" ]; then
        echo -e "${YELLOW}[UPDATE]${NC} New scripts found. Syncing repository..."
        
        # Protect local changes
        git stash push -m "oa-auto-stash" >/dev/null 2>&1 || true
        
        if git pull origin main; then
            git stash pop >/dev/null 2>&1 || true
            
            # Refresh formatting for Android
            find "$PROJECT_DIR" -maxdepth 2 -name "*.sh" -exec sed -i 's/\r$//' {} + 2>/dev/null || true
            [ -w "$PREFIX/bin/oa" ] && sed -i 's/\r$//' "$PREFIX/bin/oa" 2>/dev/null || true
            echo -e "${GREEN}[OK]${NC} Repository synchronized."
        fi
    else
        echo -e "${GREEN}[OK]${NC} Scripts are up-to-date."
    fi
    
    # Propagate changes to tools (OpenClaw Core)
    if command -v openclaw &>/dev/null; then
        echo "Updating OpenClaw Core via NPM..."
        npm install -g openclaw@latest
    fi
    
    # ── Critical Reconstruction Step ──
    # Always re-patch after 'npm install -g' as it overwrites our Android fixes
    echo "Re-applying Android compatibility patches..."
    if [ -f "$PROJECT_DIR/scripts/patch-android.sh" ]; then
        bash "$PROJECT_DIR/scripts/patch-android.sh"
    elif [ -f "$PROJECT_DIR/scripts/patch-core.sh" ]; then
        bash "$PROJECT_DIR/scripts/patch-core.sh"
    fi
    
    echo -e "${GREEN}[OK]${NC} Update cycle completed."
}

cmd_install() {
    check_and_fix_env
    if [ -f "$PROJECT_DIR/scripts/install-tools.sh" ]; then
        bash "$PROJECT_DIR/scripts/install-tools.sh"
    else
        echo -e "${RED}[FAIL]${NC} install-tools.sh not found."
        exit 1
    fi
}

# ── Helper: Verify and repair environment if needed (fast) ──
check_and_fix_env() {
    # Fast path: if variables are already set, skip
    if [ -n "${OA_GLIBC:-}" ] && [ -n "${CONTAINER:-}" ]; then
        return 0
    fi
    
    # Quick check: grep the .bashrc file (faster than sourcing)
    if grep -q "OA_GLIBC=" "$HOME/.bashrc" 2>/dev/null; then
        source "$HOME/.bashrc" 2>/dev/null || true
    fi
    
    # If still missing, run fix-env (rare case)
    if [ -z "${OA_GLIBC:-}" ] || [ -z "${CONTAINER:-}" ]; then
        bash "$PROJECT_DIR/scripts/setup-env.sh" 2>/dev/null || true
        source "$HOME/.bashrc" 2>/dev/null || true
    fi
}

cmd_update() {
    # Fast path: if variables are already set, skip
    if [ -n "${OA_GLIBC:-}" ] && [ -n "${CONTAINER:-}" ]; then
        return 0
    fi
    
    # Quick check: grep the .bashrc file (faster than sourcing)
    if grep -q "OA_GLIBC=" "$HOME/.bashrc" 2>/dev/null; then
        source "$HOME/.bashrc" 2>/dev/null || true
    fi
    
    # If still missing, run fix-env (rare case)
    if [ -z "${OA_GLIBC:-}" ] || [ -z "${CONTAINER:-}" ]; then
        bash "$PROJECT_DIR/scripts/setup-env.sh" 2>/dev/null || true
        source "$HOME/.bashrc" 2>/dev/null || true
    fi
}

cmd_start() {
    # Verify environment before starting
    check_and_fix_env
    
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
    check_and_fix_env
    echo -e "${YELLOW}Starting OpenClaw gateway in foreground...${NC}"
    openclaw gateway
}

cmd_stop() {
    check_and_fix_env
    echo -e "${YELLOW}Stopping OpenClaw gateway processes...${NC}"
    
    # Identify processes (excluding our current PID)
    local PIDS=""
    local ALL_CANDIDATES
    ALL_CANDIDATES=$(pgrep -f "openclaw gateway|node.*openclaw" || echo "")
    
    for pid in $ALL_CANDIDATES; do
        if [ "$pid" != "$$" ]; then
            PIDS="$PIDS $pid"
        fi
    done
    
    if [ -n "$PIDS" ]; then
        echo -e "Stopping matching processes (IDs:$PIDS)..."
        kill -9 $PIDS 2>/dev/null || true
    else
        echo -e "No active gateway processes found."
    fi
    echo -e "${GREEN}[OK]${NC} Stopped."
}

cmd_status() {
    check_and_fix_env
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
    check_and_fix_env
    if [ -f "$PROJECT_DIR/scripts/backup.sh" ]; then
        source "$PROJECT_DIR/scripts/backup.sh"
        if command -v perform_backup &>/dev/null; then
            perform_backup "$@"
        else
            echo -e "${RED}[FAIL]${NC} perform_backup not found in backup.sh."
        fi
    else
        echo -e "${RED}[FAIL]${NC} Backup system not found."
    fi
}

cmd_restore() {
    check_and_fix_env
    if [ -f "$PROJECT_DIR/scripts/backup.sh" ]; then
        source "$PROJECT_DIR/scripts/backup.sh"
        if command -v perform_restore &>/dev/null; then
            perform_restore "$@"
        else
            echo -e "${RED}[FAIL]${NC} perform_restore not found in backup.sh."
        fi
    else
        echo -e "${RED}[FAIL]${NC} Restore system not found."
    fi
}

cmd_fix_env() {
    banner "OpenClaw — Fix Environment" "$YELLOW"
    echo "This will repair the environment variables in ~/.bashrc"
    echo ""
    
    if [ -f "$PROJECT_DIR/scripts/setup-env.sh" ]; then
        echo "Running setup-env.sh..."
        bash "$PROJECT_DIR/scripts/setup-env.sh"
        
        # Reload bashrc
        source "$HOME/.bashrc"
        
        echo ""
        echo -e "${GREEN}[OK]${NC} Environment variables fixed."
        echo "  OA_GLIBC=$OA_GLIBC"
        echo "  CONTAINER=$CONTAINER"
        echo "  TMPDIR=$TMPDIR"
    else
        echo -e "${RED}[FAIL]${NC} setup-env.sh not found."
        exit 1
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
    check_and_fix_env
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
    check_and_fix_env
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

cmd_ui() {
    # Verify environment before running
    check_and_fix_env
    
    if ! command -v openclaw &>/dev/null; then
        echo -e "${RED}[FAIL]${NC} openclaw not found. Run the installer first."
        exit 1
    fi
    echo -e "${CYAN}Opening OpenClaw Dashboard...${NC}"
    openclaw dashboard
}

cmd_ui_config() {
    # Verify environment before running
    check_and_fix_env
    
    if ! command -v openclaw &>/dev/null; then
        echo -e "${RED}[FAIL]${NC} openclaw not found. Run the installer first."
        exit 1
    fi
    echo -e "${CYAN}Opening Configuration Wizard...${NC}"
    openclaw configure
}

cmd_onboard() {
    # Verify environment before running
    check_and_fix_env
    
    if ! command -v openclaw &>/dev/null; then
        echo -e "${RED}[FAIL]${NC} openclaw not found. Run the installer first."
        exit 1
    fi
    echo -e "${CYAN}Starting Onboarding Wizard...${NC}"
    openclaw onboard
}

cmd_config() {
    check_and_fix_env
    if ! command -v openclaw &>/dev/null; then
        echo -e "${RED}[FAIL]${NC} openclaw not found. Run the installer first."
        exit 1
    fi
    shift
    openclaw config "$@"
}

cmd_doctor() {
    check_and_fix_env
    if ! command -v openclaw &>/dev/null; then
        echo -e "${RED}[FAIL]${NC} openclaw not found. Run the installer first."
        exit 1
    fi
    echo -e "${CYAN}Running health checks...${NC}"
    openclaw doctor
}

# ── Main Entry Point ──
case "${1:-}" in
    update|--update|up)       cmd_update "$@" ;;
    install|--install|inst)   cmd_install "$@" ;;
    start|--start|strt)       cmd_start ;;
    start:fg|--start:fg|strt:fg) cmd_start_fg ;;
    stop|--stop|stp)          cmd_stop ;;
    logs|--logs|log)          cmd_logs ;;
    ui|--ui|dashboard)        cmd_ui ;;
    ui-config|--ui-config|config-wizard) cmd_ui_config ;;
    onboard|--onboard)        cmd_onboard ;;
    config|--config|cfg)      cmd_config "$@" ;;
    doctor|--doctor|doc)      cmd_doctor ;;
    status|--status|st)       cmd_status ;;
    backup|--backup|bkp)      cmd_backup "$2" ;;
    restore|--restore|rst)    cmd_restore "$2" ;;
    fix-env|fix-env)         cmd_fix_env ;;
    fix-android|fix)          cmd_fix_android ;;
    uninstall|--uninstall|uninst) cmd_uninstall ;;
    v|version|--version|-v)   echo "oa CLI v$OA_VERSION" ;;
    help|--help|h|"")         show_help ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
