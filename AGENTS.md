# AGENTS.md — map (not encyclopedia)

`CLAUDE.md` → symlink to this file (Claude Code).

You are in **Skill Steward**: a meta-layer for the Agent Skills ecosystem. Read the charter before large changes.

## Start here

| I need… | Read |
|---------|------|
| **Charter, scope, boundaries** | [docs/NORTH_STAR.md](docs/NORTH_STAR.md) |
| **Why** (standing decisions) | [DESIGN_FAQ.md](DESIGN_FAQ.md) · [docs/decisions/](docs/decisions/) |
| **How** (install, validate, contribute, release) | [DX_FAQ.md](DX_FAQ.md) |
| **Full doc index** | [docs/start_here/docs_map.mdx](docs/start_here/docs_map.mdx) |
| **Plan hygiene** | [docs/start_here/executable-plans.mdx](docs/start_here/executable-plans.mdx) — any format; extract & remove when done |
| **Which FAQ to edit** | [.cursor/rules/faq_usage.mdc](.cursor/rules/faq_usage.mdc) |

## Install Skill Steward (consumers)

```bash
npx skills add arenukvern/skill_steward
npx skills add arenukvern/skill_steward --skill north-star-governance
```

[Listed agents](https://github.com/vercel-labs/skills#supported-agents). Project: `.agents/skills/` → `.cursor/skills/`. Global: `-g`.

## Non-negotiables

1. **Meta only** — no domain framework skills (React, Flutter, …); see North Star.
2. **`pnpm run validate`** before merging skill changes.
3. **Plan hygiene** — any planning tool is fine; when done, extract into ADR / FAQ / code / harness, then delete stale plan files ([doctrine](docs/start_here/executable-plans.mdx)).
4. **AGENTS.md stays a map** — skill authoring: [docs/STANDARDS.md](docs/STANDARDS.md); do not bloat this file.
5. **Docs ≠ code** — link to behavior SSOT; do not paraphrase implementations in prose.

## Guild skills (in-repo)

| Skill | Use when |
|-------|----------|
| `north-star-governance` | Charter, AGENTS map, plan lifecycle, docs.json |
| `harness-engineering-culture` | CLI/MCP harness, agent-first culture |
| `release-changelog-harness` | Release/changelog tooling per ecosystem (Changesets, Melos, …) |
| `create-skill` | New skill under `skills/` |
| `skill-spec-review` | Audit SKILL.md before merge |
| `faq-driven-docs` | DESIGN_FAQ + DX_FAQ |
| `adr-records` | New ADR in `docs/decisions/` |
| `concept-doc-store` | Doc lattice for larger repos |
| `multi-agent-handoff` | HANDOFF between agents |

## Add or change a skill (checklist)

1. `skills/{name}/SKILL.md` — `name` == directory; see [STANDARDS](docs/STANDARDS.md).
2. `pnpm run validate`
3. `skills.sh.json` + [README](README.md) table
4. No secrets; no domain tutorials

## Validation

```bash
pnpm run validate
```

CI: `.github/workflows/validate-skills.yml`

## Agent paths (reference)

| Agent | Project | Global |
|-------|---------|--------|
| Cursor | `.cursor/skills/` | `~/.cursor/skills/` |
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |
| Codex | `.codex/skills/` | `~/.codex/skills/` |
| Universal | `.agents/skills/` | `~/.agents/skills/` |

Plugins (hooks) are **not** installed by `npx skills` on Cursor — [plugins/README.md](plugins/README.md).
