#!/usr/bin/env bash
# oa.sh — OpenClaw Management Orchestrator for Android
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

PROJECT_DIR="$HOME/.openclaw-android"
if [ -f "$PROJECT_DIR/scripts/lib.sh" ]; then
    source "$PROJECT_DIR/scripts/lib.sh"
fi

# Fallback values if lib.sh is NOT found
OA_VERSION="${OA_VERSION:-1.2.0.0}"
RED="${RED:-\033[0;31m}"
GREEN="${GREEN:-\033[0;32m}"
YELLOW="${YELLOW:-\033[1;33m}"
BLUE="${BLUE:-\033[0;34m}"
PURPLE="${PURPLE:-\033[0;35m}"
CYAN="${CYAN:-\033[0;36m}"
LIME="${LIME:-\033[38;5;154m}"
BOLD="${BOLD:-\033[1m}"
NC="${NC:-\033[0m}"

# ── Global Flag Parsing ──
export OA_YES=""
# Temporarily collect arguments to parse flags first
TEMP_ARGS=()
for arg in "$@"; do
    case "$arg" in
        -y|--yes) export OA_YES="true" ;;
        -n|--no)  export OA_YES="false" ;;
        *) TEMP_ARGS+=("$arg") ;;
    esac
done
# Reconstruct arguments without the flags to avoid breaking subcommands
set -- "${TEMP_ARGS[@]}"

# ── Commands ──

show_help() {
    banner "OpenClaw Android Professional CLI" "$LIME"
    echo "Usage: oa [command]"
    echo ""
    echo "Commands:"
    echo "  update       Update everything (OpenClaw + tools + scripts)"
    echo "  self-update  Update ONLY the CLI scripts and patches (fast)"
    echo "  install      Install optional components (code-server, tmux, etc.)"
    echo ""
    echo "  start        Start OpenClaw Gateway (Background - nohup)"
    echo "  start:sv     Start OpenClaw gateway (Service - termux-services)"
    echo "  start:fg     Start OpenClaw gateway (Foreground - debug)"
    echo "  stop         Stop BOTH background and services"
    echo "  stop:sv      Stop ONLY the service"
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
    # Ensure SVDIR is set for termux-services (runit) otherwise commands like sv will fail
    export SVDIR="${PREFIX}/var/service"
    
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
    maybe_backup_before_update
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
            if [ -w "$PREFIX/bin" ]; then
                ln -sf "$PROJECT_DIR/oa.sh" "$PREFIX/bin/oa"
                chmod +x "$PROJECT_DIR/oa.sh"
            fi
            # Ensure all scripts are executable and have correct line endings
            find "$PROJECT_DIR" -maxdepth 2 -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
            find "$PROJECT_DIR" -maxdepth 2 -name "*.sh" -exec sed -i 's/\r$//' {} + 2>/dev/null || true
            local NEW_VERSION
            # Precise grep for the exported version line to avoid picking up function arguments
            NEW_VERSION=$(grep "^export OA_VERSION=" "$PROJECT_DIR/scripts/lib.sh" 2>/dev/null | cut -d'"' -f2 || echo "Updated")
            echo -e "${GREEN}[OK]${NC} Scripts updated to v$NEW_VERSION"
        else
            echo -e "${RED}[FAIL]${NC} Pull failed. Try: git reset --hard origin/main"
            git stash pop >/dev/null 2>&1 || true
            exit 1
        fi
    fi

    # ── Step 2: Update OpenClaw Core (npm) with confirmation ──
    if command -v openclaw &>/dev/null; then
        echo ""
        echo -e "${BOLD}OpenClaw Core Update${NC}"

        local PREV_VERSION
        PREV_VERSION=$(openclaw --version 2>/dev/null | head -1 || echo "unknown")
        echo "  Current version: $PREV_VERSION"
        echo ""
        echo "This will update OpenClaw via npm to the latest version."
        if [ -n "${OPENCLAW_STABLE_VERSION:-}" ] && [ "$OPENCLAW_STABLE_VERSION" != "latest" ]; then
            echo "  Stable fallback: $OPENCLAW_STABLE_VERSION"
        fi

        if ask_yn "Proceed with updating OpenClaw Core?"; then
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
            echo -e "${YELLOW}[SKIP]${NC} OpenClaw Core update skipped."
        fi
    else
        echo -e "${YELLOW}[SKIP]${NC} OpenClaw Core not installed."
    fi

    # ── Step 3: Re-apply Android patches ──
    echo -e "${CYAN}Re-applying Android compatibility patches...${NC}"
    if [ -f "$PROJECT_DIR/scripts/patch-android.sh" ]; then
        bash "$PROJECT_DIR/scripts/patch-android.sh" || true
    elif [ -f "$PROJECT_DIR/scripts/patch-core.sh" ]; then
        bash "$PROJECT_DIR/scripts/patch-core.sh" || true
    fi

    # ── Step 4: Auto-reload environment safely ──
    echo ""
    echo "Refreshing environment variables..."
    source "$HOME/.bashrc" 2>/dev/null || true
    echo -e "${GREEN}[OK]${NC} Update cycle completed."
    echo ""
    echo -e "${YELLOW}[IMPORTANT]${NC} To apply changes to your current terminal, run:"
    echo -e "  ${BOLD}source ~/.bashrc${NC}"
}

