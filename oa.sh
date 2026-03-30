#!/usr/bin/env bash
# oa.sh — OpenClaw Management Orchestrator for Android
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

PROJECT_DIR="$HOME/.openclaw-android"
if [ -f "$PROJECT_DIR/scripts/lib.sh" ]; then
    source "$PROJECT_DIR/scripts/lib.sh"
fi

# Fallback values if lib.sh is NOT found
OA_VERSION="${OA_VERSION:-1.1.0}"
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

# Fallback ask_yn if lib.sh is not available
if ! command -v ask_yn &>/dev/null; then
    ask_yn() {
        local prompt="$1"
        local reply
        read -rp "$prompt [Y/n] " reply < /dev/tty
        [[ "${reply:-}" =~ ^[Nn]$ ]] && return 1
        return 0
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

# ── Helper: Verify and repair environment if needed (fast) ──
check_and_fix_env() {
    if [ -n "${OA_GLIBC:-}" ] && [ -n "${CONTAINER:-}" ]; then
        return 0
    fi
    if grep -q "OA_GLIBC=" "$HOME/.bashrc" 2>/dev/null; then
        source "$HOME/.bashrc" 2>/dev/null || true
    fi
    if [ -z "${OA_GLIBC:-}" ] || [ -z "${CONTAINER:-}" ]; then
        bash "$PROJECT_DIR/scripts/setup-env.sh" 2>/dev/null || true
        source "$HOME/.bashrc" 2>/dev/null || true
    fi
}

# ── Command Implementations ──

cmd_update() {
    check_and_fix_env
    banner "OpenClaw — Update Module" "$PURPLE"
    cd "$PROJECT_DIR" || { echo -e "${RED}[FAIL]${NC} Impossible to access $PROJECT_DIR"; exit 1; }

    # Load stable version pin from config
    if [ -f "$PROJECT_DIR/platforms/openclaw/config.env" ]; then
        source "$PROJECT_DIR/platforms/openclaw/config.env"
    fi

    # ── Step 1: Sync scripts via git (like omni.sh) ──
    local GIT_ERR_LOG="/tmp/oa_git_err.log"
    [ -d "$PREFIX/tmp" ] && GIT_ERR_LOG="$PREFIX/tmp/oa_git_err.log"

    git fetch --tags --force 2>"$GIT_ERR_LOG" || {
        echo -e "${RED}[FAIL]${NC} Network/Git error."
        cat "$GIT_ERR_LOG" 2>/dev/null || echo "Check your internet/DNS connection."
        exit 1
    }

    local LOCAL REMOTE
    LOCAL=$(git rev-parse HEAD 2>/dev/null || echo "0")
    REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "1")

    if [ "$LOCAL" = "$REMOTE" ]; then
        echo -e "${GREEN}[OK]${NC} Scripts already up-to-date (v$OA_VERSION)."
    else
        echo -e "${YELLOW}[UPDATE]${NC} New scripts found. Syncing repository..."
        git stash push -m "oa-auto-stash" >/dev/null 2>&1 || true

        if git pull origin main; then
            git stash pop >/dev/null 2>&1 || true
            find "$PROJECT_DIR" -maxdepth 2 -name "*.sh" -exec sed -i 's/\r$//' {} + 2>/dev/null || true
            if [ -w "$PREFIX/bin" ]; then
                ln -sf "$PROJECT_DIR/oa.sh" "$PREFIX/bin/oa"
                chmod +x "$PROJECT_DIR/oa.sh"
            fi
            local NEW_VERSION
            NEW_VERSION=$(grep OA_VERSION "$PROJECT_DIR/scripts/lib.sh" 2>/dev/null | cut -d'"' -f2 || echo "Updated")
            echo -e "${GREEN}[OK]${NC} Scripts updated to v$NEW_VERSION."
        else
            echo -e "${RED}[FAIL]${NC} Pull failed. Try: git reset --hard origin/main"
            git stash pop >/dev/null 2>&1 || true
            exit 1
        fi
    fi

    # ── Step 2: Update OpenClaw Core (npm) ──
    if command -v openclaw &>/dev/null; then
        echo ""
        echo -e "${BOLD}OpenClaw Core Update${NC}"

        local PREV_VERSION
        PREV_VERSION=$(openclaw --version 2>/dev/null | head -1 || echo "unknown")
        echo "  Current version: $PREV_VERSION"

        echo "Updating OpenClaw Core via NPM (latest first)..."
        local NPM_OUTPUT
        local NPM_EXIT=0
        NPM_OUTPUT=$(npm install -g openclaw@latest --no-audit --no-fund 2>&1) || NPM_EXIT=$?

        if [ $NPM_EXIT -eq 0 ]; then
            echo -e "${GREEN}[OK]${NC} OpenClaw Core updated (latest)."
        elif [ -n "${OPENCLAW_STABLE_VERSION:-}" ] && [ "$OPENCLAW_STABLE_VERSION" != "latest" ]; then
            echo -e "${YELLOW}[FALLBACK]${NC} latest failed — trying stable version $OPENCLAW_STABLE_VERSION..."
            NPM_OUTPUT=$(npm install -g "openclaw@${OPENCLAW_STABLE_VERSION}" --no-audit --no-fund 2>&1) || NPM_EXIT=$?
            if [ $NPM_EXIT -eq 0 ]; then
                echo -e "${GREEN}[OK]${NC} OpenClaw Core installed (stable: $OPENCLAW_STABLE_VERSION)."
            else
                echo -e "${RED}[FAIL]${NC} Stable version also failed."
                echo "$NPM_OUTPUT" | head -10
                if [ "$PREV_VERSION" != "unknown" ]; then
                    echo ""
                    if ask_yn "Rollback to previous version ($PREV_VERSION)?"; then
                        npm install -g "openclaw@$PREV_VERSION" --no-audit --no-fund 2>&1 || true
                        echo -e "${YELLOW}[INFO]${NC} Rollback attempted."
                    fi
                fi
            fi
        else
            echo -e "${RED}[FAIL]${NC} OpenClaw Core update failed."
            echo "$NPM_OUTPUT" | head -20
        fi
    else
        echo -e "${YELLOW}[SKIP]${NC} OpenClaw Core not installed."
    fi

    # ── Step 3: Re-apply Android patches ──
    echo ""
    echo "Re-applying Android compatibility patches..."
    if [ -f "$PROJECT_DIR/scripts/patch-android.sh" ]; then
        bash "$PROJECT_DIR/scripts/patch-android.sh"
    elif [ -f "$PROJECT_DIR/scripts/patch-core.sh" ]; then
        bash "$PROJECT_DIR/scripts/patch-core.sh"
    fi

    echo ""
    echo -e "${GREEN}[OK]${NC} Update cycle completed."
    echo "Run: source ~/.bashrc"
}

    local LOCAL REMOTE
    LOCAL=$(git rev-parse HEAD 2>/dev/null || echo "0")
    REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "1")

    if [ "$LOCAL" = "$REMOTE" ]; then
        echo -e "${GREEN}[OK]${NC} Scripts already up-to-date (v$OA_VERSION)."
    else
        echo -e "${YELLOW}[UPDATE]${NC} New scripts found. Syncing repository..."
        git stash push -m "oa-auto-stash" >/dev/null 2>&1 || true

        if git pull origin main; then
            git stash pop >/dev/null 2>&1 || true
            find "$PROJECT_DIR" -maxdepth 2 -name "*.sh" -exec sed -i 's/\r$//' {} + 2>/dev/null || true
            if [ -w "$PREFIX/bin" ]; then
                ln -sf "$PROJECT_DIR/oa.sh" "$PREFIX/bin/oa"
                chmod +x "$PROJECT_DIR/oa.sh"
            fi
            local NEW_VERSION
            NEW_VERSION=$(grep OA_VERSION "$PROJECT_DIR/scripts/lib.sh" 2>/dev/null | cut -d'"' -f2 || echo "Updated")
            echo -e "${GREEN}[OK]${NC} Scripts updated to v$NEW_VERSION."
        else
            echo -e "${RED}[FAIL]${NC} Pull failed. Try: git reset --hard origin/main"
            git stash pop >/dev/null 2>&1 || true
            exit 1
        fi
    fi

    # ── Step 2: Update OpenClaw Core (npm) ──
    if command -v openclaw &>/dev/null; then
        echo ""
        echo -e "${BOLD}OpenClaw Core Update${NC}"

        local PREV_VERSION
        PREV_VERSION=$(openclaw --version 2>/dev/null | head -1 || echo "unknown")
        echo "  Current version: $PREV_VERSION"

        echo "Updating OpenClaw Core via NPM (latest first)..."
        local NPM_OUTPUT
        local NPM_EXIT=0
        NPM_OUTPUT=$(npm install -g openclaw@latest --no-audit --no-fund 2>&1) || NPM_EXIT=$?

        if [ $NPM_EXIT -eq 0 ]; then
            echo -e "${GREEN}[OK]${NC} OpenClaw Core updated (latest)."
        elif [ -n "${OPENCLAW_STABLE_VERSION:-}" ] && [ "$OPENCLAW_STABLE_VERSION" != "latest" ]; then
            echo -e "${YELLOW}[FALLBACK]${NC} latest failed — trying stable version $OPENCLAW_STABLE_VERSION..."
            NPM_OUTPUT=$(npm install -g "openclaw@${OPENCLAW_STABLE_VERSION}" --no-audit --no-fund 2>&1) || NPM_EXIT=$?
            if [ $NPM_EXIT -eq 0 ]; then
                echo -e "${GREEN}[OK]${NC} OpenClaw Core installed (stable: $OPENCLAW_STABLE_VERSION)."
            else
                echo -e "${RED}[FAIL]${NC} Stable version also failed."
                echo "$NPM_OUTPUT" | head -10
                if [ "$PREV_VERSION" != "unknown" ]; then
                    echo ""
                    if ask_yn "Rollback to previous version ($PREV_VERSION)?"; then
                        npm install -g "openclaw@$PREV_VERSION" --no-audit --no-fund 2>&1 || true
                        echo -e "${YELLOW}[INFO]${NC} Rollback attempted."
                    fi
                fi
            fi
        else
            echo -e "${RED}[FAIL]${NC} OpenClaw Core update failed."
            echo "$NPM_OUTPUT" | head -20
        fi
    else
        echo -e "${YELLOW}[SKIP]${NC} OpenClaw Core not installed."
    fi

    # ── Step 3: Re-apply Android patches ──
    echo ""
    echo "Re-applying Android compatibility patches..."
    if [ -f "$PROJECT_DIR/scripts/patch-android.sh" ]; then
        bash "$PROJECT_DIR/scripts/patch-android.sh"
    elif [ -f "$PROJECT_DIR/scripts/patch-core.sh" ]; then
        bash "$PROJECT_DIR/scripts/patch-core.sh"
    fi

    echo ""
    echo -e "${GREEN}[OK]${NC} Update cycle completed."
    echo "Run: source ~/.bashrc"
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

