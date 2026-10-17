#!/usr/bin/env bash
# Isolated hook regression: fake validators; no SDK, network, or host required.
set -euo pipefail
HOOK=${1:-"$(cd "$(dirname "$0")/../hooks" && pwd)/validate-on-skill-edit.sh"}
FIXTURE=$(mktemp -d)
trap 'rm -rf "$FIXTURE"' EXIT
mkdir -p "$FIXTURE/bin" "$FIXTURE/repo/packages/steward_cli" "$FIXTURE/repo/skills/demo/references"
touch "$FIXTURE/repo/packages/steward_cli/pubspec.yaml" "$FIXTURE/repo/package.json" "$FIXTURE/repo/skills/demo/references/sources.md"
cat > "$FIXTURE/bin/dart" <<'STUB'
#!/usr/bin/env bash
echo dart >> "$HOOK_CALLS"
echo 'validation diagnostic' >&2
exit 7
STUB
cat > "$FIXTURE/bin/pnpm" <<'STUB'
#!/usr/bin/env bash
echo pnpm >> "$HOOK_CALLS"
exit 0
STUB
chmod +x "$FIXTURE/bin/"*
export PATH="$FIXTURE/bin:$PATH"
export HOOK_CALLS="$FIXTURE/calls"
cd "$FIXTURE/repo"
git init -q
for EDIT_PATH in "$FIXTURE/repo/skills/demo/SKILL.md" skills/demo/SKILL.md; do
  : > "$HOOK_CALLS"
  STATUS=0
  printf '{"file_path":"%s"}' "$EDIT_PATH" | bash "$HOOK" > "$FIXTURE/out" 2> "$FIXTURE/err" || STATUS=$?
  [[ "$STATUS" == 7 ]] || { echo "Expected validator failure 7 for $EDIT_PATH, got $STATUS" >&2; exit 1; }
  [[ "$(cat "$HOOK_CALLS")" == dart ]] || { echo 'Validator ran more than once' >&2; exit 1; }
  grep -q 'validation diagnostic' "$FIXTURE/err"
done
: > "$HOOK_CALLS"
printf '{"file_path":"README.md"}' | bash "$HOOK"
[[ ! -s "$HOOK_CALLS" ]]
echo 'Hook regression checks passed'
