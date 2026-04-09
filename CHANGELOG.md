# Changelog - OpenClaw Termux Edition

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.2.1] - 2026-04-08
### Fixed
- Critical Node.js (glibc) missing dependency on `libstdc++.so.6` (added `gcc-libs-glibc` to installer).
- Node.js wrapper script heredoc incorrectly escaping variables, causing "broken wrapper" errors.
- Cleaned up noisy `pacman` filesystem warnings during installation and uninstallation.

### Added
- Reinforced dynamic linker (`ld.so`) resolution with 3-tier fallback (Dynamic -> Absolute -> Search) in `scripts/lib.sh`.
- Multi-architecture support for `x86_64` (PC emulators) in glibc installer.
- Global confirmation for Optional Tools (Step 3) to allow for minimal, faster installations.

## [1.2.2.0] - 2026-04-08

### Added

- **Multi-Architecture Support**: Full dynamic detection and support for `aarch64`, `x86_64` (emulators), and `armv7l` (legacy) across all installation and setup scripts.
- **Enhanced Glibc Resilience**:
  - **Reinstallation Logic**: Fixed a critical bug where `pacman` would skip `glibc` if files were manually deleted. Now explicitly manages both `glibc` and `glibc-runner` packages.
  - **Keyring Workaround**: Implemented non-interactive `SigLevel = Never` patching in the uninstaller to bypass GPG signature errors on broken Termux environments.
- **Automated Platform Detection Fallback**: Improved the uninstaller to detect `openclaw` artifacts even if the environment marker is missing, ensuring a 100% clean state.
- **Improved Non-Interactive Mode**: Unified `-y`/`-n` support across all internal uninstaller prompts.

## [1.2.1.0] - 2026-04-08

### Added

- **Channel System**: User-selectable release tracks (**Latest** vs **Stable**) during installation to prevent regressions.
- **Plugin Pre-flight Repair**: Silent auto-healing for `@buape/carbon` and bundled plugins in `onboard` and `ui-config`.
- **Professional Tool Management**:
  - `oa install-tools`: New modular command for optional helpers.
  - `oa uninstall-tools`: Selective removal of components (pkg, npm, binaries).
- **Auto-Repair Runtime**: Recursive `chmod +x` and CRLF cleanup during all update/install cycles.
- **Robust Git Sync**: `oa self-update` now protects local work with `git stash` during repository synchronization.

### Fixed

- **Onboarding Broken**: Fixed the critical "Cannot find module '@buape/carbon'" error.
- **Syntax Error**: Removed redundant `fi` in `install-tools.sh`.
- **Install Path Logic**: Fixed incorrect directory pointers for tool installation.
- **Repair Loops**: Implemented version-aware user-space markers to prevent redundant "Repairing..." messages in restricted environments.
- **Bun Performance**: Enhanced fallback logic for OpenCode installation in Termux.

## [1.1.5.2] - 2026-03-31

### Added

- **Global Flag Support**: Introduced `-y/--yes` and `-n/--no` flags for all `oa` commands, enabling fully non-interactive updates and operations.
- **Dynamic Dashboard Reflection**: Refactored `oa ui` to extract IP, security tokens, and local host directly from the core process logs, providing a 100% accurate PC browser link.
- **Dual SSH Tunneling Paths**: Added "Silent Tunnel" and "Tunnel + Shell" options to the dashboard terminal view.

### Changed

- **Mobile-Safe UI Aesthetics**: Standardized minimalist 40-character separators for `oa ui` and `oa logs` to prevent visual breakage on phone screens.
- **Improved Contextual Clarity**: Refined the dashboard correction tip title and labels for professional remote access.

## [1.1.5.1] - 2026-03-31

### Fixed

- **Token Hijack Logic**: Implemented "Bridge Capture" to extract security tokens directly from the official `openclaw dashboard` output, ensuring 100% reliability.
- **Unbound Variable Fix**: Localized ANSI style variables within `cmd_ui` to prevent shell errors on strict Termux environments.
- **Optimized UI Flow**: Combined native binary accuracy with custom LAN/SSH helper links.

## [1.1.5.0] - 2026-03-31

### Added

- **Ultra-Resilient Token Extraction**: Implemented multi-path scanning for security tokens, supporting both `.openclaw` and `.openclaw-android` directory structures.
- **Redundant IP Discovery**: Added `hostname -I` fallback for network detection to ensure reliable LAN links on all Android kernels.
- **SmartTV UI Support**: Expanded dashboard access instructions for cross-device compatibility.

## [1.1.4.7] - 2026-03-31

### Fixed

- **UI Network Timeouts**: Added strict time limits (2s) to all network/IP discovery commands in `oa ui` to prevent the CLI from hanging in offline or high-latency environments.
- **Improved Token Hunt**: Refined extraction logic to be more resilient during multi-path configuration lookups.

