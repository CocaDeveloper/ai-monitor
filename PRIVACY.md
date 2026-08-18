# Privacy

AI Monitor is local-first and contains no analytics, advertising, crash-reporting SDK, or tracking pixel.

## Data stored on your Mac

`~/Library/Application Support/AI Monitor/` contains non-secret account names, provider type, order, preferences, last valid usage snapshots, update times, and one isolated Codex directory per account.

Codex authentication is created and refreshed by the official Codex software inside the account’s `CODEX_HOME`. AI Monitor never asks for your ChatGPT password and never copies a token between accounts. Advanced MCP bearer credentials belong in macOS Keychain, not JSON or `UserDefaults`.

The widget receives only account display names, provider type, summary text, status, reset summary, and update time through an App Group container. It receives no credentials and never starts provider software.

## Network activity

AI Monitor has no backend. The Codex App Server contacts OpenAI as part of the account flow. **Check for Updates** contacts GitHub’s public Releases API. An advanced MCP connection contacts only the endpoint the user explicitly reviews and approves.

## Diagnostics

Before export, AI Monitor lists every category included. Exports omit account IDs, full email addresses, tokens, API keys, cookies, passwords, `auth.json`, private keys, MCP secrets, and credential-bearing URLs.

## Disconnect and removal

1. Disconnect each account in Settings if you want the provider to clear its managed session.
2. Quit AI Monitor and remove it from Applications.
3. Delete `~/Library/Application Support/AI Monitor/` to remove accounts, snapshots, preferences, and isolated Codex homes.
4. Open **Keychain Access**, search for `dev.aimonitor.mcp`, and remove entries created for Custom MCP if that beta was used.
5. Remove AI Monitor from **System Settings → General → Login Items** if it remains listed.
6. Removing the widget from the desktop removes its presentation; deleting the App Group container may require signing-specific knowledge and is normally handled by macOS when the signed apps are removed.

Provider-side data and subscriptions are controlled by each provider and are not deleted merely by removing AI Monitor.

