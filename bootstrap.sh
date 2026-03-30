#!/usr/bin/env bash
# bootstrap.sh - Download and run OpenClaw on Android installer
# Usage: curl -sL https://raw.githubusercontent.com/ANONIMO432HZ/openclaw-android-multiarch/main/bootstrap.sh | bash
set -euo pipefail

REPO_TARBALL="https://github.com/ANONIMO432HZ/openclaw-android-multiarch/archive/refs/heads/main.tar.gz"
INSTALL_DIR="$HOME/.openclaw-android"

RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}OpenClaw on Android - Bootstrap${NC}"
echo ""

if ! command -v curl &>/dev/null; then
    echo -e "${RED}[FAIL]${NC} curl not found. Install it with: pkg install curl"
    exit 1
fi

echo "Downloading installer..."
mkdir -p "$INSTALL_DIR"
if ! curl -sfL "$REPO_TARBALL" | tar xz -C "$INSTALL_DIR" --strip-components=1; then
    echo -e "${RED}[FAIL]${NC} Download failed. Check your internet connection."
    exit 1
fi

if [ ! -f "$INSTALL_DIR/install.sh" ]; then
    echo -e "${RED}[FAIL]${NC} Installer files incomplete. Retrying may fix it."
    exit 1
fi

# Run the installer
bash "$INSTALL_DIR/install.sh"

chmod +x "$INSTALL_DIR/uninstall.sh"
