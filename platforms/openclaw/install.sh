#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/scripts/lib.sh"

echo "=== Installing OpenClaw Platform Package ==="
echo ""

export CPATH="$PREFIX/include/glib-2.0:$PREFIX/lib/glib-2.0/include"

python -c "import yaml" 2>/dev/null || pip install pyyaml -q || true

mkdir -p "$PROJECT_DIR/patches"
cp "$SCRIPT_DIR/../../patches/glibc-compat.js" "$PROJECT_DIR/patches/glibc-compat.js" 2>/dev/null || true

cp "$SCRIPT_DIR/../../patches/systemctl" "$PREFIX/bin/systemctl"
chmod +x "$PREFIX/bin/systemctl"

# Clean up existing installation for smooth reinstall
if npm list -g openclaw &>/dev/null 2>&1 || [ -d "$PREFIX/lib/node_modules/openclaw" ]; then
    echo "Existing installation detected \u2014 cleaning up for reinstall..."
    npm uninstall -g openclaw 2>/dev/null || true
    rm -rf "$PREFIX/lib/node_modules/openclaw" 2>/dev/null || true
    rm -f "$PROJECT_DIR"/.plugins_repaired_* 2>/dev/null || true
    npm uninstall -g clawdhub 2>/dev/null || true
    rm -rf "$PREFIX/lib/node_modules/clawdhub" 2>/dev/null || true
    rm -rf "$HOME/.npm/_cacache" 2>/dev/null || true
    echo -e "${GREEN}[OK]${NC}   Previous installation cleaned"
fi

# OpenClaw update requires standard performance

# ───── Version Selection ─────
echo -e "${CYAN}${BOLD}OpenClaw Version Channel Selection${NC}"
echo "Choose your release track:"
echo -e "  1) ${GREEN}Stable${NC} (v2026.3.28)  — ${GREEN}Recommended, tested for Termux${NC}"
echo -e "  2) ${CYAN}Latest${NC} (v2026.4.5+) — Newest features, may need repairs"
echo ""

CHANNEL_VERSION="latest"
if [[ "${OA_YES:-}" == "true" ]]; then
    CHOICE="1"
elif [[ "${OA_YES:-}" == "false" ]]; then
    CHOICE="2"
else
    echo -n "Select version [1-2, default 1]: "
    read -r CHOICE < /dev/tty || CHOICE="1"
fi

if [[ "$CHOICE" == "2" ]]; then
    CHANNEL_VERSION="latest"
    echo -e "${CYAN}[CHANNEL]${NC} Tracking Latest"
else
    CHANNEL_VERSION="${OPENCLAW_STABLE_VERSION:-2026.3.28}"
    echo -e "${GREEN}[CHANNEL]${NC} Pinned to Stable ($CHANNEL_VERSION)"
fi

# Save channel preference for future updates
echo "$CHANNEL_VERSION" > "$PROJECT_DIR/.openclaw_version_channel"

echo ""
echo "Attempting to install OpenClaw Core ($CHANNEL_VERSION)..."
echo "This may take several minutes..."
echo ""

if npm install -g "openclaw@$CHANNEL_VERSION" --ignore-scripts 2>&1; then
    echo -e "${GREEN}[OK]${NC}   OpenClaw Core installed ($CHANNEL_VERSION)"
elif [ -n "$OPENCLAW_STABLE_VERSION" ] && [ "$OPENCLAW_STABLE_VERSION" != "latest" ]; then
    echo -e "${YELLOW}[WARN]${NC} latest version failed \u2014 trying stable version $OPENCLAW_STABLE_VERSION"
    if npm install -g "openclaw@${OPENCLAW_STABLE_VERSION}" --ignore-scripts 2>&1; then
        echo -e "${GREEN}[OK]${NC}   OpenClaw Core installed (stable: $OPENCLAW_STABLE_VERSION)"
    else
        echo -e "${RED}[FAIL]${NC} Both latest and stable version failed"
        exit 1
    fi
else
    echo -e "${RED}[FAIL]${NC} OpenClaw Core installation failed"
    echo "       No stable version pin configured for fallback"
    exit 1
fi

# OOM prevention for openclaw update
export NODE_OPTIONS="${NODE_OPTIONS:-} --max-old-space-size=512"

echo ""
echo -e "${GREEN}[OK]${NC}   OpenClaw installed"

# Fix native bindings and missing dependencies via centralized helper
repair_openclaw_plugins

bash "$SCRIPT_DIR/patches/openclaw-apply-patches.sh"

echo ""
echo "Installing clawdhub (skill manager)..."
if npm install -g clawdhub --no-fund --no-audit; then
    echo -e "${GREEN}[OK]${NC}   clawdhub installed"
    CLAWHUB_DIR="$(npm root -g)/clawdhub"
    if [ -d "$CLAWHUB_DIR" ] && ! (cd "$CLAWHUB_DIR" && node -e "require('undici')" 2>/dev/null); then
        echo "Installing undici dependency for clawdhub..."
        if (cd "$CLAWHUB_DIR" && npm install undici --no-fund --no-audit); then
            echo -e "${GREEN}[OK]${NC}   undici installed for clawdhub"
        else
            echo -e "${YELLOW}[WARN]${NC} undici installation failed (clawdhub may not work)"
        fi
    fi
else
    echo -e "${YELLOW}[WARN]${NC} clawdhub installation failed (non-critical)"
    echo "       Retry manually: npm i -g clawdhub"
fi

mkdir -p "$HOME/.openclaw"

# Optimization: Skip 'openclaw update' during fresh install
# The package was just installed via npm, so an update check is redundant and
# risks OOM on devices.
echo -e "${YELLOW}[SKIP]${NC} Skipping 'openclaw update' (redundant on fresh install)."

# Force Sharp WASM build for ARMv7 (Legacy compatibility)
if [ "$IS_ARMV7L" = true ]; then
    step "Sharp Image Processing (WASM Fallback)"
    echo "Building sharp for ARMv7..."
    bash "$SCRIPT_DIR/patches/openclaw-build-sharp.sh" || true
fi

# Config binding fix for termux-ssh access (0.0.0.0)
CONFIG_FILE="$HOME/.openclaw/openclaw.json"
if [ -f "$CONFIG_FILE" ]; then
    echo "Patching OpenClaw config for 0.0.0.0 binding..."
    sed -i 's/"host":\s*"127.0.0.1"/"host": "0.0.0.0"/g' "$CONFIG_FILE" || true
fi
