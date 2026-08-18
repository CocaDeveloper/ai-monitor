# Security Policy

## Supported versions

Before 1.0, only the latest commit on `main` is supported. After 1.0, the latest stable minor release will receive security fixes.

## Reporting a vulnerability

Do not open a public issue containing a vulnerability, token, credential, account identifier, private log, or `auth.json`. Use GitHub private vulnerability reporting after it is enabled in repository settings. If that feature is unavailable, contact the repository owner privately using the address published on their GitHub profile.

Include the affected version, impact, minimal reproduction, and suggested mitigation. Remove all real credentials. Maintainers should acknowledge a complete report within seven days; this is a response goal, not a contractual guarantee.

## Security boundaries

- Provider processes are local and use separated arguments, never shell-concatenated input.
- Codex App Server uses stdio, not an exposed network listener.
- MCP calls require an exact user-reviewed allowlist and a read-only usage name; generation, purchase, deletion, and mutation names remain blocked.
- Remote MCP uses HTTPS; cleartext HTTP is restricted to loopback development.
- Release secrets are available only to tag-triggered jobs in the protected `release` environment.
- The project contains no analytics.
