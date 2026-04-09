#!/usr/bin/env bash
# lib.sh — Shared function library for all orchestrators
# Usage: source "$SCRIPT_DIR/scripts/lib.sh"  (from repo)
#        source "$PROJECT_DIR/scripts/lib.sh"  (from installed copy)

# Standard Project Path
export PROJECT_DIR="${PROJECT_DIR:-$HOME/.openclaw-android}"

# ── Color constants ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIME='\033[38;5;154m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── UI Utilities ──
banner() {
    local title="$1"
    local color="${2:-$BOLD}"
    local version="${3:-$OA_VERSION}"
    echo -e "${color}${BOLD}=======================================================${NC}"
    echo -e "${color}${BOLD}  ${title} v${version}${NC}"
    echo -e "${color}${BOLD}=======================================================${NC}"
}

show_banner() {
    banner "$@"
}

# ── Project constants ──
PROJECT_DIR="$HOME/.openclaw-android"
PLATFORM_MARKER="$PROJECT_DIR/.platform"
REPO_BASE="https://raw.githubusercontent.com/ANONIMO432HZ/openclaw-android-multiarch/main"

BASHRC_MARKER_START="# >>> OpenClaw on Android >>>"
BASHRC_MARKER_END="# <<< OpenClaw on Android <<<"
export OA_VERSION="1.2.2.1" # Robust Linker & Glibc Resilience Edition
export ITALIC="\e[3m"
export DIM="\e[2m"

# ── Platform detection ──
# 1. Explicit marker file (new install and after first update)
# 2. Legacy detection (v1.0.2 and below, one-time)
# 3. Detection failure
detect_platform() {
    if [ -f "$PLATFORM_MARKER" ]; then
        cat "$PLATFORM_MARKER"
        return 0
    fi
    if command -v openclaw &>/dev/null; then
        echo "openclaw"
        mkdir -p "$(dirname "$PLATFORM_MARKER")"
        echo "openclaw" > "$PLATFORM_MARKER"
        return 0
    fi
    echo ""
    return 1
}

# ── System Resource Detection ──
is_armv7l() {
    local arch=$(uname -m)
    if [[ "$arch" == "armv7l" || "$arch" == "armhf" || "$arch" == "arm" ]]; then
        return 0
    fi
    return 1
}
# ── UI Utilities ──
step() {
    echo ""
    local total="${TOTAL_STEPS:-8}"
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        echo -e "${BOLD}[$1/$total] $2${NC}"
    else
        echo -e "${BOLD}=== $1 ===${NC}"
    fi
    echo "----------------------------------------"
}

# Global arch state
IS_ARMV7L=false
if is_armv7l; then IS_ARMV7L=true; fi

is_low_ram() {
    local total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    # Low RAM if < 2GB (approx 2,000,000 KB)
    if [ "$total_kb" -lt 2048000 ]; then
        return 0
    fi
    return 1
}

# ── Platform name validation ──
validate_platform_name() {
    local name="$1"
    if [ -z "$name" ]; then
        echo -e "${RED}[FAIL]${NC} Platform name is empty"
        return 1
    fi
    # Only lowercase alphanumeric + hyphens/underscores allowed
    if [[ ! "$name" =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then
        echo -e "${RED}[FAIL]${NC} Invalid platform name: $name"
        return 1
    fi
    return 0
}

# ── User confirmation prompt ──
# Reads from /dev/tty so it works even in curl|bash mode.
# Termux always has /dev/tty — no fallback for tty-less environments.
ask_yn() {
    local prompt="$1"
    
    # Auto-responses based on global OA_YES (set via -y/-n flags)
    if [[ "${OA_YES:-}" == "true" ]]; then
        return 0
    fi
    if [[ "${OA_YES:-}" == "false" ]]; then
        return 1
    fi

    local reply
    read -rp "$prompt [Y/n] " reply < /dev/tty
    [[ "${reply:-}" =~ ^[Nn]$ ]] && return 1
    return 0
}

# ── Load platform config.env ──
# $1: platform name, $2: base directory (parent of platforms/)
load_platform_config() {
    local platform="$1"
    local base_dir="$2"
    local config_path="$base_dir/platforms/$platform/config.env"

    validate_platform_name "$platform" || return 1

    if [ ! -f "$config_path" ]; then
        echo -e "${RED}[FAIL]${NC} Platform config not found: $config_path"
        return 1
    fi
    source "$config_path"
    return 0
}

# ── Glibc Linker Resolution ──
# Returns the absolute path to the glibc dynamic linker (ld.so)
# based on current architecture with absolute path fallbacks for robustness.
get_glibc_ldso() {
    local arch=$(uname -m)
    local ldso_name=""
    case "$arch" in
        aarch64) ldso_name="ld-linux-aarch64.so.1" ;;
        x86_64)  ldso_name="ld-linux-x86-64.so.2" ;;
        armv7l|armhf|arm) ldso_name="ld-linux-armhf.so.3" ;;
        *) ldso_name="ld-linux-aarch64.so.1" ;;
    esac

    # 1. Try $PREFIX-based path (dynamic)
    if [ -n "${PREFIX:-}" ]; then
        local path="$PREFIX/glibc/lib/$ldso_name"
        if [ -x "$path" ]; then
            echo "$path"
            return 0
        fi
    fi

    # 2. Fallback: Absolute Standard Termux Path
    local abs_path="/data/data/com.termux/files/usr/glibc/lib/$ldso_name"
    if [ -x "$abs_path" ]; then
        echo "$abs_path"
        return 0
    fi

    # 3. Fallback: Systematic search
    if [ -d "${PREFIX:-}/glibc" ]; then
        local found=$(find "${PREFIX}/glibc" -name "$ldso_name" -type f -executable 2>/dev/null | head -n 1)
        if [ -n "$found" ]; then
            echo "$found"
            return 0
        fi
    fi

    return 1
}

