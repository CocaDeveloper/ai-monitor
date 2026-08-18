#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/DerivedData/Build/Products/Release/AI Monitor.app"
OUTPUT="$ROOT/build/AI-Monitor.dmg"
VOLUME="AI Monitor"
DRY_RUN=0
FINDER_LAYOUT=1

usage() {
  cat <<'EOF'
Usage: ./scripts/create-dmg.sh [options]

Options:
  --app PATH           Signed AI Monitor.app to package
  --output PATH        Output path (default: build/AI-Monitor.dmg)
  --volume-name NAME   Mounted volume name
  --no-finder-layout   Skip Finder icon/background customization
  --dry-run            Print commands without creating an image
  -h, --help           Show help

The DMG contains only AI Monitor.app, an Applications symlink, and a simple
background. Signing/notarization are deliberately separate release steps.
EOF
}

while (($#)); do
  case "$1" in
    --app) APP="${2:?Missing path}"; shift 2 ;;
    --output) OUTPUT="${2:?Missing path}"; shift 2 ;;
    --volume-name) VOLUME="${2:?Missing name}"; shift 2 ;;
    --no-finder-layout) FINDER_LAYOUT=0; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

for tool in hdiutil ditto python3 sips; do command -v "$tool" >/dev/null 2>&1 || { printf 'Missing tool: %s\n' "$tool" >&2; exit 1; }; done
if (( DRY_RUN )); then
  printf '[dry-run] package %q as %q (volume %q)\n' "$APP" "$OUTPUT" "$VOLUME"
  exit 0
fi
[[ -d "$APP" ]] || { printf 'App bundle not found: %s\n' "$APP" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/aimonitor-dmg.XXXXXX")"
MOUNT=""
cleanup() {
  if [[ -n "$MOUNT" && -d "$MOUNT" ]]; then hdiutil detach "$MOUNT" -quiet || true; fi
  rm -rf "$WORK"
}
trap cleanup EXIT

STAGE="$WORK/stage"
mkdir -p "$STAGE/.background" "$(dirname "$OUTPUT")"
ditto "$APP" "$STAGE/AI Monitor.app"
ln -s /Applications "$STAGE/Applications"

python3 - "$WORK/background.ppm" <<'PY'
import sys
w, h = 660, 400
with open(sys.argv[1], "wb") as f:
    f.write(f"P6\n{w} {h}\n255\n".encode())
    for y in range(h):
        for x in range(w):
            glow = max(0, 30 - int(((x-330)**2 + (y-185)**2) ** .5 / 12))
            f.write(bytes((24 + glow, 26 + glow, 24 + glow // 2)))
PY
sips -s format png "$WORK/background.ppm" --out "$STAGE/.background/install.png" >/dev/null

RW="$WORK/AI-Monitor-rw.dmg"
hdiutil create -quiet -volname "$VOLUME" -srcfolder "$STAGE" -ov -format UDRW "$RW"

if (( FINDER_LAYOUT )); then
  ATTACH_OUTPUT="$(hdiutil attach -readwrite -noverify -noautoopen "$RW")"
  MOUNT="$(printf '%s\n' "$ATTACH_OUTPUT" | awk -F '\t' '/\/Volumes\// {print $NF; exit}')"
  if [[ -n "$MOUNT" ]]; then
    LAYOUT_SCRIPT="$WORK/layout.applescript"
    cat > "$LAYOUT_SCRIPT" <<OSA
tell application "Finder"
  tell disk "$VOLUME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {100, 100, 760, 500}
    set arrangement of icon view options of container window to not arranged
    set icon size of icon view options of container window to 112
    set background picture of icon view options of container window to file ".background:install.png"
    set position of item "AI Monitor.app" of container window to {190, 210}
    set position of item "Applications" of container window to {470, 210}
    update without registering applications
    delay 2
    close
  end tell
end tell
OSA
    osascript "$LAYOUT_SCRIPT" >"$WORK/layout.log" 2>&1 &
    LAYOUT_PID=$!
    LAYOUT_FINISHED=0
    for _ in {1..30}; do
      if ! kill -0 "$LAYOUT_PID" 2>/dev/null; then
        if ! wait "$LAYOUT_PID"; then
          printf 'Warning: Finder layout failed; DMG contents are still valid.\n' >&2
          cat "$WORK/layout.log" >&2
        fi
        LAYOUT_FINISHED=1
        break
      fi
      sleep 0.5
    done
    if (( ! LAYOUT_FINISHED )); then
      kill "$LAYOUT_PID" 2>/dev/null || true
      wait "$LAYOUT_PID" 2>/dev/null || true
      printf 'Warning: Finder layout timed out; continuing with the simple packaged background.\n' >&2
    fi
    rm -rf "$MOUNT/.fseventsd" "$MOUNT/.Trashes" "$MOUNT/.Spotlight-V100"
    sync
    hdiutil detach "$MOUNT" -quiet
    MOUNT=""
  fi
fi

rm -f "$OUTPUT"
hdiutil convert "$RW" -quiet -format UDZO -imagekey zlib-level=9 -o "$OUTPUT"
printf 'Created %s\n' "$OUTPUT"
