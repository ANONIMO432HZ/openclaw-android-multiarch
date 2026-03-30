#!/usr/bin/env bash
# bootstrap.sh - Download and run OpenClaw on Android installer
# Usage: curl -sL https://raw.githubusercontent.com/ANONIMO432HZ/openclaw-android-multiarch/main/bootstrap.sh | bash
set -euo pipefail

REPO_URL="https://github.com/ANONIMO432HZ/openclaw-android-multiarch.git"
INSTALL_DIR="$HOME/.openclaw-android"

RED='\033[0;31m'
BOLD='\033[1m'
GREEN='\033[0;32m'
NC='\033[0m'

echo ""
echo -e "${BOLD}OpenClaw on Android - Bootstrap${NC}"
echo ""

# Check for git first
if ! command -v git &>/dev/null; then
    echo -e "${RED}[FAIL]${NC} git not found. Install it with: pkg install git"
    exit 1
fi

echo "Cloning repository (shallow clone, depth=1)..."
if [ -d "$INSTALL_DIR/.git" ]; then
    echo -e "${YELLOW}[INFO]${NC} Existing git repository found. Pulling latest changes..."
    git -C "$INSTALL_DIR" pull --ff-only 2>/dev/null || {
        echo -e "${YELLOW}[WARN]${NC} Pull failed. Re-cloning..."
        rm -rf "$INSTALL_DIR"
        if ! git clone --depth=1 --branch main "$REPO_URL" "$INSTALL_DIR"; then
            echo -e "${RED}[FAIL]${NC} Clone failed. Check your internet connection."
            exit 1
        fi
    }
else
    # Remove any existing directory that's not a git repo
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
    fi
    if ! git clone --depth=1 --branch main "$REPO_URL" "$INSTALL_DIR"; then
        echo -e "${RED}[FAIL]${NC} Clone failed. Check your internet connection."
        exit 1
    fi
fi

if [ ! -f "$INSTALL_DIR/install.sh" ]; then
    echo -e "${RED}[FAIL]${NC} Installer files incomplete. Retrying may fix it."
    exit 1
fi

echo -e "${GREEN}[OK]${NC} Repository cloned successfully."

# Run the installer
bash "$INSTALL_DIR/install.sh"

chmod +x "$INSTALL_DIR/uninstall.sh"
