# Roadmap

Only completed source features are checked. A checked source feature is not the same as a published release.

## v0.1 — foundation
- [x] Menu bar target and original retro design system
- [x] Mock provider, onboarding, account sheet, and Settings
- [x] Local account/snapshot persistence and sanitized diagnostics

## v0.2 — Codex
- [x] Typed App Server stdio client and required handshake
- [x] Browser login, account state, logout, rate limits, and notifications buffering
- [x] Multiple isolated `CODEX_HOME` directories
- [x] Primary/secondary/multiple limit parsing and tests
- [ ] Validate a complete login with a consenting test account on both Apple silicon and Intel

## v0.3 — widgets and polish
- [x] Small and Medium widget source
- [x] Shared safe snapshots and stale state
- [x] Launch at Login and manual update check
- [ ] Complete visual/VoiceOver QA on macOS 14, 15, and 26

## v0.4 — Kling and MCP beta
- [x] Honest unavailable state when balance is not officially readable
- [x] MCP models, Keychain credential wrapper, HTTPS policy, and explicit read-only tool allowlist
- [ ] Enable a Kling connection only after an official read-only balance interface is verified
- [ ] Finish reviewed Custom MCP connection editor and Streamable HTTP/SSE support

## v1.0 — public release
- [ ] Configure real bundle IDs, Team ID, and App Group
- [ ] Produce a universal Developer ID signed app
- [ ] Notarize and staple `AI-Monitor.dmg`
- [ ] Publish the first stable GitHub Release and Pages site

## Good first issues
- Add missing Portuguese strings to the String Catalog.
- Add VoiceOver assertions for an account row.
- Add a high-contrast accessibility theme.
- Improve the empty-state illustration without using company logos.
- Document one provider’s official read-only capabilities.
- Add a regression fixture for an optional Codex field.
