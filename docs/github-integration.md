# GitHub integration

AI Monitor includes a small, read-only integration with the GitHub REST API for update discovery.

## Purpose

The app checks the latest stable GitHub Release for its configured repository so it can tell users when a newer signed release is available.

## API usage

AI Monitor requests:

```text
GET https://api.github.com/repos/{owner}/{repository}/releases/latest
```

The request uses GitHub's JSON media type and a product-specific user agent. It does not require a GitHub token for the public repository.

## Privacy and security

- No GitHub account sign-in is required for this update check.
- No GitHub credentials are stored by AI Monitor for this feature.
- The request is read-only.
- Draft and prerelease responses are not treated as stable updates.
- Failure to reach GitHub does not expose or modify local account data.

The implementation lives in `Core/Updates/UpdateChecker.swift`.

## Support

Use the repository's public issue templates for reproducible bugs and feature requests. Security reports should follow the private process in [SECURITY.md](../SECURITY.md).
