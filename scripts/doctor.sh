#!/usr/bin/env bash
# scripts/doctor.sh — Advanced System Health Diagnostic for Termux
set -euo pipefail

# Find PROJECT_DIR - either from installed location or relative to script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
if [ -f "$SCRIPT_DIR/lib.sh" ]; then
    source "$SCRIPT_DIR/lib.sh"
else
    source "$HOME/.openclaw-android/scripts/lib.sh"
fi

banner "OpenClaw Termux Edition — DOCTOR" "$CYAN"
echo ""

ERRORS=0
WARNINGS=0

# 1. 🔍 Basic Environment
step "Checking Core System"
if [ -n "${PREFIX:-}" ]; then
    echo -e "  OS: Termux (Android)"
    ARCH=$(uname -m)
    echo -e "  Architecture: $ARCH"
else
    echo -e "  ${RED}[FAIL]${NC} Not running in Termux (\$PREFIX missing)."
    ERRORS=$((ERRORS+1))
fi

# 2. ⚡ Battery & Background Performance
step "Checking Background Stability"
# Check if wake lock is held
if pgrep -f "termux.app/.WakeLock" >/dev/null; then
    echo -e "  ${GREEN}[PASS]${NC} Wake lock is active."
else
    echo -e "  ${YELLOW}[WARN]${NC} Wake lock NOT active. OpenClaw might be killed when screen is off."
    echo -e "         Fix: Run ${BOLD}termux-wake-lock${NC}"
    WARNINGS=$((WARNINGS+1))
fi

# 3. 💾 Storage Permissions
step "Checking Storage Access"
if [ -d "$HOME/storage/shared" ]; then
    echo -e "  ${GREEN}[PASS]${NC} Storage access granted."
else
    echo -e "  ${YELLOW}[WARN]${NC} Storage access missing. Cannot access Downloads/Documents."
    echo -e "         Fix: Run ${BOLD}termux-setup-storage${NC}"
    WARNINGS=$((WARNINGS+1))
fi

# 4. 🧠 Memory & Resources
step "Checking Memory & Swap"
TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}' || echo "0")
FREE_MEM=$(grep MemFree /proc/meminfo | awk '{print int($2/1024)}' || echo "0")
SWAP_TOTAL=$(grep SwapTotal /proc/meminfo | awk '{print int($2/1024)}' || echo "0")

echo -e "  Total RAM: ${TOTAL_MEM}MB"
echo -e "  Free RAM:  ${FREE_MEM}MB"

if is_low_ram; then
    echo -e "  ${YELLOW}[LOW RAM]${NC} Device has <2GB RAM."
    if [ "$SWAP_TOTAL" -eq 0 ]; then
        echo -e "  ${RED}[CRITICAL]${NC} No Swap/ZRAM detected. Native modules will likely fail to compile."
        ERRORS=$((ERRORS+1))
    fi
fi

# 5. 🌐 Network Connectivity
step "Checking Connectivity"
if ping -c 1 8.8.8.8 &>/dev/null; then
    echo -e "  ${GREEN}[PASS]${NC} Internet access OK."
else
    echo -e "  ${RED}[FAIL]${NC} Internet access FAIL. Check Wi-Fi/Data."
    ERRORS=$((ERRORS+1))
fi

# 6. 🦖 Legacy Architecture (ARMv7) Specifics
if is_armv7l; then
    step "ARMv7 Compatibility Audit"
    if [ "${OA_GLIBC:-}" = "0" ]; then
        echo -e "  ${GREEN}[PASS]${NC} Using native armv7 environment."
    else
        echo -e "  ${RED}[FAIL]${NC} OA_GLIBC should be 0 for armv7 natives."
        echo -e "         Fix: Run ${BOLD}oa fix-env${NC}"
        ERRORS=$((ERRORS+1))
    fi
fi

# 7. 🟢 OpenClaw Core Health
step "Checking OpenClaw Core"
if command -v openclaw &>/dev/null; then
    echo -e "  ${GREEN}[PASS]${NC} OpenClaw binary found."
    
    # Check for critical missing dependencies (e.g. @buape/carbon)
    OPENCLAW_DIR="$(npm root -g 2>/dev/null)/openclaw"
    if [ -d "$OPENCLAW_DIR" ] && [ ! -d "$OPENCLAW_DIR/node_modules/@buape/carbon" ]; then
        echo -e "  ${RED}[FAIL]${NC} Bundled plugin dependency '@buape/carbon' is missing."
        echo -e "         Fix: Run ${BOLD}oa update${NC}"
        ERRORS=$((ERRORS+1))
    fi

    # Run the built-in doctor but capture output to indent it
    echo -e "  Running core diagnostic (via openclaw doctor)..."
    openclaw doctor 2>&1 | sed 's/^/    /' || echo -e "    ${RED}Core doctor failed.${NC}"
else
    echo -e "  ${RED}[FAIL]${NC} OpenClaw core not installed."
    ERRORS=$((ERRORS+1))
fi

echo ""
echo -e "----------------------------------------"
if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}EVERYTHING LOOKS PERFECT!${NC} Happy coding. 🚀"
elif [ "$ERRORS" -eq 0 ]; then
    echo -e "${YELLOW}${BOLD}SYSTEM STABLE BUT SUBOPTIMAL.${NC} $WARNINGS warning(s) found."
else
    echo -e "${RED}${BOLD}SYSTEM UNSTABLE.${NC} $ERRORS error(s) must be fixed."
fi
echo ""
