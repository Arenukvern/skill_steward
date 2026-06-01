# Skill Steward DX_FAQ — Memory Palace

_How to work in this repo and install Skill Steward meta-skills elsewhere. Walk locations in order or jump by emoji._

## 🧭 Router

```text
CHARTER / scope        → docs/NORTH_STAR.mdx
WHY / ADRs             → DESIGN_FAQ.md, docs/decisions/
HOW contribute         → this file, AGENTS.md, CONTRIBUTING.md
PLAN HYGIENE (any format) → docs/start_here/executable-plans.mdx
DOCS SITE              → https://docs.page/arenukvern/skill_steward · docs.json + docs/
DOCS CI                → pnpm run docs:check  (@docs.page/cli)
INSTALL for users      → npx skills add arenukvern/skill_steward
UPDATE installed       → this file (Updating installed skills)
ANALYZE steward_cli    → pnpm run steward:analyze  (xsoulspace_lints; CI on PR)
VALIDATE before PR     → pnpm run steward:validate  (validate + eval; same as CI)
CITE / EVAL SKILLS     → skill-source-citations, skill-eval-improve
EVAL CI (Tier 1)       → pnpm run eval · evals/cases/*.yaml · ADR 0011
STEWARD CLI              → packages/steward_cli/README.md  (ADR 0007)
RELEASE / CHANGELOG    → this file (Release desk) · ADR 0009 · ADR 0010 · skill release-changelog-harness
PLUGINS (hooks)        → plugins/README.md  (not via npx skills)
```

## 📦 Repo setup (maintainers)

GitHub product name: **Skill Steward** (`Arenukvern/skill_steward`). Many workspaces clone it as **`agent_guild/`** beside harness repos (e.g. in `~/mcp/` or any sibling directory).

```bash
# Clone wherever you keep your workspace (e.g. ~/mcp/, ~/dev/, etc.)
cd <workspace>/agent_guild
pnpm install          # packageManager: pnpm@9 (see package.json)
pnpm run steward:analyze
pnpm run steward:validate
```

### Consumer install from a local clone (sibling repo)

```bash
# Project scope (example: <cli_harness>)
cd <workspace>/<cli_harness>
make agent-skills
# or install from the cloned local copy:
npx skills add <workspace>/agent_guild --skill mcp-harness-repo-maintainer -a cursor -y
```

### Harness bundle (recommended for product repos)

| Skill | Role |
|-------|------|
| `north-star-governance` | Charter, AGENTS map, plan hygiene |
| `harness-engineering-culture` | CLI/MCP harness culture |
| `mcp-harness-repo-maintainer` | Archetype checklists, sibling layout |
| `adr-records` | ADRs in `decisions/` |
| `faq-driven-docs` | DESIGN_FAQ + DX_FAQ |
| `create-skill` / `skill-spec-review` | Author and audit `plugin/skills/` |

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

**Note:** Hooks/plugins are **not** installed by `npx skills` on Cursor—see `plugins/README.md` and [ADR 0004](docs/decisions/0004-plugin-packaging-and-install-path.mdx).

## 🔄 Updating installed skills

After Skill Steward merges to `main`, consumers refresh installed `SKILL.md` files with [vercel-labs/skills](https://github.com/vercel-labs/skills) (`npx skills`). Installed paths depend on agent (e.g. `.cursor/skills/`, `.agents/skills/`); see [AGENTS.md](AGENTS.md).

```bash
# List what is installed (project)
npx skills list

# List global installs
npx skills list -g

# Update all installed skills (project; non-interactive)
npx skills update -y

# Update global installs only
npx skills update -g -y

# Update project installs only
npx skills update -p -y

# Update one skill by directory name (from `skills list`)
npx skills update north-star-governance -y
npx skills update create-skill -y
```

**Re-add from GitHub** (same as install; overwrites/refreshes from `arenukvern/skill_steward`):

```bash
# All meta-skills
npx skills add arenukvern/skill_steward -y

# One skill
npx skills add arenukvern/skill_steward --skill adr-records -y

# Target agents, project scope
npx skills add arenukvern/skill_steward -a cursor -a claude-code -y

# Global reinstall
npx skills add arenukvern/skill_steward -g -y
```

**When to use which**

| Goal | Command |
|------|---------|
| Routine sync after upstream changes | `npx skills update -y` |
| Only global skills | `npx skills update -g -y` |
| One skill you use heavily | `npx skills update <skill-name> -y` |
| Force full marketplace refresh | `npx skills add arenukvern/skill_steward -y` |
| Pin to a branch or local clone | `npx skills add <path-or-url> --skill <name> -y` |

**Not covered by `npx skills`:** Cursor hook plugins — [plugins/README.md](plugins/README.md).

## 🏗️ Add a skill (maintainers)

```bash
# 1. Copy template
cp -r templates/skill skills/my-skill-name

# 2. Edit skills/my-skill-name/SKILL.md (name == directory name)

# 3. Validate
dart run :steward validate   # or pnpm run validate (now delegates to Dart)

# 4. Register
#    - skills.sh.json groupings
#    - README.md skill table
#    - optional DESIGN_FAQ Q&A if repo-level why changed
```

**Authoring skill:** use installed `create-skill` or read [skills/create-skill/SKILL.md](skills/create-skill/SKILL.md).

## ✅ Validate desk

```bash
dart run :steward validate          # canonical (pure Dart implementation)
dart run :steward validate --json   # machine-readable report
pnpm run eval                       # Tier 1 rule-based cases (ADR 0011) — still Node for now
pnpm run list                       # skill names + descriptions

# Dart meta CLI (primary)
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

Index: [docs/decisions/README.mdx](docs/decisions/README.mdx).

## 🧭 North Star desk

```text
Edit charter           → docs/NORTH_STAR.mdx
Wire agent map         → AGENTS.md (~100 lines max)
docs.page sidebar      → docs.json + docs_map.mdx
Close a plan           → merge to ADR/FAQ/code/skill → delete docs/exec-plans/active/*
Skill                  → north-star-governance
```

## 🚀 Release desk (Changesets)

Skill Steward uses [Changesets](https://github.com/changesets/changesets) for **repo** semver + `CHANGELOG.md` (skills are not individually versioned). **No binary release train** — consumers use `npx skills`; product siblings use GitHub Release tarballs + `install.sh` ([ADR 0010](docs/decisions/0010-binary-releases-for-product-harness-not-meta-steward.mdx)). Skill: `release-changelog-harness` · ADRs: [0009](docs/decisions/0009-adopt-changesets-for-repo-releases.mdx), [0010](docs/decisions/0010-binary-releases-for-product-harness-not-meta-steward.mdx).

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
CLI+MCP dual surface    → references/cli-mcp-pattern.md (product MCP / platform libs)
Compose Skill Steward skills    → skills/harness-engineering-culture/references/steward-composition.md
```

Product example: `<cli_harness> doctor`, `make check-contracts` — not shipped from Skill Steward.

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
template                   → templates/plugin/
```

## 🤖 Agent ops

```text
Read first:  AGENTS.md, DESIGN_FAQ.md (why), DX_FAQ.md (how)
Rules:       .cursor/rules/faq_usage.mdc
After edit:  dart run :steward validate + update correct FAQ layer
```

Do not duplicate SKILL.md bodies in ADRs or FAQs—link to `skills/{name}/`.