# ── Platform-Specific Helpers (OpenClaw) ──
# Centralized repair logic for bundled dependencies that often fail in Termux
repair_openclaw_plugins() {
    local force="${1:-false}"
    local openclaw_dir
    
    # Fix pathing: ensuring the isolated Node.js environment is active
    local node_path="$HOME/.openclaw-android/node"
    if [ -d "$node_path/bin" ] && [[ ":$PATH:" != *":$node_path/bin:"* ]]; then
        export PATH="$node_path/bin:$PATH"
    fi

    # Determine OpenClaw directory using forced prefix for robustness
    openclaw_dir="$(npm root -g --prefix="$node_path" 2>/dev/null)/openclaw"
    [ -d "$openclaw_dir" ] || return 0

    # 1. Fix native bindings broken by --ignore-scripts (npm/cli#4828 workaround)
    if [ -d "$openclaw_dir/node_modules/@snazzah/davey" ]; then
        echo "Installing native bindings for @snazzah/davey..."
        (cd "$openclaw_dir" && npm install @snazzah/davey --no-fund --no-audit --no-save --prefix="$node_path" 2>/dev/null) || true
    fi

    local claw_ver
    claw_ver=$(openclaw --version 2>/dev/null | head -1 | awk '{print $2}' | tr -d '[:space:]' || echo "unknown")
    local marker="$PROJECT_DIR/.plugins_repaired_${claw_ver:-unknown}"

    # 2. Fix missing bundled plugin dependencies (e.g. @buape/carbon)
    # If it's missing, or we are forcing, we MUST repair
    if [ ! -d "$openclaw_dir/node_modules/@buape/carbon" ] || [ "$force" = true ]; then
        echo -e "${YELLOW}[REPAIR]${NC} Critical plugin dependency (@buape/carbon) missing/requested."
        echo "         Applying heavy fix... (this ensures core stability)"
        
        local LOG_FILE="/tmp/oa_repair.log"
        [ -d "$PREFIX/tmp" ] && LOG_FILE="$PREFIX/tmp/oa_repair.log"
        truncate -s 0 "$LOG_FILE" 2>/dev/null || true

        # 2.1 Force install into OpenClaw's own node_modules
        local ERR=0
        (cd "$openclaw_dir" && npm install @buape/carbon --no-fund --no-audit --save-exact --no-package-lock --prefix="$node_path" >>"$LOG_FILE" 2>&1) || ERR=$?
        
        # 2.2 Run internal bundler if available (OpenClaw native script)
        if [ $ERR -eq 0 ] && [ -f "$openclaw_dir/scripts/postinstall-bundled-plugins.mjs" ]; then
            (cd "$openclaw_dir" && node scripts/postinstall-bundled-plugins.mjs >>"$LOG_FILE" 2>&1) || ERR=$?
        fi
        
        # Final Verification
        if [ -d "$openclaw_dir/node_modules/@buape/carbon" ]; then
            touch "$marker" 2>/dev/null || true
            rm -f "$LOG_FILE" 2>/dev/null || true
            echo -e "  ${GREEN}[OK]${NC}   Plugin environment successfully fixed."
            return 0
        else
            echo -e "  ${RED}[FAIL]${NC}  Could not force install @buape/carbon."
            if [ -f "$LOG_FILE" ]; then
                echo -e "         ${DIM}Check diagnostics below:${NC}"
                tail -n 10 "$LOG_FILE" | sed 's/^/         /'
                echo -e "         Full log: ${LOG_FILE}"
            fi
            return 1
        fi
    fi
    return 0
}
