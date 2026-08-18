# GitHub community setup

After the repository is public, enable **Issues**, **Discussions**, private vulnerability reporting, and GitHub Pages.

Suggested Discussion categories:

- Announcements (maintainers only)
- General
- Ideas
- Provider Requests
- Show and Tell
- Q&A

Use `./scripts/setup-github.sh --dry-run` to preview label commands. Run without `--dry-run` only after reviewing the repository detected from `git remote` and confirming interactively.

Recommended branch protection for `main`: require pull requests, require the CI check, dismiss stale approvals, block force pushes/deletion, and require conversation resolution. Keep Actions’ default token read-only; the included workflows elevate only individual jobs.