cmd_self_update() {
    check_and_fix_env
    maybe_backup_before_update
    banner "OpenClaw — CLI Self-Update" "$BLUE"
    echo "Updating repository scripts and patches..."
    
    cd "$PROJECT_DIR" || { echo -e "${RED}[FAIL]${NC} Folder missing."; exit 1; }
    
    # Prepare for safe sync (handle local changes)
    git stash push -m "oa-self-auto-stash" >/dev/null 2>&1 || true
    
    # Simple git pull for fast script sync
    if git pull origin main; then
        git stash pop >/dev/null 2>&1 || true
        echo -e "${GREEN}[OK]${NC} Repository synced."
        ln -sf "$PROJECT_DIR/oa.sh" "$PREFIX/bin/oa"
        # Ensure scripts are executable and have correct line endings
        find "$PROJECT_DIR" -maxdepth 2 -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
        find "$PROJECT_DIR" -maxdepth 2 -name "*.sh" -exec sed -i 's/\r$//' {} + 2>/dev/null || true
        bash "$PROJECT_DIR/scripts/setup-env.sh"
        echo ""
        echo -e "${GREEN}[SUCCESS]${NC} Scripts updated to latest version."
        echo "Run: source ~/.bashrc"
    else
        git stash pop >/dev/null 2>&1 || true
        echo -e "${RED}[FAIL]${NC} Git sync failed. Check connection."
    fi
}

cmd_install() {
    check_and_fix_env
    if [ -f "$PROJECT_DIR/install-tools.sh" ]; then
        chmod +x "$PROJECT_DIR/install-tools.sh"
        bash "$PROJECT_DIR/install-tools.sh"
    elif [ -f "$PROJECT_DIR/scripts/install-tools.sh" ]; then
        chmod +x "$PROJECT_DIR/scripts/install-tools.sh"
        bash "$PROJECT_DIR/scripts/install-tools.sh"
    else
        echo -e "${RED}[FAIL]${NC} install-tools.sh not found."
        exit 1
    fi
}

# ── Helper: Apply Ultra-Light optimizations if needed ──
apply_ultra_light_mode() {
    if is_armv7l && is_low_ram; then
        echo -e "${YELLOW}[LOW RAM DETECTED]${NC} Your device has limited memory (<2GB)."
        if ask_yn "Enable 'Ultra-Light' mode for better stability (limits memory per process)?"; then
            echo -e "${GREEN}[INFO]${NC} Memory limits applied (--max-old-space-size=256)."
            export NODE_OPTIONS="${NODE_OPTIONS:-} --max-old-space-size=256 --gc-interval=100"
        fi
        echo ""
    fi
}

