#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/scripts/lib.sh"

echo "=== Installing OpenClaw Platform Package ==="
echo ""

export CPATH="$PREFIX/include/glib-2.0:$PREFIX/lib/glib-2.0/include"

python -c "import yaml" 2>/dev/null || pip install pyyaml -q || true

mkdir -p "$PROJECT_DIR/patches"
cp "$SCRIPT_DIR/../../patches/glibc-compat.js" "$PROJECT_DIR/patches/glibc-compat.js"

cp "$SCRIPT_DIR/../../patches/systemctl" "$PREFIX/bin/systemctl"
chmod +x "$PREFIX/bin/systemctl"

# Clean up existing installation for smooth reinstall
if npm list -g openclaw &>/dev/null 2>&1 || [ -d "$PREFIX/lib/node_modules/openclaw" ]; then
    echo "Existing installation detected \u2014 cleaning up for reinstall..."
    npm uninstall -g openclaw 2>/dev/null || true
    rm -rf "$PREFIX/lib/node_modules/openclaw" 2>/dev/null || true
    npm uninstall -g clawdhub 2>/dev/null || true
    rm -rf "$PREFIX/lib/node_modules/clawdhub" 2>/dev/null || true
    rm -rf "$HOME/.npm/_cacache" 2>/dev/null || true
    echo -e "${GREEN}[OK]${NC}   Previous installation cleaned"
fi

# OpenClaw update requires standard performance

echo "Running: npm install -g openclaw@latest --ignore-scripts"
echo "This may take several minutes..."
echo ""
npm install -g openclaw@latest --ignore-scripts

# OOM prevention for openclaw update
export NODE_OPTIONS="${NODE_OPTIONS:-} --max-old-space-size=512"

echo ""
echo -e "${GREEN}[OK]${NC}   OpenClaw installed"

# Fix native bindings broken by --ignore-scripts (npm/cli#4828 workaround)
OPENCLAW_DIR="$(npm root -g)/openclaw"
if [ -d "$OPENCLAW_DIR/node_modules/@snazzah/davey" ]; then
    echo "Installing native bindings for @snazzah/davey..."
    (cd "$OPENCLAW_DIR" && npm install @snazzah/davey --no-fund --no-audit --no-save 2>/dev/null) || true
fi

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

# Optimization: Skip 'openclaw update' on ARMv7 if we just installed @latest
# These devices often OOM during the redundant update check.
if [ "$IS_ARMV7L" = true ]; then
    echo -e "${YELLOW}[SKIP]${NC} Skipping 'openclaw update' on ARMv7 to prevent OOM."
    echo "       The latest version was already installed via npm."
else
    echo ""
    echo "Running: openclaw update"
    echo "  (This includes building native modules and may take 5-10 minutes)"
    echo ""
    openclaw update || true
fi

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
