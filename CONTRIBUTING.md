# Contributing

Thank you for helping AI Monitor stay small, safe, and honest.

## Development setup

```bash
git clone <repository-url>
cd ai-monitor
./scripts/bootstrap.sh
./scripts/build.sh
./scripts/test.sh
```

Do not use a real provider account in automated tests. Use anonymized fixtures and `MockProvider`.

## Pull requests

1. Keep UI independent from provider transports and JSON-RPC strings.
2. Never persist secrets in models or `UserDefaults`.
3. Preserve the last valid snapshot on refresh failures.
4. Add tests for optional and unknown fields.
5. Update user and provider documentation.
6. Run build, tests, `shellcheck scripts/*.sh`, and a secret scan before submitting.

Provider contributions must follow [docs/creating-a-provider.md](docs/creating-a-provider.md). Security concerns belong in the private process described by [SECURITY.md](SECURITY.md), not public issues.

