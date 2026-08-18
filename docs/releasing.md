# Release process

No release is created when signing or notarization inputs are missing.

## Required repository secrets

| Secret | Purpose |
|---|---|
| `APPLE_CERTIFICATE_BASE64` | Password-protected Developer ID Application `.p12` |
| `APPLE_CERTIFICATE_PASSWORD` | `.p12` import password |
| `KEYCHAIN_PASSWORD` | Temporary runner keychain password |
| `APPLE_TEAM_ID` | Developer Team ID |
| `APP_PROVISIONING_PROFILE_BASE64` | App Developer ID profile authorizing the App Group |
| `WIDGET_PROVISIONING_PROFILE_BASE64` | Widget Developer ID profile authorizing the App Group |
| `AIMONITOR_BUNDLE_ID` | Production app bundle ID |
| `AIMONITOR_APP_GROUP` | Registered App Group |
| `NOTARY_KEY_BASE64` | App Store Connect API private key |
| `NOTARY_KEY_ID` | App Store Connect API key ID |
| `NOTARY_ISSUER_ID` | App Store Connect issuer ID |

Store signing secrets in a protected GitHub environment if available. Never paste them into issues or logs.

## Prepare a release

1. Update `MARKETING_VERSION` in `Config/Project.xcconfig`.
2. Move Unreleased notes in `CHANGELOG.md` to the exact version.
3. Run `./scripts/build.sh`, `./scripts/test.sh`, and `shellcheck scripts/*.sh`.
4. Review the full diff and run the secret scan documented in `LAUNCH_CHECKLIST.md`.
5. Commit and create a matching semantic tag:

```bash
git tag -s v0.1.0 -m "AI Monitor 0.1.0"
git push origin main
git push origin v0.1.0
```

The workflow validates the tag, tests, archives, imports signing material into a temporary keychain, signs app and widget with Hardened Runtime, verifies signatures, creates `AI-Monitor.dmg`, submits it with `notarytool`, staples and verifies the ticket, checks Gatekeeper, writes `AI-Monitor.sha256`, then creates the GitHub Release.

The cleanup trap deletes the temporary keychain, decoded certificate/key, profiles, archive, and staging files even on failure.

## Manual post-release checks

1. Download the release asset on a clean supported Mac.
2. Verify `shasum -a 256 -c AI-Monitor.sha256`.
3. Open the DMG and confirm it contains only `AI Monitor.app` and the Applications alias.
4. Drag, launch, complete a consenting test login, refresh, and add both widget sizes.
5. Verify the stable download link on the landing page.
