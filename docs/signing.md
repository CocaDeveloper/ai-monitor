# Apple signing and App Group setup

The repository does not contain or infer a Team ID. Local unsigned builds are supported by `scripts/build.sh`.

## One-time Developer configuration

1. Join the Apple Developer Program and create explicit bundle IDs for the app and widget.
2. Register an App Group beginning with `group.`, for example `group.com.example.AIMonitor`.
3. Enable the same App Group capability for both bundle IDs.
4. Create Developer ID Application provisioning profiles that authorize the capability for the app and widget, if your signing flow requires them.
5. Create a Developer ID Application certificate and export it as a password-protected `.p12` for local secure storage or GitHub Actions secrets.
6. Copy `Config/Developer.example.xcconfig` to ignored `Config/Developer.xcconfig` and set `DEVELOPMENT_TEAM`, both bundle IDs, and the App Group.

In Xcode, select **AI-Monitor** and **AI-MonitorWidget → Signing & Capabilities**. Verify the Team, explicit bundle identifier, and exact same App Group. Do not commit the generated private xcconfig or profiles.

## Local widget validation

An unsigned build proves compilation but cannot prove the signed App Group container. Build and run both targets with your Team. Add the widget, refresh the app, and confirm the timestamp changes. Check the signed entitlements:

```bash
codesign -d --entitlements :- "/path/to/AI Monitor.app"
codesign -d --entitlements :- "/path/to/AI Monitor.app/Contents/PlugIns/AI Monitor Widget.appex"
```

## Distribution requirements

Stable DMGs require a Developer ID Application signature, Hardened Runtime, secure timestamp, successful `codesign` verification, Apple notarization using `notarytool`, a stapled ticket, and `spctl` verification. See [releasing.md](releasing.md).