# ── Helper: Optional backup before sensitive operations ──
maybe_backup_before_update() {
    if [ ! -d "$HOME/.openclaw" ] && [ ! -d "$HOME/.openclaw-android" ]; then
        return 0
    fi
    
    echo -e "${CYAN}${BOLD}Pre-Update Safety Check${NC}"
    if ask_yn "Would you like to create a backup of your data before updating?"; then
        cmd_backup "$PROJECT_DIR/backup"
    else
        echo -e "  ${YELLOW}[SKIP]${NC} Skipping preventive backup."
    fi
    echo ""
}

cmd_start_sv() {
    check_and_fix_env
    apply_ultra_light_mode
    
    # Ensure service is registered before starting
    if [ ! -d "$HOME/.termux/services/openclaw-gateway" ]; then
        echo -e "${YELLOW}[INFO]${NC} Service registration missing. Setting up now..."
        
        local SETUP_SCRIPT=""
        if [ -f "$PROJECT_DIR/scripts/setup-services.sh" ]; then
            SETUP_SCRIPT="$PROJECT_DIR/scripts/setup-services.sh"
        elif [ -f "$SCRIPT_DIR/scripts/setup-services.sh" ]; then
            SETUP_SCRIPT="$SCRIPT_DIR/scripts/setup-services.sh"
        fi

        if [ -n "$SETUP_SCRIPT" ]; then
            bash "$SETUP_SCRIPT" || { echo -e "${RED}[FAIL]${NC} Error running setup-services.sh"; return 1; }
        else
            echo -e "${RED}[FAIL]${NC} setup-services.sh not found."
            return 1
        fi
    fi

    # Universal cleanup before service start
    cmd_stop >/dev/null 2>&1 || true

    if command -v sv &>/dev/null && [ -d "$HOME/.termux/services/openclaw-gateway" ]; then
        # Ensure service is enabled (linked to /var/service) to avoid 'file does not exist' errors
        if command -v sv-enable &>/dev/null; then
            sv-enable openclaw-gateway >/dev/null 2>&1 || true
        fi

        echo -e "${CYAN}Starting OpenClaw gateway via termux-services...${NC}"
        # Inject a marker to avoid false positives from old logs
        mkdir -p "$PROJECT_DIR/logs"
        echo "--- OA RESTART ---" >> "$PROJECT_DIR/logs/current" 2>/dev/null || true

        # Trigger an 'up' command
        sv up openclaw-gateway 2>/dev/null || true
        
        # 1. Blocking wait for the service supervisor to transition to 'run'
        echo -ne "  Waiting for service supervisor"
        local sv_ok=false
        for i in {1..15}; do
            if sv status openclaw-gateway 2>/dev/null | grep -q "^run: openclaw-gateway:"; then
                sv_ok=true
                echo -e "\n  ${GREEN}[OK]${NC} Supervisor active."
                break
            fi
            echo -n "."
            sleep 1
        done
        
        if [ "$sv_ok" = false ]; then
            echo -e "\n${RED}[FAIL]${NC} Service supervisor failed to start within timeout."
            echo "  Try: sv status openclaw-gateway"
            return 1
        fi

        # 2. Blocking wait for the Node.js payload to fully boot (can take 30-60s on old phones)
        echo -ne "  Waiting for gateway to wake up (max 90s)..."
        local count=0
        local max_wait=90
        local log_file="$PROJECT_DIR/logs/current"
        
        while true; do
            # Read only the logs AFTER our restart marker
            if awk '/--- OA RESTART ---/{flag=1} flag' "$log_file" 2>/dev/null | grep -q "listening on" 2>/dev/null; then
                # Brief wait for kernel to register the socket (ARM race condition)
                sleep 2
                # Verify port is actually open before declaring success
                local port_open=false
                if command -v ss &>/dev/null && ss -ltn 2>/dev/null | grep -q ":18789\b"; then
                    port_open=true
                elif command -v netstat &>/dev/null && netstat -ltn 2>/dev/null | grep -q ":18789\b"; then
                    port_open=true
                else
                    port_open=true  # No tool to verify, trust the log
                fi
                if [ "$port_open" = true ]; then
                    echo -e "\n${GREEN}[OK]${NC} OpenClaw Gateway process started."
                    echo -e "     ${YELLOW}→${NC} The gateway may take ${BOLD}35-60 additional seconds${NC} to be reachable."
                    echo -e "     Verify with: ${CYAN}oa status${NC}"
                    return 0
                fi
                # Port not open yet, keep waiting
            fi

            sync
            sleep 1
            count=$((count + 1))
            echo -n "."

            # Print a progress hint every 10 seconds to keep the user informed
            if [ $((count % 10)) -eq 0 ]; then
                local last_line
                last_line=$(tail -n 1 "$log_file" 2>/dev/null | cut -c1-50)
                echo -ne "\n  [LOG] ${last_line}..."
            fi

            if [ $count -ge $max_wait ]; then
                echo -e "\n${YELLOW}[WARN]${NC} Timeout de ${max_wait}s excedido."
                echo -e "       El servicio sigue corriendo en background pero está muy lento."
                echo -e "       Revisa si arrancó ejecutando: ${BOLD}oa logs:sv${NC}"
                return 0
            fi
        done
    else
        echo -e "${RED}[FAIL]${NC} termux-services not fully initialized. Use 'oa start'."
        return 1
    fi
}

