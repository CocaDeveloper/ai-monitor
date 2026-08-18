#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: ./scripts/bootstrap.sh [--dry-run]

Checks the local macOS toolchain and regenerates the checked-in Xcode project.
This script never installs software or writes credentials.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$arg" >&2; usage >&2; exit 2 ;;
  esac
done

require() {
  command -v "$1" >/dev/null 2>&1 || { printf 'Missing required tool: %s\n' "$1" >&2; exit 1; }
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'AI Monitor requires macOS for native builds.\n' >&2
  exit 1
fi

require xcodebuild
require xcrun
require python3
require git

printf 'Xcode: %s\n' "$(xcodebuild -version | tr '\n' ' ')"
printf 'Swift: %s\n' "$(xcrun swift --version | head -n 1)"

if (( DRY_RUN )); then
  printf '[dry-run] python3 %q\n' "$ROOT/scripts/generate-xcodeproj.py"
  exit 0
fi

python3 "$ROOT/scripts/generate-xcodeproj.py"
printf 'Bootstrap complete. Open %s\n' "$ROOT/AI-Monitor.xcodeproj"
