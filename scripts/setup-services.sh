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
# OpenClaw Gateway Service Runner
# Managed by: OpenClaw CLI (oa)

# Hand over stderr to stdout for svlogd
exec 2>&1

# 1. Environment and Path setup
export PROJECT_DIR="\$HOME/.openclaw-android"
export SVDIR="\$PREFIX/var/service"

# Load full environment (especially for Node scripts/wrappers)
if [ -f "\$HOME/.bashrc" ]; then
    source "\$HOME/.bashrc"
fi

# 2. Performance and Tuning
export NODE_OPTIONS="\${NODE_OPTIONS:-} --max-old-space-size=256"

# 3. Execution
cd "\$PROJECT_DIR" || exit 1
echo "======================================================="
echo "Starting OpenClaw Gateway (PID: \$\$)"
echo "Time: \$(date)"
echo "======================================================="

# Hand over process to Node/OpenClaw
exec openclaw gateway
EOF
chmod +x "$SERVICE_DIR/run"

# Step 2: Create the logger script (log/run)
echo "  [2/2] Configuring service logging..."
cat <<EOF > "$LOG_DIR/run"
#!/data/data/com.termux/files/usr/bin/bash
# Managed by: OpenClaw CLI (oa)
LOG_FOLDER="\$HOME/.openclaw-android/logs"
mkdir -p "\$LOG_FOLDER"
exec svlogd -tt "\$LOG_FOLDER"
EOF
chmod +x "$LOG_DIR/run"

echo ""
echo -e "  ${GREEN}[OK]${NC} Service directory established at $SERVICE_DIR"

# Step 3: Link and Enable Service
if command -v sv-enable &>/dev/null; then
    echo -e "  ${YELLOW}[INFO]${NC} Activating service symlink (sv-enable)..."
    sv-enable openclaw-gateway >/dev/null 2>&1 || true
    echo -e "  ${GREEN}[OK]${NC} Service linked to \$PREFIX/var/service."
else
    echo -e "  ${RED}[WARN]${NC} sv-enable not found. Please install termux-services."
fi
echo ""