cmd_start() {
    check_and_fix_env
    apply_ultra_light_mode
    echo -e "${CYAN}Starting OpenClaw gateway in background (nohup)...${NC}"
    # Stop anything running first to prevent port conflict
    cmd_stop >/dev/null 2>&1 || true

    mkdir -p "$PROJECT_DIR/logs"
    # Clear log before starting to avoid false positives from previous runs
    > "$PROJECT_DIR/server.log"
    
    # Ensure Android 7+ compatibility with clear paths
    nohup openclaw gateway > "$PROJECT_DIR/server.log" 2>&1 &
    echo $! > "$PROJECT_DIR/oa.pid"

    echo -ne "  Waiting for server..."
    local count=0
    local max_wait=45
    while ! grep -q "listening on" "$PROJECT_DIR/server.log" 2>/dev/null; do
        sync
        sleep 1
        count=$((count + 1))
        
        # Show some progress from the log every 5 seconds
        if [ $((count % 5)) -eq 0 ]; then
            local LAST_LOG
            LAST_LOG=$(tail -n 1 "$PROJECT_DIR/server.log" 2>/dev/null | cut -c1-50)
            echo -ne "\n  [LOG] ${LAST_LOG}..."
        else
            echo -n "."
        fi

        if [ $count -ge $max_wait ]; then
            echo -e "\n${RED}[FAIL]${NC} Startup verification timed out after ${max_wait}s."
            echo -e "       The process might still be starting. Check 'oa logs'."
            return 1
        fi
    done
    echo ""
    local RUNNING_PIDS
    RUNNING_PIDS=$(list_oa_pids)
    if [ -n "$RUNNING_PIDS" ]; then
        echo -e "${GREEN}[OK]${NC} OpenClaw is listening and ready."
        return 0
    else
        echo -e "\n${RED}[FAIL]${NC} Log says listening but process check failed (no PIDs found)."
        return 1
    fi
}

cmd_start_fg() {
    check_and_fix_env
    apply_ultra_light_mode
    echo -e "${YELLOW}Starting OpenClaw gateway in foreground...${NC}"
    # Use 'exec' to replace the shell process for maximum stability on Android 7+
    exec openclaw gateway
}

# ── Helper: List active OpenClaw PIDs safely (excludes supervisors runsv/svlogd) ──
list_oa_pids() {
    ps -ef 2>/dev/null \
        | grep -E "openclaw gateway|node.*openclaw|openclaw-gateway|/bin/openclaw" \
        | grep -Ev "runsv|svlogd|grep|oa\.sh|$0" \
        | awk '{print $2}' || echo ""
}

