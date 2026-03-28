#!/usr/bin/env bash
# bootstrap.sh - Download and run OpenClaw on Android installer
# Usage: curl -sL https://raw.githubusercontent.com/ANONIMO432HZ/openclaw-android-multiarch/main/bootstrap.sh | bash
set -euo pipefail

REPO_TARBALL="https://github.com/ANONIMO432HZ/openclaw-android-multiarch/archive/refs/heads/main.tar.gz"
INSTALL_DIR="$HOME/.openclaw-android/installer"

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
curl -sfL "$REPO_TARBALL" | tar xz -C "$INSTALL_DIR" --strip-components=1

bash "$INSTALL_DIR/install.sh"

cp "$INSTALL_DIR/uninstall.sh" "$HOME/.openclaw-android/uninstall.sh"
chmod +x "$HOME/.openclaw-android/uninstall.sh"
rm -rf "$INSTALL_DIR"
