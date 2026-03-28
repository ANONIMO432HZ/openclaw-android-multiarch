#!/usr/bin/env bash
# install-infra-deps.sh - Install core infrastructure packages (L1)
# Extracted from install-deps.sh — infrastructure only.
# Always runs regardless of platform selection.
#
# Installs: git (+ pkg update/upgrade)
set -euo pipefail

GREEN='\033[0;32m'
NC='\033[0m'

echo "=== Installing Infrastructure Dependencies ==="
echo ""

# Update and upgrade package repos
echo "Updating package repositories..."
echo "  (This may take a minute depending on mirror speed)"
pkg update -y
pkg upgrade -y

# Install core infrastructure packages
echo "Installing git..."
pkg install -y git

echo ""
echo -e "${GREEN}Infrastructure dependencies installed.${NC}"
