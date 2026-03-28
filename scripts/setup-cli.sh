#!/usr/bin/env bash
set -euo pipefail

# This script sets up the 'oa' CLI tool command.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/scripts/lib.sh"

echo "OpenClaw on Android — CLI Wrapper Setup"
echo "────────────────────────────────────────"

# Create the bin directory if it doesn't exist
mkdir -p "$HOME/bin"

# Create/Update the 'oa' command link
OA_CLI_PATH="$HOME/bin/oa"
echo "  Targeting: $OA_CLI_PATH"

# Create the wrapper script
cat > "$OA_CLI_PATH" <<EOF
#!/usr/bin/env bash
# OpenClaw Android CLI wrapper
bash "$PROJECT_DIR/installer/oa.sh" "\$@"
EOF

chmod +x "$OA_CLI_PATH"

echo -e "  ${GREEN}[OK]${NC} CLI command link created."
echo ""
