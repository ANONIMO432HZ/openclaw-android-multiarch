#!/usr/bin/env bash
set -euo pipefail

# This script installs OpenClaw on Termux with platform-aware architecture.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
echo "DEBUG: SCRIPT_DIR is $SCRIPT_DIR"

# Global configuration
TOTAL_STEPS=8
if [ ! -f "$SCRIPT_DIR/scripts/lib.sh" ]; then
    echo "ERROR: Could not find lib.sh at $SCRIPT_DIR/scripts/lib.sh"
    echo "Current directory: $(pwd)"
    ls -R "$SCRIPT_DIR" || echo "Cannot list $SCRIPT_DIR"
    exit 1
fi
source "$SCRIPT_DIR/scripts/lib.sh"

banner "OpenClaw on Android - Installer" "$OA_VERSION"

step 1 "Environment Check"
if command -v termux-wake-lock &>/dev/null; then
    termux-wake-lock 2>/dev/null || true
    echo -e "${GREEN}[OK]${NC}   Termux wake lock enabled"
fi
bash "$SCRIPT_DIR/scripts/check-env.sh"

step 2 "Platform Selection"
SELECTED_PLATFORM="openclaw"
echo -e "${GREEN}[OK]${NC}   Platform: OpenClaw"
load_platform_config "$SELECTED_PLATFORM" "$SCRIPT_DIR"

step 3 "Optional Tools Selection (L3)"
INSTALL_TMUX=false
INSTALL_TTYD=false
INSTALL_DUFS=false
INSTALL_ANDROID_TOOLS=false
INSTALL_CODE_SERVER=false
INSTALL_OPENCODE=false
INSTALL_CLAUDE_CODE=false
INSTALL_CHROMIUM=false
INSTALL_GEMINI_CLI=false
INSTALL_CODEX_CLI=false

check_tool_installed() {
    local cmd="$1"
    local name="$2"
    if command -v "$cmd" &>/dev/null; then
        echo -e "       ${GREEN}[INSTALLED]${NC} $name"
        return 0
    fi
    return 1
}

if ! check_tool_installed "tmux" "tmux (terminal multiplexer)"; then
    if ask_yn "Install tmux (terminal multiplexer)?"; then INSTALL_TMUX=true; fi
fi

if ! check_tool_installed "ttyd" "ttyd (web terminal)"; then
    if ask_yn "Install ttyd (web terminal)?"; then INSTALL_TTYD=true; fi
fi

if ! check_tool_installed "dufs" "dufs (file server)"; then
    if ask_yn "Install dufs (file server)?"; then INSTALL_DUFS=true; fi
fi

if ! check_tool_installed "adb" "android-tools (adb)"; then
    if ask_yn "Install android-tools (adb)?"; then INSTALL_ANDROID_TOOLS=true; fi
fi

# Selection logic based on architecture and resources
if is_armv7l; then
    # ARMv7: Hide completely unsupported tools
    echo -e "\n${YELLOW}[ARMv7 DETECTED]${NC} Hiding memory-intensive tools unsupported on 32-bit legacy devices."
else
    # ARMv8/aarch64: Show everything, but warn if RAM is low
    if ! check_tool_installed "chromium" "Chromium (browser automation)"; then
        if ask_yn "Install Chromium (browser automation for OpenClaw, ~400MB)?"; then INSTALL_CHROMIUM=true; fi
    fi
    if ! check_tool_installed "code-server" "code-server (browser IDE)"; then
        if ask_yn "Install code-server (browser IDE)?"; then INSTALL_CODE_SERVER=true; fi
    fi
    if ! check_tool_installed "opencode" "OpenCode (AI assistant)"; then
        if ask_yn "Install OpenCode (AI coding assistant)?"; then INSTALL_OPENCODE=true; fi
    fi
    if ! check_tool_installed "claude" "Claude Code CLI"; then
        if ask_yn "Install Claude Code CLI?"; then INSTALL_CLAUDE_CODE=true; fi
    fi
    if ! check_tool_installed "gemini" "Gemini CLI"; then
        if ask_yn "Install Gemini CLI?"; then INSTALL_GEMINI_CLI=true; fi
    fi
    if ! check_tool_installed "codex" "Codex CLI"; then
        if ask_yn "Install Codex CLI?"; then INSTALL_CODEX_CLI=true; fi
    fi
fi

step 4 "Core Infrastructure (L1)"
bash "$SCRIPT_DIR/scripts/install-infra.sh"
bash "$SCRIPT_DIR/scripts/setup-paths.sh"

step 5 "Platform Runtime Dependencies (L2)"
# Pass the architecture info to children
bash "$SCRIPT_DIR/scripts/install-glibc.sh"
bash "$SCRIPT_DIR/scripts/install-nodejs.sh"
bash "$SCRIPT_DIR/scripts/install-build-tools.sh"

# Memory optimization for installation phase
if is_low_ram && [ "$IS_ARMV7L" = true ]; then
    echo -e "${YELLOW}[LOW RAM MODE]${NC} Limiting Node.js memory for installation stability."
    export NODE_OPTIONS="--max-old-space-size=512"
fi

step 6 "Platform Package Installation"
# Run the platform-specific installer
bash "$SCRIPT_DIR/platforms/$SELECTED_PLATFORM/install.sh"

step 7 "Install Optional Tools (L3)"
if [ "$INSTALL_TMUX" = true ]; then pkg install -y tmux; fi
if [ "$INSTALL_TTYD" = true ]; then pkg install -y ttyd; fi
if [ "$INSTALL_DUFS" = true ]; then pkg install -y dufs; fi
if [ "$INSTALL_ANDROID_TOOLS" = true ]; then pkg install -y android-tools; fi
if [ "$INSTALL_CHROMIUM" = true ]; then pkg install -y chromium; fi
if [ "$INSTALL_CODE_SERVER" = true ]; then pkg install -y code-server; fi

# AI Tools (npm based)
if [ "$INSTALL_OPENCODE" = true ]; then npm install -g @opencode/cli --no-audit --no-fund; fi
if [ "$INSTALL_CLAUDE_CODE" = true ]; then npm install -g @anthropic-ai/claude-code --no-audit --no-fund; fi
if [ "$INSTALL_GEMINI_CLI" = true ]; then npm install -g @google/gemini-cli --no-audit --no-fund; fi
if [ "$INSTALL_CODEX_CLI" = true ]; then npm install -g @openai/codex-cli --no-audit --no-fund; fi

step 8 "System Configuration & Services"
bash "$SCRIPT_DIR/scripts/setup-cli.sh"
bash "$SCRIPT_DIR/scripts/setup-shell.sh"

# Cleanup
echo ""
echo "Cleaning up temporary files..."
rm -rf "$HOME/.openclaw-android/tmp"/* || true

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "You can now use OpenClaw by running:"
echo -e "  ${BOLD}oa onboarding${NC}"
echo ""
echo "To manage services:"
echo -e "  ${BOLD}oa start${NC}  - Start all services"
echo -e "  ${BOLD}oa stop${NC}   - Stop all services"
echo -e "  ${BOLD}oa status${NC} - View service health"
echo ""

# Verify the installation
bash "$SCRIPT_DIR/tests/verify-install.sh"
