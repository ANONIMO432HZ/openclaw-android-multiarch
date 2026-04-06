#!/usr/bin/env bash
set -euo pipefail

# This script sets up the 'oa' CLI tool command.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/scripts/lib.sh"

echo "OpenClaw on Android — CLI Wrapper Setup"
echo "────────────────────────────────────────"

# Install to PREFIX/bin (like original) - this directory is in PATH by default
OA_CLI_PATH="$PREFIX/bin/oa"
echo "  Targeting: $OA_CLI_PATH"

# Link oa.sh to PREFIX/bin (ensures updates to $PROJECT_DIR/oa.sh are reflected)
chmod +x "$SCRIPT_DIR/oa.sh"
ln -sf "$SCRIPT_DIR/oa.sh" "$OA_CLI_PATH"
chmod +x "$OA_CLI_PATH"

# Also create oaupdate for convenience
OA_UPDATE_PATH="$PREFIX/bin/oaupdate"
if [ -f "$SCRIPT_DIR/update.sh" ]; then
    cp "$SCRIPT_DIR/update.sh" "$OA_UPDATE_PATH"
    chmod +x "$OA_UPDATE_PATH"
    echo "  Targeting: $OA_UPDATE_PATH"
fi

echo -e "  ${GREEN}[OK]${NC} CLI command installed to $PREFIX/bin"
echo ""
