# Skill Steward DX_FAQ — Memory Palace

_How to work in this repo and install Skill Steward meta-skills elsewhere. Walk locations in order or jump by emoji._

## 🧭 Router

```text
CHARTER / scope        → docs/NORTH_STAR.md
WHY / ADRs             → DESIGN_FAQ.md, docs/decisions/
HOW contribute         → this file, AGENTS.md, CONTRIBUTING.md
PLAN HYGIENE (any format) → docs/start_here/executable-plans.mdx
DOCS SITE              → https://docs.page/arenukvern/skill_steward · docs.json + docs/
DOCS CI                → pnpm run docs:check  (@docs.page/cli)
INSTALL for users      → npx skills add arenukvern/skill_steward
ANALYZE steward_cli    → pnpm run steward:analyze  (xsoulspace_lints; CI on PR)
VALIDATE before PR     → pnpm run steward:validate  (CI uses dart run :steward validate)
CITE / EVAL SKILLS     → skill-source-citations, skill-eval-improve
STEWARD CLI              → packages/steward_cli/README.md  (ADR 0007)
RELEASE / CHANGELOG    → this file (Release desk) · ADR 0009 · ADR 0010 · skill release-changelog-harness
PLUGINS (hooks)        → plugins/README.md  (not via npx skills)
```

## 📦 Repo setup (maintainers)

```bash
pnpm install          # packageManager: pnpm@9 (see package.json)
pnpm run steward:analyze
pnpm run steward:validate
```

## 📦 Install Skill Steward (consumers)

```bash
# All meta-skills
npx skills add arenukvern/skill_steward

# One skill
npx skills add arenukvern/skill_steward --skill adr-records

# Cursor + Claude, project scope, non-interactive
npx skills add arenukvern/skill_steward -a cursor -a claude-code -y

# Global (every project)
npx skills add arenukvern/skill_steward -g

# List without installing (from repo path)
npx skills add . --list
```

**Note:** Hooks/plugins are **not** installed by `npx skills` on Cursor—see `plugins/README.md` and [ADR 0004](docs/decisions/0004-plugin-packaging-and-install-path.md).

## 🏗️ Add a skill (maintainers)

```bash
# 1. Copy template
cp -r templates/skill skills/my-skill-name

# 2. Edit skills/my-skill-name/SKILL.md (name == directory name)

# 3. Validate
pnpm run validate

# 4. Register
#    - skills.sh.json groupings
#    - README.md skill table
#    - optional DESIGN_FAQ Q&A if repo-level why changed
```

**Authoring skill:** use installed `create-skill` or read [skills/create-skill/SKILL.md](skills/create-skill/SKILL.md).

## ✅ Validate desk

```bash
pnpm run validate          # all skills under skills/
pnpm run validate:json     # machine-readable report
pnpm run list              # skill names + descriptions

# Dart meta CLI (same gates; delegates to pnpm/npm run in v1)
cd packages/steward_cli && dart pub get
dart analyze --fatal-infos
dart run :steward validate
dart run :steward list
```

Optional Cursor hook: [plugins/steward-validate-on-save](plugins/steward-validate-on-save/README.md).

Fix all `error:` lines before merge. Warnings (long SKILL.md, missing skills.sh entry) should be addressed or justified in PR.

## 📋 Registry shelf

| File | Update when |
|------|-------------|
| `skills.sh.json` | New skill or category change |
| `README.md` skill table | New/removed skill |
| `DESIGN_FAQ.md` | Repo-level **why** changes |
| `DX_FAQ.md` | Contributor **how** changes |
| `docs/decisions/` | Architecturally significant decision |

## 📜 ADR desk

```bash
# Next ADR number
bash skills/adr-records/scripts/next-adr-number.sh docs/decisions

# Authoring
# Use skill adr-records or references in skills/adr-records/
```

Index: [docs/decisions/README.md](docs/decisions/README.md).

## 🧭 North Star desk

```text
Edit charter           → docs/NORTH_STAR.md
Wire agent map         → AGENTS.md (~100 lines max)
docs.page sidebar      → docs.json + docs_map.mdx
Close a plan           → merge to ADR/FAQ/code/skill → delete docs/exec-plans/active/*
Skill                  → north-star-governance
```

## 🚀 Release desk (Changesets)

Skill Steward uses [Changesets](https://github.com/changesets/changesets) for **repo** semver + `CHANGELOG.md` (skills are not individually versioned). **No binary release train** — consumers use `npx skills`; product siblings use GitHub Release tarballs + `install.sh` ([ADR 0010](docs/decisions/0010-binary-releases-for-product-harness-not-meta-steward.md)). Skill: `release-changelog-harness` · ADRs: [0009](docs/decisions/0009-adopt-changesets-for-repo-releases.md), [0010](docs/decisions/0010-binary-releases-for-product-harness-not-meta-steward.md).

```bash
# PR: describe consumer impact (required when skills/docs/plugins/registry change)
pnpm changeset
# Pick patch | minor | major for "skill-steward", write one imperative sentence

# Maintainer: consume changesets on main before tag
pnpm changeset:status
pnpm changeset:version    # updates CHANGELOG.md + package.json
git add -A && git commit -m "chore: version packages"

# Tag release (example)
git tag "v$(node -p "require('./package.json').version")"
git push origin main --tags
```

```text
CI on PR               → .github/workflows/changesets.yml
Local gate             → bash scripts/changeset-check.sh origin/main
Skip (maintainer only) → PR title contains [skip changeset]
```

**When to add a changeset:** `skills/`, `plugins/`, `docs/`, `skills.sh.json`, `README.md`, `AGENTS.md`, `docs.json`, `CONTRIBUTING.md`, `scripts/`, `.github/workflows/`.

**When to skip:** typos, comments-only, or internal refactors with zero consumer impact (use `[skip changeset]` in PR title).

## 🏗️ Harness workshop

```text
Agent-first culture     → skill harness-engineering-culture
OpenAI principles       → skills/harness-engineering-culture/references/harness-principles.md
CLI+MCP dual surface    → references/cli-mcp-pattern.md (mcp_flutter / IntentCall)
Compose Skill Steward skills    → skills/harness-engineering-culture/references/steward-composition.md
```

Product example: `flutter-mcp-toolkit doctor`, `make check-contracts` — not shipped from Skill Steward.

## 📚 Doc styles desk

| Need | Skill / doc |
|------|-------------|
| Harness / CLI / MCP culture | `harness-engineering-culture` |
| Release / changelog tooling | `release-changelog-harness` |
| Package DESIGN + DX FAQ | `faq-driven-docs` |
| Repo lattice (router, SSOT) | `concept-doc-store` |
| ADR format | `adr-records` |
| Spec compliance | `skill-spec-review` |
| Agent handoffs | `multi-agent-handoff` |

Article: [FAQ-driven development](https://dev.to/arenukvern/faq-driven-development-or-new-old-way-to-write-docs-rules-prompts-25jl).

## 🔌 Plugins corner (future)

```text
plugins/{id}/plugin.yaml   → references skill ids in skills/
CURSOR HOOKS           → .cursor/hooks.json (steward-validate-on-save; committed)
install hooks elsewhere  → plugins/steward-validate-on-save/README.md
template                   → plugins/_template/
```

## 🤖 Agent ops

```text
Read first:  AGENTS.md, DESIGN_FAQ.md (why), DX_FAQ.md (how)
Rules:       .cursor/rules/faq_usage.mdc
After edit:  pnpm run validate + update correct FAQ layer
```

Do not duplicate SKILL.md bodies in ADRs or FAQs—link to `skills/{name}/`.
