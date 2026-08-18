#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "${1:-}" in
  -h|--help)
    printf 'Usage: ./scripts/open-project.sh [--dry-run]\nOpens AI-Monitor.xcodeproj in Xcode.\n'
    exit 0
    ;;
  --dry-run)
    printf '[dry-run] open -a Xcode %q\n' "$ROOT/AI-Monitor.xcodeproj"
    exit 0
    ;;
  "") ;;
  *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
esac

command -v open >/dev/null 2>&1 || { printf 'The macOS open command is required.\n' >&2; exit 1; }
open -a Xcode "$ROOT/AI-Monitor.xcodeproj"
