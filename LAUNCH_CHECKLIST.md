# Ethical launch checklist

## Product evidence
- [ ] Install the exact release DMG on clean Intel and Apple silicon Macs.
- [ ] Capture real menu bar, onboarding, Settings, and widget screenshots from that build.
- [ ] Complete one consenting Codex login and verify primary/secondary reset values against the official client.
- [ ] Verify offline behavior keeps the last snapshot.
- [ ] Run VoiceOver, keyboard navigation, Reduce Motion, Increase Contrast, light mode, and dark mode checks.
- [ ] Confirm Kling is labeled unavailable unless official balance access is proven.

## Release integrity
- [ ] CI and all tests pass for the release commit.
- [ ] `codesign --verify --deep --strict --verbose=2` passes.
- [ ] `spctl -a -vv -t install` passes for the app.
- [ ] `xcrun stapler validate` passes for the DMG.
- [ ] SHA-256 matches the downloaded asset.
- [ ] DMG contains only the app and Applications alias.

## Secret and privacy review

```bash
python3 scripts/audit-public-repo.py
```

- [ ] Confirm the public repository audit passes.
- [ ] Export diagnostics and confirm the disclosure matches the file.
- [ ] Confirm there is no analytics, hidden network endpoint, credential log, or private account directory.

## Community launch
- [ ] README communicates status honestly in the first screen.
- [ ] Real screenshots replace design previews only after validation.
- [ ] Pages, Privacy, Support, Security, Issues, and Discussions work.
- [ ] Roadmap marks only completed work.
- [ ] Post in relevant communities once, follow their rules, and answer questions.

Never use bots, purchased or exchanged stars, fake accounts, spam, star-gated giveaways, fabricated download/user counts, or invented testimonials. Reliability, memorable design, useful documentation, and respectful support are the growth strategy.
