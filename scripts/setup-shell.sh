#!/usr/bin/env bash
set -euo pipefail

# This script configures the shell PATH and environment.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/scripts/lib.sh"

echo "OpenClaw on Android — Shell Configuration"
echo "────────────────────────────────────────"

# Ensure ~/bin is in PATH
BASHRC="$HOME/.bashrc"
echo "  Targeting: $BASHRC"

# Create /data/data/com.termux/files/home/bin if missing
mkdir -p "$HOME/bin"

# Check if PATH already contains ~/bin
if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$BASHRC" 2>/dev/null; then
    echo "" >> "$BASHRC"
    echo "# OpenClaw on Android - bin path" >> "$BASHRC"
    echo 'export PATH="$HOME/bin:$PATH"' >> "$BASHRC"
    echo -e "  ${GREEN}[OK]${NC}   Added ~/bin to PATH in .bashrc"
else
    echo -e "  ${BLUE}[SKIP]${NC} ~/bin already in PATH in .bashrc"
fi

# Set project-specific environment variables
if ! grep -q "OPENCLAW_ANDROID_DIR" "$BASHRC" 2>/dev/null; then
    echo "export OPENCLAW_ANDROID_DIR=\"$PROJECT_DIR\"" >> "$BASHRC"
    echo -e "  ${GREEN}[OK]${NC}   Added OPENCLAW_ANDROID_DIR to .bashrc"
fi

echo ""
echo -e "  ${GREEN}[OK]${NC} Shell environment configured."
echo ""
