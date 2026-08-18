# Manual GitHub setup

No remote repository has been created or modified by the project scripts automatically.

- [ ] Create a **public** repository, preferably `ai-monitor`, and add it as `origin`.
- [ ] Run `./scripts/configure-project.sh --github-owner YOUR_NAME` after adding `origin`; review the ignored local xcconfig.
- [ ] Before the first push, search for `OWNER` placeholders. The Pages workflow replaces site metadata automatically; configure the app's real owner locally.
- [ ] Set description: **A tiny retro macOS menu bar app for monitoring AI usage, limits, resets and credits.**
- [ ] Set the website after Pages deploys.
- [ ] Add topics: `macos`, `swift`, `swiftui`, `menubar`, `widgetkit`, `open-source`, `codex`, `mcp`, `ai-tools`, `usage-monitor`, `productivity`, `pixel-art`.
- [ ] Upload the original social preview using [docs/github-social-preview.md](docs/github-social-preview.md).
- [ ] Enable Issues and private vulnerability reporting.
- [ ] Enable Discussions and the categories in [docs/github-setup.md](docs/github-setup.md).
- [ ] Protect `main` and require CI.
- [ ] Set Actions’ default `GITHUB_TOKEN` permission to read-only; do not allow Actions to approve pull requests.
- [ ] Under Pages, select **GitHub Actions** as the source.
- [ ] Configure a protected release environment and every secret in [docs/releasing.md](docs/releasing.md).
- [ ] Make the first signed/notarized release; verify both assets and pin it.
- [ ] Open a welcome Discussion and a few small roadmap issues.
- [ ] Confirm the README and site download buttons resolve to `releases/latest/download/AI-Monitor.dmg`.

Preview optional label commands with:

```bash
./scripts/setup-github.sh --dry-run
```

Review the printed repository and commands. The script asks for explicit confirmation before any remote change.
