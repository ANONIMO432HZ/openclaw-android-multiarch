# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.12] - 2026-03-30

### Added

- **New command `oa fix-env`**: Repairs environment variables in `~/.bashrc`. Run this command when you see errors about `OA_GLIBC` or `CONTAINER` not being set.
- **Fast environment verification**: Added ultra-fast environment check to all CLI commands. The check runs in microseconds when variables are already configured.
- **Smart error messages**: Verification scripts now suggest running `oa fix-env` instead of attempting auto-repair, giving users more control.

### Fixed

- **Environment setup bug**: Fixed `setup-env.sh` to correctly detect both installed and source-based execution paths, resolving the "lib.sh not found" error.
- **Duplicate .bashrc entries**: Added cleanup logic to remove legacy environment blocks before writing new ones, preventing duplicate/conflicting entries.
- **armv7l architecture detection**: Corrected logic for native Node.js detection on 32-bit devices.

### Changed

- **Simplified verification**: Removed auto-repair from verification scripts. Users can now run `oa fix-env` manually when needed, making the process more transparent.
- **Performance**: Environment checks now use fast-path optimization (instant return when variables are already set).

## [1.2.0-beta] - 2026-03-25

### Added

- **Full ARMv7/32-bit (Android 7+) support**: Automatic fallback to native Node.js and Termux packages when `aarch64` is not available.
- **Experimental glibc Skip**: Intelligent detection that avoids glibc-runner overhead on incompatible architectures.
- **SSH Tunneling Support**: Added documentation for secure remote access ("Origin Not Allowed" bypass).
- **Thermal & OOM Mitigation**: Limit parallel npm jobs and set Node.js memory heap limits for legacy/low-RAM devices.
- **Auto-Config Patching**: Automatically bind OpenClaw gateway to `0.0.0.0` for easier SSH/Network access.

### Fixed

- **Bonjour/mDNS warnings**: Auto-disable mDNS when Android/Termux only exposes loopback (`lo`), preventing noisy Gateway shutdown warnings.
- **Architecture Verification**: Updated `verify-install.sh` to correctly check native environments.

## [1.0.6] - 2026-03-10

### Changed

- Clean up existing installation on reinstall

## [1.0.5] - 2026-03-06

### Added

- Standalone Android APK with WebView UI, native terminal, and extra keys bar
- Multi-session terminal tab bar with swipe navigation
- Boot auto-start via BootReceiver
- Chromium browser automation support (`scripts/install-chromium.sh`)
- `oa --install` command for installing optional tools independently

### Fixed

- `update-core.sh` syntax error (extra `fi` on line 237)
- sharp image processing with WASM fallback for glibc/bionic boundary

### Changed

- Switch terminal input mode to `TYPE_NULL` for strict terminal behavior

## [1.0.4] - 2025-12-15

### Changed

- Upgrade Node.js to v22.22.0 for FTS5 support (`node:sqlite` static bundle)
- Show version in all update skip and completion messages

### Removed

- oh-my-opencode support (OpenCode uses internal Bun, PATH-based plugins not detected)

### Fixed

- Update version glob picks oldest instead of latest
- Native module build failures during update

## [1.0.3] - 2025-11-20

### Added

- `.gitattributes` for LF line ending enforcement

### Changed

- Bump version to v1.0.3

## [1.0.2] - 2025-10-15

### Added

- Platform-plugin architecture (`platforms/<name>/` structure)
- Shared script library (`scripts/lib.sh`)
- Verification system (`tests/verify-install.sh`)

### Changed

- Refactor install flow into modular scripts
- Separate platform-specific code from infrastructure

## [1.0.1] - 2025-09-01

### Fixed

- Initial bug fixes and stability improvements

## [1.0.0] - 2025-08-15

### Added

- Initial release
- glibc-runner based execution (no proot-distro required)
- One-command installer (`curl | bash`)
- Node.js glibc wrapper for standard Linux binaries on Android
- Path conversion for Termux compatibility
- Optional tools: tmux, code-server, OpenCode, AI CLIs
- Post-install verification
