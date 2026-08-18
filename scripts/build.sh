#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="Debug"
DERIVED_DATA="${DERIVED_DATA:-$ROOT/DerivedData}"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: ./scripts/build.sh [--release] [--derived-data PATH] [--dry-run]

Builds the macOS app and its widget without requiring signing credentials.
EOF
}

while (($#)); do
  case "$1" in
    --release) CONFIGURATION="Release"; shift ;;
    --derived-data) DERIVED_DATA="${2:?Missing path after --derived-data}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

command -v xcodebuild >/dev/null 2>&1 || { printf 'Xcode command-line tools are required.\n' >&2; exit 1; }
ARCH="$(uname -m)"
CMD=(xcodebuild -project "$ROOT/AI-Monitor.xcodeproj" -scheme AI-Monitor
  -configuration "$CONFIGURATION" -destination "platform=macOS,arch=$ARCH"
  -derivedDataPath "$DERIVED_DATA" CODE_SIGNING_ALLOWED=NO
  ONLY_ACTIVE_ARCH=YES "ARCHS=$ARCH" build)

if (( DRY_RUN )); then
  printf '[dry-run] '; printf '%q ' "${CMD[@]}"; printf '\n'; exit 0
fi

"${CMD[@]}"
