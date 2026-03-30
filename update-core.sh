#!/usr/bin/env bash
set -euo pipefail

# This script updates OpenClaw on Android while maintaining architecture compatibility.
PROJECT_DIR="$HOME/.openclaw-android"
TOTAL_STEPS=5
OA_VERSION="1.1.0"
source "$PROJECT_DIR/scripts/lib.sh"

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

step 2 "Scripts Update (git)"
cd "$PROJECT_DIR"
echo "Updating scripts..."
git fetch origin main > /dev/null 2>&1 || true

LOCAL=$(git rev-parse HEAD 2>/dev/null || echo "0")
REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "1")

if [ "$LOCAL" != "$REMOTE" ]; then
    echo -e "${YELLOW}[UPDATE]${NC} New scripts found. Syncing..."
    git stash push -m "oa-auto-stash" >/dev/null 2>&1 || true
    if git pull origin main; then
        git stash pop >/dev/null 2>&1 || true
        find "$PROJECT_DIR" -maxdepth 2 -name "*.sh" -exec sed -i 's/\r$//' {} + 2>/dev/null || true
        echo -e "${GREEN}[OK]${NC} Scripts updated."
    fi
else
    echo -e "${GREEN}[OK]${NC} Scripts are up-to-date."
fi

step 3 "Core Update (npm)"
if is_low_ram && is_armv7l; then
    echo -e "${YELLOW}[LOW RAM MODE]${NC} Limiting Node.js memory for update stability."
    export NODE_OPTIONS="--max-old-space-size=512"
fi

# Load stable version pin from config
STABLE_VER=""
if [ -f "$PROJECT_DIR/platforms/openclaw/config.env" ]; then
    source "$PROJECT_DIR/platforms/openclaw/config.env"
    STABLE_VER="${OPENCLAW_STABLE_VERSION:-}"
fi

echo "Attempting to install OpenClaw Core (latest)..."
if npm install -g openclaw@latest --no-audit --no-fund --ignore-scripts 2>&1; then
    echo -e "${GREEN}[OK]${NC} OpenClaw core updated (latest)."
elif [ -n "$STABLE_VER" ] && [ "$STABLE_VER" != "latest" ]; then
    echo -e "${YELLOW}[WARN]${NC} latest failed — trying stable version $STABLE_VER"
    if npm install -g "openclaw@${STABLE_VER}" --no-audit --no-fund --ignore-scripts 2>&1; then
        echo -e "${GREEN}[OK]${NC} OpenClaw core updated (stable: $STABLE_VER)."
    else
        echo -e "${RED}[FAIL]${NC} Both latest and stable version failed"
        exit 1
    fi
else
    echo -e "${RED}[FAIL]${NC} OpenClaw core update failed"
    exit 1
fi

step 4 "Patch Application"
echo -e "${BOLD}Applying Android-specific patches...${NC}"
if [ -f "$PROJECT_DIR/scripts/patch-android.sh" ]; then
    bash "$PROJECT_DIR/scripts/patch-android.sh"
fi
if [ -f "$PROJECT_DIR/platforms/openclaw/patches/openclaw-apply-patches.sh" ]; then
    bash "$PROJECT_DIR/platforms/openclaw/patches/openclaw-apply-patches.sh"
fi
echo -e "${GREEN}[OK]${NC} Core patched successfully."

step 5 "Post-update"
if is_armv7l; then
    echo -e "${YELLOW}[SKIP]${NC} Skipping 'openclaw update' on ARMv7 to prevent OOM."
    echo "       The latest version was already installed via npm."
else
    echo "Building native modules..."
    openclaw update || true
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Update Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Run: source ~/.bashrc"
echo ""
