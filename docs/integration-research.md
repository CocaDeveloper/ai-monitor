# Integration research

Reviewed **2026-08-17**. Fragile integrations must be rechecked before release.

## Codex / OpenAI

Primary sources:

- [Official Codex App Server documentation](https://learn.chatgpt.com/docs/app-server)
- [Official Codex authentication documentation](https://learn.chatgpt.com/docs/auth)
- [Official Codex CLI documentation](https://learn.chatgpt.com/docs/codex/cli)

Verified protocol details used by this project:

- start `codex app-server` with local stdio and perform one `initialize` request followed by an `initialized` notification;
- `account/read` returns managed ChatGPT account state, optional email, and plan type;
- `account/login/start` with `type: chatgpt` returns a browser authentication URL and login ID;
- `account/login/completed` and `account/updated` report completion/state changes;
- `account/logout` clears the managed login;
- `account/rateLimits/read` and `account/rateLimits/updated` expose the backward-compatible primary bucket plus `rateLimitsByLimitId`, primary/secondary windows, `usedPercent`, `windowDurationMins`, and Unix-second `resetsAt` values;
- credentials stored in file mode live below `CODEX_HOME/auth.json`, and Codex refreshes managed ChatGPT tokens.

AI Monitor does not use scraping, cookies, passwords, or externally managed ChatGPT tokens. Unknown JSON fields are ignored and multiple limit IDs are preserved.

## Apple platforms

Primary sources:

- [MenuBarExtra](https://developer.apple.com/documentation/swiftui/menubarextra)
- [WidgetKit](https://developer.apple.com/documentation/widgetkit)
- [Developing a WidgetKit strategy](https://developer.apple.com/documentation/WidgetKit/Developing-a-WidgetKit-strategy)
- [Configuring App Groups](https://developer.apple.com/documentation/xcode/configuring-app-groups)
- [SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice)
- [Notarizing macOS software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [Customizing notarization](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow)

The app uses `LSUIElement`, a window-style `MenuBarExtra`, `SMAppService.mainApp`, WidgetKit, safe App Group snapshots, Hardened Runtime in target settings, and `notarytool` in release automation.

## Kling

Primary sources reviewed:

- [KlingAI Open Platform overview](https://kling.ai/document-api/quickStart%2FproductIntroduction%2Foverview)
- [Kling AI payment policy](https://kling.ai/docs/payment-policy)

The official consumer service documents credits and an on-site Credit Details screen. The public developer documentation reviewed did **not** establish an official MCP server or a supported read-only API that exposes the logged-in consumer’s credit balance to this desktop app. Generation APIs are not an acceptable substitute because calls may spend resources.

Therefore Kling remains **Beta / Usage unavailable**. AI Monitor will not scrape the website, use a community server by default, or call generation tools to infer balance.

## GitHub

Primary sources:

- [Secure use of GitHub Actions](https://docs.github.com/en/actions/reference/security/secure-use)
- [GitHub Pages custom workflows](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages)
- [Managing releases](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)

CI uses read-only contents permissions and never `pull_request_target`. Release secrets are isolated to tag builds with only `contents: write`; Pages receives only `contents: read`, `pages: write`, and `id-token: write` where required.

