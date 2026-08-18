# Creating a provider

Providers translate one official, documented service interface into the shared usage model. They must not make Views aware of transport details.

## Required interface

Implement `UsageProvider` with a stable `ProviderID`, display name, explicit capabilities, and async connect/disconnect/refresh operations. Return one `UsageSnapshot` containing any number of `UsageMetric` values.

Use:

- `.percentage` plus one or more `ResetWindow` values for percentage quotas;
- `.credits` plus `CreditBalance` for documented credit balances;
- `.measured` with `used`, `limit`, and `unit` for arbitrary quantities;
- `.unavailable` when the official service returns no monitorable data.

## Authentication

- Prefer provider-owned browser OAuth or device-code flow.
- Never request a user password, browser cookie, or copied auth file.
- Store API keys and MCP bearer credentials in Keychain.
- If the provider manages its own tokens, isolate its storage and never inspect or log the token files.
- Explain community or non-official MCP trust boundaries before connection.

## Refresh and errors

- Use read-only operations only.
- Apply the central cooldown and backoff rather than polling in the provider.
- Do not erase the last valid snapshot after a transient failure.
- Map technical failures to `ProviderError`; keep stack traces in sanitized development logs only.
- Treat absent/null fields as unavailable, never zero unless the provider explicitly reports zero.

## Tests

Provide anonymized fixtures for normal, missing, null, unknown, and future fields. Cover percentage clamping, timestamps, multiple limit IDs, authentication cancellation, timeout/crash behavior, and snapshot conversion. Automated tests must never require a real account.

## Preview example

Use `MockProvider.codex(accountID:remaining:)` or build a mock `UsageSnapshot`. Do not put sample balances in production provider code.

## Security checklist

- [ ] Official, current documentation is linked and dated.
- [ ] No scraping or private endpoint is used.
- [ ] No mutating or billable operation runs during refresh.
- [ ] Secrets never enter persisted account/snapshot models.
- [ ] Process arguments are separated and user input is not shell-concatenated.
- [ ] Logs redact tokens, keys, authorization headers, and email addresses.
- [ ] Unknown fields and unsupported versions fail safely.
- [ ] UI says “Usage unavailable” when appropriate.

