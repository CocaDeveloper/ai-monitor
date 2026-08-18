#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="$ROOT/Config/Developer.xcconfig"
BUNDLE_ID=""
APP_GROUP=""
TEAM_ID=""
GITHUB_OWNER=""
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: ./scripts/configure-project.sh [options]

Options:
  --bundle-id ID       App bundle identifier (widget uses ID.widget)
  --app-group ID       App Group identifier
  --team-id ID         Apple Developer Team ID; omit for unsigned development
  --github-owner NAME  GitHub account or organization
  --dry-run            Print the local configuration without writing it
  -h, --help           Show help

Writes only Config/Developer.xcconfig, which is ignored by Git. Team ID is not
required for unsigned builds. No credentials are requested or stored.
EOF
}

while (($#)); do
  case "$1" in
    --bundle-id) BUNDLE_ID="${2:?Missing value}"; shift 2 ;;
    --app-group) APP_GROUP="${2:?Missing value}"; shift 2 ;;
    --team-id) TEAM_ID="${2:?Missing value}"; shift 2 ;;
    --github-owner) GITHUB_OWNER="${2:?Missing value}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$BUNDLE_ID" ]]; then BUNDLE_ID="dev.aimonitor.app"; fi
if [[ -z "$APP_GROUP" ]]; then APP_GROUP="group.${BUNDLE_ID}.shared"; fi
if [[ -z "$GITHUB_OWNER" ]]; then
  REMOTE="$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)"
  if [[ "$REMOTE" =~ github\.com[:/]([^/]+)/[^/]+(\.git)?$ ]]; then GITHUB_OWNER="${BASH_REMATCH[1]}"; else GITHUB_OWNER="OWNER"; fi
fi

validate_id() { [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9.-]+$ ]] || { printf 'Invalid identifier: %s\n' "$1" >&2; exit 2; }; }
validate_id "$BUNDLE_ID"
validate_id "$APP_GROUP"
[[ -z "$TEAM_ID" || "$TEAM_ID" =~ ^[A-Z0-9]{10}$ ]] || { printf 'Team ID must be 10 uppercase letters or digits.\n' >&2; exit 2; }
[[ "$GITHUB_OWNER" =~ ^[A-Za-z0-9_.-]+$ ]] || { printf 'Invalid GitHub owner.\n' >&2; exit 2; }

CONTENT="// Local developer overrides. This file is intentionally ignored by Git.
AIMONITOR_BUNDLE_ID = $BUNDLE_ID
AIMONITOR_WIDGET_BUNDLE_ID = $BUNDLE_ID.widget
AIMONITOR_APP_GROUP = $APP_GROUP
AIMONITOR_GITHUB_OWNER = $GITHUB_OWNER"
if [[ -n "$TEAM_ID" ]]; then CONTENT+=$'\n'"DEVELOPMENT_TEAM = $TEAM_ID"; fi

if (( DRY_RUN )); then printf '%s\n' "$CONTENT"; exit 0; fi
umask 077
printf '%s\n' "$CONTENT" > "$OUTPUT"
printf 'Wrote local configuration: %s\n' "$OUTPUT"
