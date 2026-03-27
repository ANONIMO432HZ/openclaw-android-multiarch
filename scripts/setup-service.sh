#!/usr/bin/env bash
# scripts/setup-service.sh — Configure OpenClaw as a Termux service (daemon)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

SERVICE_NAME="openclaw-gateway"
SERVICE_DIR="$HOME/.termux/boot" # Fallback if not using termux-services
TERMUX_SV_DIR="$HOME/.termux/services/$SERVICE_NAME"
RUN_SCRIPT="$TERMUX_SV_DIR/run"

echo -e "${BOLD}OpenClaw on Android — Service Configuration${NC}"
echo -e "────────────────────────────────────────"

# 1. Prerequisites
if ! command -v openclaw &>/dev/null; then
    echo -e "${RED}[FAIL]${NC} 'openclaw' command not found. Install it with: pkg install openclaw"
    exit 1
fi

if ! command -v sv-enable &>/dev/null; then
    echo -e "  Installing termux-services..."
    pkg install -y termux-services 2>/dev/null || { echo -e "${RED}[FAIL]${NC} Could not install termux-services"; exit 1; }
fi

# 2. Create Service structure
echo -e "  Setting up service: $SERVICE_NAME..."
mkdir -p "$TERMUX_SV_DIR"

cat > "$RUN_SCRIPT" <<EOF
#!/usr/bin/env bash
# Termux service definition for OpenClaw Gateway
# Automatically restarts on failure (managed by runit)

# Source home environment if needed
[ -f "\$HOME/.bashrc" ] && source "\$HOME/.bashrc"

exec openclaw gateway 2>&1
EOF

chmod +x "$RUN_SCRIPT"

# 3. Enable Service
echo -e "  Enabling service..."
sv-enable "$SERVICE_NAME"

echo -e "${GREEN}[OK]${NC}   Service configured and enabled."
echo -e "       Use 'sv status $SERVICE_NAME' to check status."
echo -e "       Use 'sv stop $SERVICE_NAME' to stop it."
echo -e ""
echo -e "Note: The gateway will now start automatically when Termux starts."
