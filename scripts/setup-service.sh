#!/usr/bin/env bash
# scripts/setup-service.sh — Configure OpenClaw as a Termux service (daemon)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

SERVICE_NAME="openclaw-gateway"
TERMUX_SV_DIR="$HOME/.termux/services/$SERVICE_NAME"
RUN_SCRIPT="$TERMUX_SV_DIR/run"

echo -e "${BOLD}OpenClaw on Android — Service Manager${NC}"
echo -e "────────────────────────────────────────"

# 1. Prerequisites
if ! command -v openclaw &>/dev/null; then
    echo -e "${RED}[FAIL]${NC} 'openclaw' command not found. Install it with: pkg install openclaw"
    exit 1
fi

if ! command -v sv &>/dev/null; then
    echo -e "  Installing termux-services..."
    pkg install -y termux-services 2>/dev/null || { echo -e "${RED}[FAIL]${NC} Could not install termux-services"; exit 1; }
fi

# 2. Check if service exists
if [ -d "$TERMUX_SV_DIR" ] && [ -f "$RUN_SCRIPT" ]; then
    echo -e "  Service already exists in $TERMUX_SV_DIR"
    echo -e "  Checking if it's already running..."
    if sv status "$SERVICE_NAME" &>/dev/null; then
        echo -e "${GREEN}[OK]${NC}   Service is already active."
        exit 0
    fi
fi

# 3. Create Service structure
echo -e "  Configuring service: $SERVICE_NAME..."
mkdir -p "$TERMUX_SV_DIR"

cat > "$RUN_SCRIPT" <<EOF
#!/usr/bin/env bash
# Termux service definition for OpenClaw Gateway
# Managed by termux-services (runit)

# Source home environment if needed
[ -f "\$HOME/.bashrc" ] && source "\$HOME/.bashrc"

# Increase memory for Node.js if low RAM (optional)
# export NODE_OPTIONS="--max-old-space-size=512"

exec openclaw gateway 2>&1
EOF

chmod +x "$RUN_SCRIPT"

# 4. Enable Service
echo -e "  Enabling and starting service..."
sv-enable "$SERVICE_NAME"

echo -e "${GREEN}[OK]${NC}   Service configured and enabled."
echo -e "       Use 'oa --stop-service' to stop it."
echo ""
echo -e "Note: The gateway will now start automatically when Termux starts."
