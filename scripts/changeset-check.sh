#!/usr/bin/env bash
# Require a changeset when PR diffs touch consumer-facing paths.
# Usage: scripts/changeset-check.sh [base-ref]
set -euo pipefail

BASE="${1:-origin/main}"
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

if [[ "${SKIP_CHANGESET_CHECK:-}" == "1" ]]; then
  echo "changeset-check: skipped (SKIP_CHANGESET_CHECK=1)"
  exit 0
fi

if git rev-parse --verify "$BASE" >/dev/null 2>&1; then
  RANGE="$BASE...HEAD"
else
  RANGE="HEAD~1...HEAD"
fi

mapfile -t CHANGED < <(git diff --name-only "$RANGE" 2>/dev/null || true)
if [[ ${#CHANGED[@]} -eq 0 ]]; then
  exit 0
fi

needs=false
for f in "${CHANGED[@]}"; do
  case "$f" in
    skills/*|plugins/*|docs/*|packages/steward_cli/*|steward.yaml|package.json|pnpm-lock.yaml|skills.sh.json|README.md|AGENTS.md|docs.json|CONTRIBUTING.md|CHANGELOG.md|scripts/*|.github/workflows/*)
      needs=true
      break
      ;;
  esac
done

if [[ "$needs" != true ]]; then
  exit 0
fi

shopt -s nullglob
files=(.changeset/*.md)
shopt -u nullglob
count=0
for f in "${files[@]}"; do
  [[ "$(basename "$f")" == "README.md" ]] && continue
  count=$((count + 1))
done

if [[ "$count" -eq 0 ]]; then
  echo "changeset-check: no changeset found for consumer-facing changes." >&2
  echo "  Add one: pnpm changeset" >&2
  echo "  See docs/DX_FAQ.mdx (Release desk) and docs/decisions/0009-adopt-changesets-for-repo-releases.mdx" >&2
  exit 1
fi

echo "changeset-check: ok ($count changeset file(s))"

# Fail fast when changeset frontmatter names unknown workspace packages.
workspace_pkg="$(node -p "require('./package.json').name")"
shopt -s nullglob
for cs in .changeset/*.md; do
  [[ "$(basename "$cs")" == "README.md" ]] && continue
  names="$(sed -n '/^---$/,/^---$/p' "$cs" | sed -n '2,$p' | head -n -1 | grep -E '^"[^"]+":' || true)"
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    pkg="${line#\"}"
    pkg="${pkg%%\"*}"
    if [[ "$pkg" != "$workspace_pkg" ]]; then
      fail_pkg="changeset-check: unknown package \"$pkg\" in $(basename "$cs"); expected \"$workspace_pkg\"."
      echo "$fail_pkg" >&2
      exit 1
    fi
  done <<<"$names"
done
shopt -u nullglob

if git rev-parse --verify "$BASE" >/dev/null 2>&1; then
  if ! git show-ref --verify --quiet refs/heads/main; then
    git branch -f main "$BASE" 2>/dev/null || git fetch origin main:main --depth=1
  fi
fi
pnpm exec changeset status
