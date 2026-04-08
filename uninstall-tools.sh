#!/usr/bin/env bash
# =============================================================================
# uninstall-tools.sh — Remove optional tools from Android/Termux environment
# =============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_DIR="$HOME/.openclaw-android"

if [ -f "$PROJECT_DIR/scripts/lib.sh" ]; then
    source "$PROJECT_DIR/scripts/lib.sh"
else
    # Fallback to simple ask_yn if lib.sh not available
    ask_yn() { echo -ne "$1 [Y/n] " && read -r reply && [[ ! "$reply" =~ ^[Nn]$ ]]; }
fi

banner "OpenClaw on Android — Uninstall Tools" "$RED"
echo ""

# ───── Helper: Safe Remove ─────
remove_tool() {
    local name="$1"    # Human readable name
    local cmd="$2"     # Binary to check if installed
    local pkg_name="$3" # Package manager name
    local type="${4:-pkg}" # npm or pkg or custom

    if ! command -v "$cmd" &>/dev/null; then
        echo -e "  ${YELLOW}[SKIP]${NC} $name is not found."
        return 
    fi

    if ask_yn "Uninstall $name?"; then
        echo "Removing $name..."
        case "$type" in
            pkg)
                pkg uninstall -y "$pkg_name" || true
                ;;
            npm)
                npm uninstall -g "$pkg_name" || true
                ;;
            custom)
                # For custom ones like code-server/opencode
                if [[ "$name" == "code-server" ]] && [ -x "$PROJECT_DIR/scripts/install-code-server.sh" ]; then
                    bash "$PROJECT_DIR/scripts/install-code-server.sh" uninstall || true
                elif [[ "$name" == "OpenCode" ]] && [ -f "$PREFIX/bin/opencode" ]; then
                    rm -f "$PREFIX/bin/opencode" || true
                    rm -rf "$HOME/.openclaw-android/proot-root" "$HOME/.bun" || true
                elif [ -f "$PREFIX/bin/$cmd" ]; then
                    rm -f "$PREFIX/bin/$cmd" || true
                fi
                ;;
        esac
        echo -e "  ${GREEN}[OK]${NC} $name removed."
    fi
}

# ───── Tool list ─────

remove_tool "tmux" "tmux" "tmux" "pkg"
remove_tool "ttyd" "ttyd" "ttyd" "pkg"
remove_tool "dufs" "dufs" "dufs" "pkg"
remove_tool "android-tools (adb)" "adb" "android-tools" "pkg"
remove_tool "Chromium" "chromium" "chromium" "pkg"

remove_tool "code-server" "code-server" "code-server" "custom"
remove_tool "OpenCode" "opencode" "opencode" "custom"

remove_tool "Claude Code CLI" "claude" "@anthropic-ai/claude-code" "npm"
remove_tool "Gemini CLI" "gemini" "@google/gemini-cli" "npm"
remove_tool "Codex CLI" "codex" "@openai/codex" "npm"

echo ""
echo -e "${GREEN}${BOLD}Uninstall cycle finished.${NC}"
echo ""
