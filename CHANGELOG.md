# Changelog - OpenClaw Termux Edition

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
