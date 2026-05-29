#!/usr/bin/env bash
# Cursor afterFileEdit — validate Skill Steward skills when SKILL.md changes.
set -euo pipefail

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | node -e "
let s=''; process.stdin.on('data',d=>s+=d); process.stdin.on('end',()=>{
  try {
    const j=JSON.parse(s);
    const p=j.file_path||j.path||j.filePath||'';
    process.stdout.write(p);
  } catch { process.stdout.write(''); }
});
" 2>/dev/null || true)

SKILL_DIR=$(printf '%s' "$FILE" | sed -n 's|.*/skills/\([^/]*\)/SKILL\.md$|\1|p')
if [[ -z "$FILE" ]] || [[ -z "$SKILL_DIR" ]]; then
  exit 0
fi
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

SOURCES="skills/${SKILL_DIR}/references/sources.md"
if [[ ! -f "$SOURCES" ]]; then
  echo "guild-validate-on-save: warn — missing ${SOURCES} (see skill-source-citations)" >&2
fi

if command -v dart >/dev/null 2>&1 && [[ -f packages/guild_cli/pubspec.yaml ]]; then
  (cd packages/guild_cli && dart run :guild validate) 2>/dev/null && exit 0
fi

if command -v pnpm >/dev/null 2>&1 && [[ -f package.json ]]; then
  pnpm run validate --silent
  exit $?
fi

if command -v npm >/dev/null 2>&1 && [[ -f package.json ]]; then
  npm run validate --silent
  exit $?
fi

echo "guild-validate-on-save: need dart, pnpm, or npm to validate" >&2
exit 1
