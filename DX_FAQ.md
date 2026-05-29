# Agent Guild DX_FAQ — Memory Palace

_How to work in this repo and install Guild skills elsewhere. Walk locations in order or jump by emoji._

## 🧭 Router

```text
CHARTER / scope        → docs/NORTH_STAR.md
WHY / ADRs             → DESIGN_FAQ.md, docs/decisions/
HOW contribute         → this file, AGENTS.md, CONTRIBUTING.md
PLANS (temporary only) → docs/start_here/executable-plans.mdx
DOCS SITE              → docs.json + docs/  (docs.page)
INSTALL for users      → npx skills add arenukvern/agent_guild
VALIDATE before PR     → npm run validate  OR  packages/guild_cli (dart run :guild validate)
GUILD CLI              → packages/guild_cli/README.md  (ADR 0007)
PLUGINS (hooks)        → plugins/README.md  (not via npx skills)
```

## 📦 Install Guild (consumers)

```bash
# All meta-skills
npx skills add arenukvern/agent_guild

# One skill
npx skills add arenukvern/agent_guild --skill adr-records

# Cursor + Claude, project scope, non-interactive
npx skills add arenukvern/agent_guild -a cursor -a claude-code -y

# Global (every project)
npx skills add arenukvern/agent_guild -g

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
npm run validate

# 4. Register
#    - skills.sh.json groupings
#    - README.md skill table
#    - optional DESIGN_FAQ Q&A if repo-level why changed
```

**Authoring skill:** use installed `create-skill` or read [skills/create-skill/SKILL.md](skills/create-skill/SKILL.md).

## ✅ Validate desk

```bash
npm run validate          # all skills under skills/
npm run validate:json     # machine-readable report
npm run list              # skill names + descriptions

# Dart meta CLI (same gates; delegates to npm in v1)
cd packages/guild_cli && dart pub get
dart run :guild validate
dart run :guild list
```

Optional Cursor hook: [plugins/guild-validate-on-save](plugins/guild-validate-on-save/README.md).

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

## 🏗️ Harness workshop

```text
Agent-first culture     → skill harness-engineering-culture
OpenAI principles       → skills/harness-engineering-culture/references/harness-principles.md
CLI+MCP dual surface    → references/cli-mcp-pattern.md (mcp_flutter / agentkit)
Compose Guild skills    → references/guild-composition.md
```

Product example: `flutter-mcp-toolkit doctor`, `make check-contracts` — not shipped from Guild.

## 📚 Doc styles desk

| Need | Skill / doc |
|------|-------------|
| Harness / CLI / MCP culture | `harness-engineering-culture` |
| Package DESIGN + DX FAQ | `faq-driven-docs` |
| Repo lattice (router, SSOT) | `concept-doc-store` |
| ADR format | `adr-records` |
| Spec compliance | `skill-spec-review` |
| Agent handoffs | `multi-agent-handoff` |

Article: [FAQ-driven development](https://dev.to/arenukvern/faq-driven-development-or-new-old-way-to-write-docs-rules-prompts-25jl).

## 🔌 Plugins corner (future)

```text
plugins/{id}/plugin.yaml   → references skill ids in skills/
install hooks separately   → .cursor/hooks.json (not npx skills)
template                   → plugins/_template/
```

## 🤖 Agent ops

```text
Read first:  AGENTS.md, DESIGN_FAQ.md (why), DX_FAQ.md (how)
Rules:       .cursor/rules/faq_usage.mdc
After edit:  npm run validate + update correct FAQ layer
```

Do not duplicate SKILL.md bodies in ADRs or FAQs—link to `skills/{name}/`.