## [1.1.4.6] - 2026-03-31

### Changed

- **Native Dashboard Reversion**: Reverted `oa ui` to use the official `openclaw dashboard` logic to ensure 100% reliable token display. Added a lightweight LAN/SSH helper at the end of the output.

## [1.1.4.5] - 2026-03-31

### Fixed

- **Multi-Method Token Extraction**: Hardened `oa ui` to extract tokens from multiple config keys and fallback to direct JSON parsing if the CLI fails.
- **Route-Based IP detection**: Switched to `ip route` for local IP detection, making it interface-agnostic (works on wlan0, eth0, or VPNs).
- **ANSI Style Fixes**: Defined missing `ITALIC` and `DIM` variables in `lib.sh` to prevent shell errors.

## [1.1.4.4] - 2026-03-31

- **Smart UI Detection**: Significantly enhanced `oa ui` with automated Local IP detection (LAN/WLAN) and 'termux-open' integration for seamless browser launching and cross-device access.

## [1.1.4.3] - 2026-03-31

### Fixed

- **Blocking Shutdown Sequence**: Refactored `cmd_stop` to wait actively for process expiration, preventing port conflicts on slow Android devices.
- **Extended Startup Grace Period**: Increased `oa start` timeout to 45 seconds with live log preview mode during verification.

## [1.1.4.2] - 2026-03-31

### Fixed

- **Process Name Resolution**: Added support for `openclaw-gateway` (hyphenated) in `pgrep` patterns, ensuring reliable process termination and preventing port conflicts.
- **Stubborn Process Cleanup**: Enhanced `cmd_stop` with mandatory SIGKILL for processes that resist SIGTERM on slow Android systems.

## [1.1.4.1] - 2026-03-31

### Fixed

- **Resilient Startup Detection**: Restored log-based readiness verification in `oa start` to prevent false positive failures on slow storage.
- **Deep Diagnostics Fallback**: Added native OpenClaw temporary log paths to `oa logs` for harder troubleshooting.
- **Visual Bug Hotfix**: Corrected a version interpolation error in the update success message.

## [1.1.4] - 2026-03-31

### Added

- **On-Demand Service Self-Healing**: `oa start:sv` and `oa stop:sv` now automatically detect missing services and register them using `setup-services.sh` before proceeding.
- **Service Dependency Management**: `setup-services.sh` now automatically installs `termux-services` via `pkg` if not found.
- **Language Selector**: Global navigation menu added to all READMEs (English, Spanish, Korean).

### Changed

- **Optimized Log Management**: `oa logs` now prioritizes professional `svlogd` logs (~/logs/current) over manual `server.log`, providing better diagnostic accuracy.
- **Global Identity Cleanup**: All documentation badges, license references, and repository links updated to point to the current official repository (`ANONIMO432HZ`).
- **Improved CLI Robustness**: Refined version fallback logic and environment repair in `oa.sh`.

### Fixed

- **Markdown Linting**: Fixed multiple blank line (MD012) and header spacing (MD022) issues across all documentation.
- **Update Cycle Polish**: Streamlined the update process to be faster, moving service registration to the on-demand phase.

## [1.1.3] - 2026-03-30

### Added

- **Granular Process Management**: Introduced dedicated commands:
  - `oa start`: Manual background mode (`nohup`).
  - `oa start:sv`: Professional service mode (`termux-services/runit`).
  - `oa start:fg`: Foreground/Debug mode with stable signal handling.
  - `oa stop:sv`: Independent service termination.
- **Professional Service Logging**: Integrated `svlogd` for efficient, rotated logs in service mode.
- **Spanish Translation**: Created `README.es.md` for the Spanish-speaking community.
- **Enhanced Status Diagnostics**: `oa status` now explicitly detects and reports if the system is running via Service or Manual/Background.

### Changed

- **V3 Refactor Completion**: Removed legacy Android/APK/React code completely; strictly Termux-native architecture.
- **Resilient Installer**: Integrated `setup-services.sh` into `install.sh` with non-blocking fault tolerance.
- **ARMv7 Optimization**: Hardened Node.js V8 flags (`--max-old-space-size=256`) explicitly for 32-bit stability.

## [1.1.2] - 2026-03-27

### Changed

- **Global Synchronization**: Aligned versioning across `oa.sh`, `scripts/lib.sh`, and primary documentation.
- **Installer Cleanup**: Removed obsolete folder references and initialized the "Platform Marker" system for better environment detection.

## [1.1.1] - 2026-03-26

### Fixed

- **Node.js Compatibility**: Patched Node.js initialization for Android 7+ (termux-exec compatibility).
- **Environment Conflicts**: Mitigated shared library conflicts in newer Termux environments.

---

*Generated with pride for the OpenClaw Android Community.*