cleanup_stray_processes() {

    local PIDS
    PIDS=$(list_oa_pids)

    if [ -n "$PIDS" ]; then
        echo -e "${YELLOW}Cleaning up stray gateway processes (Manual/Zombies)...${NC}"
        echo -e "  Stopping processes: $PIDS"
        kill $PIDS 2>/dev/null || true
        
        # Blocking wait for cleanup
        echo -n "  Waiting for total shutdown"
        local stop_count=0
        while [ -n "$(list_oa_pids)" ]; do
            sleep 1
            echo -n "."
            stop_count=$((stop_count + 1))
            if [ $stop_count -ge 8 ]; then
                echo -e "\n  Stubborn processes detected. Sending SIGKILL..."
                kill -9 $PIDS 2>/dev/null || true
                break
            fi
        done
        echo -e "\n  ${GREEN}[OK]${NC} Cleanup complete."
        return 0
    fi
    return 0
}

cmd_stop_sv() {
    check_and_fix_env
    
    # Ensure service exists before trying to stop it
    if [ ! -d "$HOME/.termux/services/openclaw-gateway" ]; then
        echo -e "${YELLOW}[INFO]${NC} No service found to stop."
        cleanup_stray_processes
        return 0
    fi

    if command -v sv &>/dev/null && [ -d "$HOME/.termux/services/openclaw-gateway" ]; then
        echo -e "${YELLOW}Stopping OpenClaw gateway service...${NC}"
        sv force-stop openclaw-gateway >/dev/null 2>&1 || true
        
        # Give runsv a moment to clear the PID
        for i in {1..5}; do
            if ! sv status openclaw-gateway 2>/dev/null | grep -q "run: openclaw-gateway:"; then
                break
            fi
            sleep 1
        done
        echo -e "  ${GREEN}[OK]${NC} Service stopped."
    fi

    # ALWAYS check for strays even when service mode was requested
    cleanup_stray_processes
}

