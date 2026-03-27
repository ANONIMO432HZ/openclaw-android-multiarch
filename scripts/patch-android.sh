#!/usr/bin/env bash
# patch-android.sh — patch OpenClaw core to allow onboarding in Termux
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

OPENCLAW_PATH="/data/data/com.termux/files/usr/lib/node_modules/openclaw"
DIST_DIR="$OPENCLAW_PATH/dist"

if [ ! -d "$DIST_DIR" ]; then
    echo -e "${RED}[FAIL]${NC} OpenClaw installation not found at $DIST_DIR"
    exit 1
fi

echo -e "${BOLD}OpenClaw on Android — Core Patcher${NC}"
echo -e "────────────────────────────────────────"

# Pattern to search for (including backticks variant used in chunks)
SEARCH_PATTERN="throw new Error(\`Gateway service install not supported on \${process.platform}\`);"
REPLACEMENT="return; // Patched for Android support"

# Find all files containing the pattern
files_to_patch=()
while IFS= read -r f; do
    files_to_patch+=("$f")
done < <(grep -l "Gateway service install not supported on" "$DIST_DIR"/*.js || true)

if [ ${#files_to_patch[@]} -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC}   No files need patching (already correct or version not supported)."
    exit 0
fi

echo -e "  Found ${#files_to_patch[@]} file(s) to patch..."

for f in "${files_to_patch[@]}"; do
    echo -e "  Patching: $(basename "$f")..."
    # Using sed with a safe delimiter and escaping backticks for the shell
    sed -i "s/throw new Error(\`Gateway service install not supported on \${process.platform}\`);/$REPLACEMENT/g" "$f"
done

echo ""
echo -e "${GREEN}[OK]${NC}   Core patched successfully. You can now run 'openclaw onboarding'."
