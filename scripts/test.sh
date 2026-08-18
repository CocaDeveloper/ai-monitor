#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="${DERIVED_DATA:-$ROOT/DerivedData}"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: ./scripts/test.sh [--derived-data PATH] [--dry-run]

Builds the unsigned unit-test bundle, then runs it with xctest. This avoids an
Xcode 26 unsigned test-runner issue while keeping pull-request CI secret-free.
EOF
}

while (($#)); do
  case "$1" in
    --derived-data) DERIVED_DATA="${2:?Missing path after --derived-data}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

command -v xcodebuild >/dev/null 2>&1 || { printf 'Xcode command-line tools are required.\n' >&2; exit 1; }
ARCH="$(uname -m)"
BUILD=(xcodebuild -project "$ROOT/AI-Monitor.xcodeproj" -scheme AI-Monitor
  -configuration Debug -destination "platform=macOS,arch=$ARCH"
  -derivedDataPath "$DERIVED_DATA" CODE_SIGNING_ALLOWED=NO
  ONLY_ACTIVE_ARCH=YES "ARCHS=$ARCH" build-for-testing)
TEST_BUNDLE="$DERIVED_DATA/Build/Products/Debug/AI Monitor Tests.xctest"

if (( DRY_RUN )); then
  printf '[dry-run] '; printf '%q ' "${BUILD[@]}"; printf '\n'
  printf '[dry-run] xcrun xctest %q\n' "$TEST_BUNDLE"
  exit 0
fi

"${BUILD[@]}"
[[ -d "$TEST_BUNDLE" ]] || { printf 'Test bundle not found: %s\n' "$TEST_BUNDLE" >&2; exit 1; }
xcrun xctest "$TEST_BUNDLE"
