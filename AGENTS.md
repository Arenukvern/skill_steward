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
npx skills add arenukvern/skill_steward --skill repository-governance-lifecycle
```

[Listed agents](https://github.com/vercel-labs/skills#supported-agents). Project default: `.agents/skills/`; global default: `~/.agents/skills/` via `-g`. Use agent flags when a target needs its own path.

## Non-negotiables

1. **Meta only** — no domain framework skills (React, Flutter, …); see North Star.
2. **`pnpm run validate`** before merging skill changes.
3. **Plan hygiene** — any planning tool is fine; when done, extract into ADR / FAQ / code / harness, then delete stale plan files ([doctrine](docs/start_here/executable-plans.mdx)).
4. **AGENTS.md stays a map** — skill authoring: [docs/STANDARDS.mdx](docs/STANDARDS.mdx); do not bloat this file.
5. **Docs ≠ code** — link to behavior SSOT; do not paraphrase implementations in prose.
6. **Ethical governance** — all design decisions must be auditable against [`charter-and-ethics`](skills/repository-governance-lifecycle/references/charter-and-ethics.md) principles (Anti-Bloat, Reversibility, Legibility, Behavior-as-Truth, Artisan Restraint).

## Guild skills (in-repo)

| Skill | Use when |
|-------|----------|
| `repository-governance-lifecycle` | Architectural decisions (ADRs), FAQs, ethical auditing, charter, AGENTS map |
| `harness-engineering-lifecycle` | Engineering agentic developer harnesses and sandboxes |
| `mcp-harness-repo-maintainer` | CLI/MCP harness configuration, agent-first workflows |
| `release-changelog-harness` | Release and changelog tooling per ecosystem (Changesets, Melos, etc.) |
| `skill-authoring-lifecycle` | Creating, auditing, and maintaining SKILL.md under `skills/` |
| `skill-eval-improve` | Tiered evaluations (`evals/cases/*.yaml`) and CI improve loops |
| `mixture-of-experts` | Parallel agent reasoning, critical evaluation, and self-auditing |
| `multi-agent-handoff` | Spawning and communicating with subagents, handoffs |
| `plugin-marketplace-setup` | Skill and plugin marketplace distribution setup |
| `skill-source-citations` | Sourcing, attribution, and managing knowledge provenance |

## Add or change a skill (checklist)

1. `skills/{name}/SKILL.md` — `name` == directory; see [STANDARDS](docs/STANDARDS.mdx).
2. `pnpm run validate` (Tier 1: also run eval when the eval harness is wired)
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
| Universal / Zed | `.agents/skills/` | `~/.agents/skills/` |
| Cursor | `.agents/skills/` or `.cursor/skills/` | `~/.cursor/skills/` |
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |
| Codex | `.agents/skills/` | `~/.codex/skills/` |

Plugins (hooks) are **not** installed by `npx skills` on Cursor — [plugins/README.md](plugins/README.md).
