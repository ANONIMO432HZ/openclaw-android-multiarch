#!/usr/bin/env bash
# install-infra-deps.sh - Install core infrastructure packages (L1)
# Extracted from install-deps.sh — infrastructure only.
# Always runs regardless of platform selection.
#
# Installs: git (+ pkg update/upgrade)
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo "=== Installing Infrastructure Dependencies ==="
echo ""

# Update and upgrade package repos (Non-fatal if mirrors are temporarily down)
echo "Updating package repositories..."
echo "  (This may take a minute depending on mirror speed)"
pkg update -y || echo -e "${YELLOW}[WARN]${NC} pkg update failed. Trying to proceed with existing cache..."
pkg upgrade -y || echo -e "${YELLOW}[WARN]${NC} pkg upgrade failed. Trying to proceed..."

# Define required infrastructure packages
DEPS="git curl nodejs termux-services procps"

# Check which packages are missing
MISSING=""
for dep in $DEPS; do
    if ! command -v "$dep" &>/dev/null && [ "$dep" != "termux-services" ] && [ "$dep" != "procps" ]; then
        MISSING="$MISSING $dep"
    elif [ "$dep" = "termux-services" ] && [ ! -d "$PREFIX/var/service" ]; then
        # termux-services check: look for a known directory or sv command
        if ! command -v sv &>/dev/null; then MISSING="$MISSING $dep"; fi
    elif [ "$dep" = "procps" ] && ! pkg list-installed procps &>/dev/null; then
        MISSING="$MISSING $dep"
    fi
done

if [ -z "$MISSING" ]; then
    echo -e "${GREEN}[OK]${NC}   All infrastructure dependencies already installed."
else
    echo "Installing missing dependencies:$MISSING..."
    if ! pkg install -y $MISSING; then
        echo -e "${RED}[FAIL]${NC} Infrastructure installation failed."
        echo -e "${YELLOW}[TIP]${NC}  Your Termux mirrors might be down or unreachable."
        echo -e "       Try running: ${BOLD}termux-change-repo${NC} and select a different mirror (e.g., Albatross or Tsinghua)."
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}Infrastructure dependencies installed.${NC}"
