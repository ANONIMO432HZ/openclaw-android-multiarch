#!/usr/bin/env bash
# bootstrap.sh - Download and run OpenClaw on Android installer
# Usage: curl -sL https://raw.githubusercontent.com/ANONIMO432HZ/openclaw-android-multiarch/main/bootstrap.sh | bash
set -euo pipefail

REPO_URL="https://github.com/ANONIMO432HZ/openclaw-android-multiarch.git"
INSTALL_DIR="$HOME/.openclaw-android"

RED='\033[0;31m'
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BOLD}OpenClaw on Android - Bootstrap${NC}"
echo ""

# Check for essential tools first, install if missing
for tool in git curl npm; do
    if ! command -v "$tool" &>/dev/null; then
        if ! command -v pkg &>/dev/null; then
            echo -e "${RED}[FAIL]${NC} pkg not found. Cannot install $tool. Please install it manually."
            exit 1
        fi
        echo -e "${YELLOW}[INFO]${NC} $tool not found. Attempting to install $tool..."
        pkg update -y && pkg install -y "$tool" || {
            if [ "$tool" = "npm" ]; then
                echo -e "${YELLOW}[INFO]${NC} npm package not found. Trying nodejs package instead..."
                pkg install -y nodejs
            fi
        }
    fi
done

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

# Create a visible symlink in $HOME for easy access
if [ -L "$HOME/openclaw-android" ]; then
    rm -f "$HOME/openclaw-android"
fi
ln -sf "$INSTALL_DIR" "$HOME/openclaw-android"
echo -e "${GREEN}[OK]${NC} Visible symlink created: ~/openclaw-android -> ~/.openclaw-android"

# Run the installer
chmod +x "$INSTALL_DIR/oa.sh" "$INSTALL_DIR/install.sh" "$INSTALL_DIR/uninstall.sh"
bash "$INSTALL_DIR/install.sh"
