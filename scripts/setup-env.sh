#!/usr/bin/env bash
set -euo pipefail

# Find PROJECT_DIR - either from installed location or relative to script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$SCRIPT_DIR" == "$PREFIX/bin" ]]; then
    # Script was called from $PREFIX/bin (installed), use PROJECT_DIR
    PROJECT_DIR="$HOME/.openclaw-android"
    source "$PROJECT_DIR/scripts/lib.sh"
else
    # Script is being run from source directory
    source "$SCRIPT_DIR/lib.sh"
fi

BASHRC="$HOME/.bashrc"
PLATFORM=$(detect_platform) || true

INFRA_VARS="export TMPDIR=\"\$PREFIX/tmp\"
export TMP=\"\$TMPDIR\"
export TEMP=\"\$TMPDIR\""

# Detect architecture: use IS_ARMV7L from lib.sh, fallback to uname -m
ARCH_DETECTED=$(uname -m)
if [ "${IS_ARMV7L:-}" = true ] || [[ "$ARCH_DETECTED" == "armv7l" || "$ARCH_DETECTED" == "armhf" || "$ARCH_DETECTED" == "arm" ]]; then
    INFRA_VARS="${INFRA_VARS}
export OA_GLIBC=0
export CONTAINER=1"
else
    INFRA_VARS="${INFRA_VARS}
export OA_GLIBC=1
export CONTAINER=1"
fi

PATH_LINE="export PATH=\"\$HOME/.local/bin:\$PATH\""
if [ -n "$PLATFORM" ]; then
    # Determine base directory (installed or source)
    if [ -d "$HOME/.openclaw-android" ]; then
        BASE_DIR="$HOME/.openclaw-android"
    else
        BASE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
    fi
    load_platform_config "$PLATFORM" "$BASE_DIR" 2>/dev/null || true
    if [ "${PLATFORM_NEEDS_NODEJS:-}" = true ]; then
        PATH_LINE="export PATH=\"\$HOME/.openclaw-android/node/bin:\$HOME/.local/bin:\$PATH\""
    fi
fi

PLATFORM_VARS=""
PLATFORM_ENV_SCRIPT=""
if [ -n "$PLATFORM" ]; then
    if [ -d "$HOME/.openclaw-android/platforms" ]; then
        PLATFORM_ENV_SCRIPT="$HOME/.openclaw-android/platforms/$PLATFORM/env.sh"
    else
        PLATFORM_ENV_SCRIPT="$(dirname "$(dirname "$SCRIPT_DIR")")/platforms/$PLATFORM/env.sh"
    fi
    if [ -f "$PLATFORM_ENV_SCRIPT" ]; then
        PLATFORM_VARS=$(bash "$PLATFORM_ENV_SCRIPT")
    fi
fi

ENV_BLOCK="${BASHRC_MARKER_START}
# platform: ${PLATFORM:-none}
${PATH_LINE}
${INFRA_VARS}"

if [ -n "$PLATFORM_VARS" ]; then
    ENV_BLOCK="${ENV_BLOCK}
${PLATFORM_VARS}"
fi

ENV_BLOCK="${ENV_BLOCK}
${BASHRC_MARKER_END}"

touch "$BASHRC"

# Clean up old blocks (both new markers AND legacy blocks without markers)
# Remove any existing OpenClaw environment blocks
if grep -qF "$BASHRC_MARKER_START" "$BASHRC"; then
    sed -i "/${BASHRC_MARKER_START//\//\\/}/,/${BASHRC_MARKER_END//\//\\/}/d" "$BASHRC"
fi

# Also clean up legacy block from setup-shell.sh if exists
if grep -q 'OpenClaw on Android - bin path' "$BASHRC"; then
    sed -i '/# OpenClaw on Android - bin path/,/^$/d' "$BASHRC"
fi
if grep -q 'OPENCLAW_ANDROID_DIR=' "$BASHRC"; then
    sed -i '/export OPENCLAW_ANDROID_DIR=/d' "$BASHRC"
fi

# Also clean up any CONTAINER=1 or OA_GLIBC= that might be orphaned
sed -i '/export OA_GLIBC=/d' "$BASHRC" 2>/dev/null || true
sed -i '/export CONTAINER=/d' "$BASHRC" 2>/dev/null || true
sed -i '/export TMPDIR=/d' "$BASHRC" 2>/dev/null || true

echo "" >> "$BASHRC"
echo "$ENV_BLOCK" >> "$BASHRC"

if [ ! -e "$PREFIX/bin/ar" ] && [ -x "$PREFIX/bin/llvm-ar" ]; then
    ln -s "$PREFIX/bin/llvm-ar" "$PREFIX/bin/ar"
fi