cmd_stop() {
    check_and_fix_env
    
    # 1. Stop service if managed (Managed mode)
    if command -v sv &>/dev/null && [ -d "$HOME/.termux/services/openclaw-gateway" ]; then
        if sv status openclaw-gateway 2>/dev/null | grep -q "^run: openclaw-gateway:"; then
            echo -e "${YELLOW}[INFO]${NC} Gateway is managed by termux-services."
            cmd_stop_sv
            # Don't return, stop_sv already calls cleanup_stray_processes, but we follow through.
            return 0
        fi
    fi

    # 2. Cleanup ANY stray/manual processes (Zombie prevention)
    cleanup_stray_processes
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
    echo -e "${BOLD}Port / Network Status${NC}"
    # Check 18789 (Gateway) and 8022 (SSH)
    if command -v ss &>/dev/null; then
        if ss -ltn 2>/dev/null | grep -q ":18789\b"; then
            echo -e "  Gateway (18789): ${GREEN}PORT OPEN${NC}"
        else
            echo -e "  Gateway (18789): ${RED}CLOSED${NC}"
        fi
    elif command -v netstat &>/dev/null; then
         if netstat -ltn 2>/dev/null | grep -q ":18789\b"; then
            echo -e "  Gateway (18789): ${GREEN}PORT OPEN${NC}"
        else
            echo -e "  Gateway (18789): ${RED}CLOSED${NC}"
        fi
    else
        echo -e "  Port Check: ${YELLOW}[SKIP]${NC} (ss/netstat not found)"
    fi

    echo ""
    echo -e "${BOLD}Service Status${NC}"
    local RUNNING_PIDS
    RUNNING_PIDS=$(list_oa_pids)
    local RUNNING_VIA_PGREP=false
    if [ -n "$RUNNING_PIDS" ]; then
        RUNNING_VIA_PGREP=true
    fi

    if command -v sv &>/dev/null && [ -d "$HOME/.termux/services/openclaw-gateway" ]; then
        if sv status openclaw-gateway 2>/dev/null | grep -q "^run: openclaw-gateway:"; then
            echo -e "  Manager:  ${GREEN}termux-services${NC}"
            echo -e "  Status:   ${GREEN}Running${NC}"
        else
            echo -e "  Manager:  ${YELLOW}termux-services${NC}"
            if [ "$RUNNING_VIA_PGREP" = true ]; then
                echo -e "  Status:   ${GREEN}Running${NC} (Manual/Stray processes)"
            else
                echo -e "  Status:   ${RED}Stopped${NC}"
            fi
        fi
    else
        echo -e "  Manager:  ${CYAN}Manual / Background${NC}"
        if [ "$RUNNING_VIA_PGREP" = true ]; then
            echo -e "  Status:   ${GREEN}Running${NC}"
        else
            echo -e "  Status:   ${RED}Stopped${NC}"
        fi
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
        echo "  OA_GLIBC=${OA_GLIBC:-NOT_SET}"
        echo "  CONTAINER=${CONTAINER:-NOT_SET}"
        echo "  TMPDIR=${TMPDIR:-NOT_SET}"
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
    local LOGFILE=""

    # Check the professional svlogd location (configured in setup-services.sh)
    if [ -f "$PROJECT_DIR/logs/current" ]; then
        LOGFILE="$PROJECT_DIR/logs/current"
    elif [ -f "$HOME/.openclaw-android/logs/current" ]; then
        LOGFILE="$HOME/.openclaw-android/logs/current"
    elif [ -d "$HOME/.termux/services/openclaw-gateway/log" ]; then
        LOGFILE="$HOME/.termux/services/openclaw-gateway/log/current"
    # Internal OpenClaw system log directory (deep diagnostic)
    elif [ -d "$PREFIX/tmp/openclaw" ]; then
        LOGFILE=$(ls -t "$PREFIX/tmp/openclaw"/*.log 2>/dev/null | head -n 1)
    elif [ -d "/data/data/com.termux/files/usr/tmp/openclaw" ]; then
        LOGFILE=$(ls -t "/data/data/com.termux/files/usr/tmp/openclaw"/*.log 2>/dev/null | head -n 1)
    fi

    # Fallback to nohup manual log
    if [ -z "$LOGFILE" ] || [ ! -s "$LOGFILE" ]; then
        LOGFILE="$PROJECT_DIR/server.log"
    fi

    if [ -f "$LOGFILE" ]; then
         echo -e "${CYAN}${BOLD}Monitoring Logs:${NC} $LOGFILE"
         echo -e "${YELLOW}(Press Ctrl+C to exit)${NC}"
         echo "─────────────────────────────────────"
         tail -f "$LOGFILE"
    else
         echo -e "${RED}[FAIL]${NC} No logs found in any expected location."
         echo -e "  Manual:  $PROJECT_DIR/server.log"
         echo -e "  Service: $PROJECT_DIR/logs/current"
         exit 1
    fi
}

cmd_uninstall() {
    if [ -f "$PROJECT_DIR/uninstall.sh" ]; then
        bash "$PROJECT_DIR/uninstall.sh"
    elif [ -f "$SCRIPT_DIR/uninstall.sh" ]; then
        bash "$SCRIPT_DIR/uninstall.sh"
    else
        echo -e "${RED}[FAIL]${NC} Uninstall script not found at $PROJECT_DIR/uninstall.sh"
        exit 1
    fi
}

cmd_ui() {
    check_and_fix_env
    if ! command -v openclaw &>/dev/null; then
        echo -e "${RED}[FAIL]${NC} openclaw not found. Run the installer first."
        exit 1
    fi

    # 0. User fallback (Handle unbound variable in strict mode)
    local CURRENT_USER="${USER:-$(whoami 2>/dev/null || echo "termux")}"

    # 1. IP Fallback detection
    local IP
    IP=$(ip -o -4 addr list 2>/dev/null | grep -v '127.0.0.1' | awk '{print $4}' | cut -d/ -f1 | head -n 1 || echo "DEVICE_IP")

    echo -e "${CYAN}Launching OpenClaw Core...${NC}"
    echo "────────────────────────────────────"

    # 2. Execute core, show live logs, and capture output
    local DASH_LOG
    DASH_LOG=$(openclaw dashboard 2>&1 | tee /dev/tty || true)

    # 3. Dynamic Extraction (IP + Token Sync)
    local CORE_IP TOKEN
    # Extraemos la IP del usuario@ip (El robo de IP del dash)
    CORE_IP=$(echo "$DASH_LOG" | grep -o '[a-z0-9_]*@[0-9.]*' | cut -d'@' -f2 | head -n 1 || echo "")
    [[ -n "$CORE_IP" ]] && IP="$CORE_IP"
    
    # Extraemos el Token de seguridad dinámico (#token=...)
    TOKEN=$(echo "$DASH_LOG" | grep -o '#token=[a-z0-9]*' | cut -d'=' -f2 | head -n 1 || echo "")

    # 4. Professional Minimalist UI (Mobile-Safe 40 width)
    echo ""
    echo -e "${RED}────────────────────────────────────────${NC}"
    echo -e " ${YELLOW}⚠️  TERMUX SSH TIP (GUI & LAN ACCESS)${NC}"
    echo -e " ${DIM}The original command is incomplete. Use this:${NC}"
    echo ""
    echo -e " ${BOLD}Silent Tunnel:${NC}"
    echo -e " ${LIME}${BOLD}ssh -N -L 18789:127.0.0.1:18789 -L 18791:127.0.0.1:18791 -p 8022 ${CURRENT_USER}@${IP}${NC}"
    echo ""
    echo -e " ${BOLD}Tunnel + Shell:${NC}"
    echo -e " ${LIME}${BOLD}ssh -L 18789:127.0.0.1:18789 -L 18791:127.0.0.1:18791 -p 8022 ${CURRENT_USER}@${IP}${NC}"
    echo ""
    echo -e " ${BOLD}PC Browser Link:${NC}"
    echo -e " http://localhost:18789/#token=${TOKEN:-NOT_FOUND}"
    echo -e "${RED}────────────────────────────────────────${NC}\n"
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
    if [ -f "$PROJECT_DIR/scripts/doctor.sh" ]; then
        bash "$PROJECT_DIR/scripts/doctor.sh"
    elif [ -f "$SCRIPT_DIR/scripts/doctor.sh" ]; then
        bash "$SCRIPT_DIR/scripts/doctor.sh"
    else
        # Fallback if scripts are missing
        echo -e "${CYAN}Running health checks (legacy mode)...${NC}"
        if command -v openclaw &>/dev/null; then
            openclaw doctor
        else
            echo -e "${RED}[FAIL]${NC} Diagnostic tools not found."
            exit 1
        fi
    fi
}

# ── Main Entry Point ──
case "${1:-}" in
    update|--update|-update|up|upgrade) cmd_update "$@" ;;
    self-update|selfupdate)           cmd_self_update ;;
    install|--install|inst)           cmd_install "$@" ;;
    start|--start|srt|up)             cmd_start ;;
    start:sv|--start:sv|srt:sv|srv:up) cmd_start_sv ;;
    start:fg|--start:fg|fg)           cmd_start_fg ;;
    stop|--stop|stp|down)             cmd_stop ;;
    stop:sv|--stop:sv|stp:sv|srv:down) cmd_stop_sv ;;
    logs|--logs|log|lg)               cmd_logs ;;
    ui|--ui|dashboard)                cmd_ui ;;
    ui-config|--ui-config|config-wizard) cmd_ui_config ;;
    onboard|--onboard|obd)            cmd_onboard ;;
    config|--config|cfg)              cmd_config "$@" ;;
    doctor|--doctor|doc)              cmd_doctor ;;
    status|--status|st|stat)          cmd_status ;;
    backup|--backup|bkp)              cmd_backup "$2" ;;
    restore|--restore|rst)            cmd_restore "$2" ;;
    fix-env)                          cmd_fix_env ;;
    fix-android|fix)                  cmd_fix_android ;;
    uninstall|--uninstall|uninst)     cmd_uninstall ;;
    v|version|--version|-v)           echo "oa CLI $OA_VERSION" ;;
    help|--help|-h|h|"")              show_help ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
