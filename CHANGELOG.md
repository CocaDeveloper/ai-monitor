# Changelog

All notable changes will be documented here. The project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed
- Refined the compact retro-computer shell, added an original spectrum mark, reduced the menu-bar panel, and added a persistent Dock visibility option.

### Fixed
- Keep new accounts temporary until browser authentication succeeds and clean up cancelled sign-in data.
- Accept current provider credit balances returned as numeric strings.
- Restore the main window reliably without requiring the Dock icon.

## [0.1.0] - 2026-08-18

### Added
- Native macOS menu bar app scaffold with original retro CRT interface.
- Three-step onboarding, multiple-account UI, Settings, diagnostics disclosure, and local persistence.
- Official Codex App Server stdio client for browser login, account state, logout, and multi-window rate limits.
- Per-account `CODEX_HOME`, safe process launching, timeouts, crash handling, sanitization, cooldown, and backoff.
- Small and Medium WidgetKit views backed by safe shared snapshots.
- Honest Kling unavailable state and read-only MCP discovery foundation.
- Twenty-seven unit tests, five deterministic UI-test scenarios, a broad SwiftUI preview matrix, and English/pt-BR localization.
- Responsive static landing page, community templates, local developer scripts, and CI/Pages/signed-release automation.
- Explicit Custom MCP allowlists, HTTPS enforcement outside loopback, and stronger diagnostic redaction.
