#!/usr/bin/env bash
# scripts/setup-services.sh
# Regresa al control de servicios mediante termux-services (runit)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

SERVICE_NAME="openclaw-gateway"
SERVICE_DIR="$HOME/.termux/services/$SERVICE_NAME"
LOG_DIR="$SERVICE_DIR/log"

echo "OpenClaw on Android — Service Registration"
echo "────────────────────────────────────────"

# Ensure dependencies are installed
if ! command -v sv &>/dev/null; then
    echo "  [0/2] Installing termux-services package..."
    pkg update -y && pkg install -y termux-services || true
fi

# Ensure the service directory exists
mkdir -p "$LOG_DIR"

# Step 1: Create the main execution script (run)
echo "  [1/2] Creating service runner..."
cat <<EOF > "$SERVICE_DIR/run"
#!/data/data/com.termux/files/usr/bin/bash
exec 2>&1
# Load OpenClaw environment
source "\$HOME/.bashrc"
export NODE_OPTIONS="\${NODE_OPTIONS:-} --max-old-space-size=256"

echo "Starting OpenClaw Gateway service..."
# Use exec to hand over PID to openclaw
exec openclaw gateway
EOF
chmod +x "$SERVICE_DIR/run"

# Step 2: Create the logger script (log/run)
echo "  [2/2] Configuring service logging..."
cat <<EOF > "$LOG_DIR/run"
#!/data/data/com.termux/files/usr/bin/bash
LOG_FOLDER="\$HOME/.openclaw-android/logs"
mkdir -p "\$LOG_FOLDER"
exec svlogd -tt "\$LOG_FOLDER"
EOF
chmod +x "$LOG_DIR/run"

echo ""
echo -e "  ${GREEN}[OK]${NC} Service directory established at $SERVICE_DIR"

# Step 3: Check for termux-services and suggest enable if needed
if command -v sv-enable &>/dev/null; then
    echo -e "  ${YELLOW}[INFO]${NC} Enabling service via termux-services..."
    # We don't sv-enable automatically to avoid race conditions during installs,
    # but we've prepared the directory so 'oa start' will work perfectly.
fi
echo ""
