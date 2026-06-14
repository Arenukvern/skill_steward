# AGENTS.md — map (not encyclopedia)

Claude Code loads this map via `CLAUDE.md` (symlink to this file).

You are in **Skill Steward**: an Engineering Stewardship layer for agent-operated engineering repositories. Read the charter before large changes.

## Start here

| I need… | Read |
|---------|------|
| **Charter, scope, boundaries** | [docs/NORTH_STAR.mdx](docs/NORTH_STAR.mdx) |
| **Repo quality + evidence claims** | [docs/repo-quality-contracts.mdx](docs/repo-quality-contracts.mdx) · [docs/core/evidence-ladder.mdx](docs/core/evidence-ladder.mdx) |
| **Why** (standing decisions) | [docs/DESIGN_FAQ.mdx](docs/DESIGN_FAQ.mdx) · [docs/decisions/](docs/decisions/) |
| **How** (install, validate, contribute, release) | [docs/DX_FAQ.mdx](docs/DX_FAQ.mdx) |
| **Concepts** (stewardship loop, evidence, docs lattice) | [docs/core/](docs/core/) |
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

1. **Original goal and native validation first** — Steward governance exists to shorten future repair loops, not to delay the current fix.
2. **Structural stewardship only** — no domain framework tutorial packs (React, Flutter, …); see North Star.
3. **`pnpm run validate`** before merging skill changes.
4. **Claims need matching evidence** — H2 smoke proof is not H4 fresh-agent proof; static evals are not runtime behavior. Use [docs/core/evidence-ladder.mdx](docs/core/evidence-ladder.mdx) before claiming readiness.
5. **Plan hygiene** — any planning tool is fine; when done, extract into ADR / FAQ / code / harness, then delete stale plan files ([doctrine](docs/start_here/executable-plans.mdx)).
6. **AGENTS.md stays a map** — skill authoring: [docs/STANDARDS.mdx](docs/STANDARDS.mdx); do not bloat this file.
7. **Docs ≠ code** — link to behavior SSOT; do not paraphrase implementations in prose.
8. **Ethical governance** — all design decisions must be auditable against [`charter-and-ethics`](skills/repository-governance-lifecycle/references/charter-and-ethics.md) principles (Anti-Bloat, Reversibility, Legibility, Behavior-as-Truth, Artisan Restraint).

## Guild skills (in-repo)

| Skill | Use when |
|-------|----------|
| `repository-governance-lifecycle` | Architectural decisions (ADRs), FAQs, ethical auditing, charter, AGENTS map |
| `steward-continuity-boundary-lifecycle` | Stewardship protocol mode boundaries, self-model decisions, delegation hygiene, and handoff-safe continuity |
| `repo-quality-system-lifecycle` | General stewardship baseline for apps, libraries, tools, plugins, harnesses, and meta repos |
| `mcp-harness-repo-maintainer` | Local action-contract/harness adoption: `steward.yaml`, typed actions, quick probes, benchmark smoke loops |
| `harness-engineering-lifecycle` | Cross-repo harness generalization after a local contract exists |
| `release-changelog-harness` | Release and changelog tooling per ecosystem (Changesets, Melos, etc.) |
| `skill-authoring-lifecycle` | Creating, auditing, and maintaining SKILL.md under `skills/` |
| `skill-eval-improve` | T-named skill quality gates (`evals/cases/*.yaml`) and CI improve loops |
| `mixture-of-experts` | Parallel agent reasoning, critical evaluation, and self-auditing |
| `multi-agent-handoff` | Spawning and communicating with subagents, handoffs |
| `plugin-marketplace-setup` | Skill and plugin marketplace distribution setup |
| `skill-source-citations` | Sourcing, attribution, and managing knowledge provenance |
| `vision-alignment-foresight` | Vision vs implementation, intent, evidence, and future-fit analysis |

## Add or change a skill (checklist)

1. `skills/{name}/SKILL.md` — `name` == directory; see [STANDARDS](docs/STANDARDS.mdx).
2. `pnpm run validate` (T1 behavior-critical skill changes also require `pnpm run eval`)
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

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **skill_steward** (2921 symbols, 5339 relationships, 235 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/skill_steward/context` | Codebase overview, check index freshness |
| `gitnexus://repo/skill_steward/clusters` | All functional areas |
| `gitnexus://repo/skill_steward/processes` | All execution flows |
| `gitnexus://repo/skill_steward/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
