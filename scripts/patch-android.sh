#!/usr/bin/env bash
# patch-android.sh — patch OpenClaw core to allow onboarding in Termux
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

OPENCLAW_PATH="/data/data/com.termux/files/usr/lib/node_modules/openclaw"
DIST_DIR="$OPENCLAW_PATH/dist"

if [ ! -d "$DIST_DIR" ]; then
    echo -e "${RED}[FAIL]${NC} OpenClaw installation not found at $OPENCLAW_PATH"
    exit 1
fi

echo -e "${BOLD}Applying Android fix to OpenClaw core…${NC}"

# Find the file containing the error
# The hash part of the filename may change between versions
target_file=$(grep -l 'Gateway service install not supported on' "$DIST_DIR"/*.js | head -n 1 || true)

if [ -z "$target_file" ]; then
    echo -e "${GREEN}[OK]${NC}   No throw found (already patched or not present in this version)"
    exit 0
fi

echo -e "  Target: $(basename "$target_file")"

# Replace throw with a noop (return) to avoid crashing during onboarding
# The string usually matches: throw new Error(`Gateway service install not supported on ${process.platform}`);
sed -i "s/throw new Error(\`Gateway service install not supported on \${process.platform}\`);/return;/g" "$target_file"

echo -e "${GREEN}[OK]${NC}   Patch applied. You can now run 'openclaw onboarding' without errors."
