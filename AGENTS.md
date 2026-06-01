# AGENTS.md — map (not encyclopedia)

Claude Code loads this map via `CLAUDE.md` (symlink to this file).

You are in **Skill Steward**: a meta-layer for the Agent Skills ecosystem. Read the charter before large changes.

## Start here

| I need… | Read |
|---------|------|
| **Charter, scope, boundaries** | [docs/NORTH_STAR.mdx](docs/NORTH_STAR.mdx) |
| **Why** (standing decisions) | [docs/DESIGN_FAQ.mdx](docs/DESIGN_FAQ.mdx) · [docs/decisions/](docs/decisions/) |
| **How** (install, validate, contribute, release) | [docs/DX_FAQ.mdx](docs/DX_FAQ.mdx) |
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
4. **AGENTS.md stays a map** — skill authoring: [docs/STANDARDS.mdx](docs/STANDARDS.mdx); do not bloat this file.
5. **Docs ≠ code** — link to behavior SSOT; do not paraphrase implementations in prose.
6. **Ethical governance** — all design decisions must be auditable against [`ethical-stewardship`](skills/ethical-stewardship/SKILL.md) principles (Anti-Bloat, Reversibility, Legibility, Behavior-as-Truth, Artisan Restraint).

## Guild skills (in-repo)

| Skill | Use when |
|-------|----------|
| `north-star-governance` | Charter, AGENTS map, plan lifecycle, docs.json |
| `ethical-stewardship` | Bootstrapping ethics, auditing decisions against moral/design boundaries, defining repo credo |
| `harness-engineering-culture` | CLI/MCP harness, agent-first culture |
| `release-changelog-harness` | Release/changelog tooling per ecosystem (Changesets, Melos, …) |
| `create-skill` | New skill under `skills/` |
| `skill-eval-improve` | Tiered evals, `evals/cases/*.yaml`, improve loops ([ADR 0011](docs/decisions/0011-tiered-skill-evals-and-rule-based-ci.mdx)) |
| `skill-spec-review` | Audit SKILL.md before merge |
| `faq-driven-docs` | DESIGN_FAQ + DX_FAQ |
| `adr-records` | New ADR in `docs/decisions/` |
| `concept-doc-store` | Doc lattice for larger repos |
| `multi-agent-handoff` | HANDOFF between agents |

## Add or change a skill (checklist)

1. `skills/{name}/SKILL.md` — `name` == directory; see [STANDARDS](docs/STANDARDS.mdx).
2. `pnpm run validate` (Tier 1: also `pnpm run eval`)
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
