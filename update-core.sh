#!/usr/bin/env bash
set -euo pipefail

# This script updates OpenClaw on Android while maintaining architecture compatibility.
PROJECT_DIR="$HOME/.openclaw-android"
TOTAL_STEPS=5
OA_VERSION="1.0.12"
source "$PROJECT_DIR/installer/scripts/lib.sh"

banner "OpenClaw on Android - Updater" "$OA_VERSION"

step 1 "Pre-flight Check"

if [ -z "${PREFIX:-}" ]; then
    echo -e "${RED}[FAIL]${NC} Not running in Termux (\$PREFIX not set)"
    exit 1
fi

if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}[FAIL]${NC} OpenClaw is not installed. Use bootstrap.sh instead."
    exit 1
fi

echo -e "${GREEN}[OK]${NC} Environment ready for update."

step 2 "Architecture Update"
# Update the local installer repository for latest scripts
cd "$PROJECT_DIR/installer"
echo "Updating installer scripts..."
git fetch origin main > /dev/null 2>&1
git reset --hard origin/main > /dev/null 2>&1
echo -e "${GREEN}[OK]${NC} Scripts updated to latest main branch."

step 3 "Core Update (npm)"
# Update the core npm package
# On ARMv7, we skip the memory-heavy postinstall if memory is low
if is_low_ram && is_armv7l; then
    echo -e "${YELLOW}[LOW RAM MODE]${NC} Limiting Node.js memory for update stability."
    export NODE_OPTIONS="--max-old-space-size=512"
fi

echo "Installing latest openclaw via npm..."
npm install -g openclaw@latest --no-audit --no-fund --ignore-scripts
echo -e "${GREEN}[OK]${NC} OpenClaw core updated."

step 4 "Patch Application"
# Re-apply patches (in case npm update overwrote them)
echo -e "${BOLD}Applying Android-specific patches...${NC}"
bash "$PROJECT_DIR/installer/platforms/openclaw/patches/openclaw-apply-patches.sh"
echo -e "${GREEN}[OK]${NC} Core patched successfully."

step 5 "Post-update (Platform Sync)"
# Sync platform-specific configs or native modules
PLATFORM=$(cat "$PLATFORM_MARKER" 2>/dev/null || echo "openclaw")
echo "Syncing platform: $PLATFORM"

# Optimization: Skip 'openclaw update' on ARMv7 to prevent OOM
# NPM install with --ignore-scripts is sufficient and we re-apply patches manually.
if is_armv7l; then
    echo -e "${YELLOW}[SKIP]${NC} Skipping 'openclaw update' on ARMv7 to prevent OOM."
    echo "       The latest version was already installed via npm."
else
    echo "Building native modules..."
    openclaw update || true
fi

# Cleanup
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Update Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Current Version: $OA_VERSION"
echo ""
echo "Try running:"
echo -e "  ${BOLD}oa status${NC} - To verify everything is running"
echo ""