cmd_start() {
    check_and_fix_env
    echo -e "${CYAN}Starting OpenClaw gateway in background...${NC}"
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

    echo -e "  Stopping and cleaning up processes..."
    cmd_stop >/dev/null 2>&1 || true

    if command -v sv &>/dev/null; then
        sv-disable openclaw-gateway 2>/dev/null || true
    fi

    echo -e "  Removing CLI and files..."
    rm -rf "$PROJECT_DIR"
    rm -f "$PREFIX/bin/oa"

    if [ -f "$HOME/.bashrc" ]; then
        sed -i "/# >>> OpenClaw on Android >>>/,/# <<< OpenClaw on Android <<</d" "$HOME/.bashrc"
    fi

    echo -e "${GREEN}[OK]${NC} OpenClaw has been removed."
}

cmd_ui() {
    check_and_fix_env
    if ! command -v openclaw &>/dev/null; then
        echo -e "${RED}[FAIL]${NC} openclaw not found. Run the installer first."
        exit 1
    fi
    echo -e "${CYAN}Opening OpenClaw Dashboard...${NC}"
    openclaw dashboard
}

cmd_ui_config() {
    check_and_fix_env
    if ! command -v openclaw &>/dev/null; then
        echo -e "${RED}[FAIL]${NC} openclaw not found. Run the installer first."
        exit 1
    fi
    echo -e "${CYAN}Opening Configuration Wizard...${NC}"
    openclaw configure
}

cmd_onboard() {
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
    update|--update|-update|up)       cmd_update "$@" ;;
    install|--install|inst)           cmd_install "$@" ;;
    start|--start|strt)               cmd_start ;;
    start:fg|--start:fg|strt:fg)      cmd_start_fg ;;
    stop|--stop|stp)                  cmd_stop ;;
    logs|--logs|log)                  cmd_logs ;;
    ui|--ui|dashboard)                cmd_ui ;;
    ui-config|--ui-config|config-wizard) cmd_ui_config ;;
    onboard|--onboard|obd)            cmd_onboard ;;
    config|--config|cfg)              cmd_config "$@" ;;
    doctor|--doctor|doc)              cmd_doctor ;;
    status|--status|st)               cmd_status ;;
    backup|--backup|bkp)              cmd_backup "$2" ;;
    restore|--restore|rst)            cmd_restore "$2" ;;
    fix-env)                          cmd_fix_env ;;
    fix-android|fix)                  cmd_fix_android ;;
    uninstall|--uninstall|uninst)     cmd_uninstall ;;
    v|version|--version|-v)           echo "oa CLI v$OA_VERSION" ;;
    help|--help|-h|h|"")              show_help ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
