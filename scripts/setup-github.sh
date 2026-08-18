#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="dry-run"
ASSUME_YES=0
REPO=""

usage() {
  cat <<'EOF'
Usage: ./scripts/setup-github.sh [--repo OWNER/REPO] [--apply] [--yes]

Shows the GitHub labels it would create. Remote changes require --apply and an
interactive confirmation; --yes is intended only for already-reviewed scripts.
No repository is created and no remote is added.
EOF
}

while (($#)); do
  case "$1" in
    --repo) REPO="${2:?Missing OWNER/REPO}"; shift 2 ;;
    --dry-run) MODE="dry-run"; shift ;;
    --apply) MODE="apply"; shift ;;
    --yes) ASSUME_YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

command -v gh >/dev/null 2>&1 || { printf 'GitHub CLI (gh) is required.\n' >&2; exit 1; }
if [[ -z "$REPO" ]]; then
  REMOTE="$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)"
  [[ "$REMOTE" =~ github\.com[:/]([^/]+)/([^/]+?)(\.git)?$ ]] && REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
fi
[[ "$REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || { printf 'Pass --repo OWNER/REPO or configure a GitHub origin remote.\n' >&2; exit 2; }

LABELS=(
  'bug|d73a4a|Something is not working'
  'enhancement|a2eeef|New feature or improvement'
  'good first issue|7057ff|Approachable for a first contribution'
  'help wanted|008672|Extra attention is welcome'
  'provider|1d76db|Provider integration work'
  'codex|2dba4e|Codex provider'
  'kling|f9d0c4|Kling beta provider'
  'mcp|0052cc|Model Context Protocol'
  'widget|bfd4f2|WidgetKit extension'
  'documentation|0075ca|Documentation improvements'
  'security|b60205|Security and privacy'
  'design|fbca04|Visual or interaction design'
)

printf 'Target: %s\n' "$REPO"
for entry in "${LABELS[@]}"; do
  IFS='|' read -r name color description <<< "$entry"
  printf '  gh label create %q --repo %q --color %q --description %q --force\n' "$name" "$REPO" "$color" "$description"
done
if [[ "$MODE" == "dry-run" ]]; then printf 'Dry run only. Re-run with --apply to make these changes.\n'; exit 0; fi

gh auth status >/dev/null 2>&1 || { printf 'Authenticate gh before applying remote changes.\n' >&2; exit 1; }
if (( ! ASSUME_YES )); then
  printf 'Type APPLY to update labels in %s: ' "$REPO" >&2
  read -r confirmation
  [[ "$confirmation" == "APPLY" ]] || { printf 'Cancelled; no remote changes made.\n'; exit 1; }
fi
for entry in "${LABELS[@]}"; do
  IFS='|' read -r name color description <<< "$entry"
  gh label create "$name" --repo "$REPO" --color "$color" --description "$description" --force
done
printf 'Labels updated. Repository settings remain unchanged.\n'
