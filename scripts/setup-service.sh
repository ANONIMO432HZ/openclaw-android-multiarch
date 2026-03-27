#!/usr/bin/env bash
# scripts/setup-service.sh — Configure OpenClaw as a Termux background service (Optimized)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

SERVICE_NAME="openclaw-gateway"
TERMUX_SV_DIR="$HOME/.termux/services/$SERVICE_NAME"
RUN_SCRIPT="$TERMUX_SV_DIR/run"

echo -e "${BOLD}OpenClaw on Android — Service Manager${NC}"
echo -e "────────────────────────────────────────"

# 1. Faster Prerequisites Check
if ! command -v openclaw &>/dev/null; then
    echo -e "${RED}[FAIL]${NC} 'openclaw' command not found. Install it with: oa --update"
    exit 1
fi

# Only install if not present
if ! command -v sv &>/dev/null; then
    echo -e "  Installing termux-services..."
    pkg install -y termux-services 2>/dev/null || { echo -e "${RED}[FAIL]${NC} Could not install termux-services"; exit 1; }
fi

# 2. Optimized Idempotency Check
if [ -d "$TERMUX_SV_DIR" ] && [ -f "$RUN_SCRIPT" ]; then
    echo -e "  Checking if service is up-to-date..."
    # Check if we need to update the run script (compare content)
    TMP_RUN=$(mktemp)
    cat > "$TMP_RUN" <<EOF
#!/usr/bin/env bash
# Termux service definition for OpenClaw Gateway
# Managed by termux-services (runit)

# Source home environment if needed
[ -f "\$HOME/.bashrc" ] && source "\$HOME/.bashrc"

exec openclaw gateway 2>&1
EOF
    
    if diff "$RUN_SCRIPT" "$TMP_RUN" >/dev/null 2>&1; then
        rm -f "$TMP_RUN"
        # If it's already active or linked, skip everything
        if sv status "$SERVICE_NAME" >/dev/null 2>&1 || [ -L "$PREFIX/var/service/$SERVICE_NAME" ]; then
             echo -e "${GREEN}[OK]${NC}   Service is already active and up-to-date. Skipping."
             exit 0
        fi
    fi
    rm -f "$TMP_RUN"
fi

# 3. Create/Update Service structure
echo -e "  Configuring service: $SERVICE_NAME..."
mkdir -p "$TERMUX_SV_DIR/log"

# Main run script
cat > "$RUN_SCRIPT" <<EOF
#!/usr/bin/env bash
# Termux service definition for OpenClaw Gateway
# Managed by termux-services (runit)

# Source home environment if needed
[ -f "\$HOME/.bashrc" ] && source "\$HOME/.bashrc"

exec openclaw gateway 2>&1
EOF

# Log run script
cat > "$TERMUX_SV_DIR/log/run" <<EOF
#!/usr/bin/env bash
exec svlogd -tt ./
EOF

chmod +x "$RUN_SCRIPT" "$TERMUX_SV_DIR/log/run"

# 4. Enable Service (Conditional)
echo -e "  Activating service..."
if [ ! -L "$PREFIX/var/service/$SERVICE_NAME" ]; then
    sv-enable "$SERVICE_NAME" >/dev/null 2>&1 || true
fi

# Start it if stopped
sv start "$SERVICE_NAME" >/dev/null 2>&1 || true

echo -e "${GREEN}[OK]${NC}   Service configured and enabled."
echo -e "       Use 'oa stop' to stop it."
echo ""
echo -e "Note: The gateway will now start automatically when Termux starts."
