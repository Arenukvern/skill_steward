---
name: harness-engineering-culture
description: Develops agent-first engineering culture via harness design—CLI and MCP with shared contracts, mechanical gates, and in-repo docs. Use when building agentic tooling, harness loops, Codex/Cursor workflows, or applying OpenAI harness engineering with Skill Steward meta-skills.
license: MIT
metadata:
  author: skill-steward
  version: "1.2.0"
  category: harness
paths:
  - "AGENTS.md"
  - "docs/**"
  - "scripts/**"
  - "Makefile"
  - "**/mcp*.json"
  - ".github/workflows/**"
---

# Harness engineering culture

Build environments where **agents execute** and **humans steer**—through legible tooling (CLI, MCP, hooks, skills) and docs that agents can navigate without a monolithic manual.

Primary reference: [Harness engineering (OpenAI)](https://openai.com/index/harness-engineering/).  
Local patterns: CLI vs MCP separation (dual interfaces), schema and adapter registries.

## Core beliefs

1. **Missing capability → harness gap** — When an agent fails, ask what is not *legible* or *enforceable*, then add CLI command, MCP tool, linter, or skill—not “try harder.”
2. **Ambiguous design → decision checkpoint** — Before coding a fork (CLI vs MCP split, new tool surface, schema shape), use `adr-records` layer 0 ([decision checkpoints](../adr-records/references/decision-checkpoints.md)); record `accepted` ADR after agreement—not drive-by architecture.
3. **CLI + MCP = thin interfaces; core = logic** — MCP and CLI are agent-facing APIs only. Domain logic, schemas, and registries live in **core** packages; both surfaces call the same entrypoints. CLI for CI/`doctor`/contracts; MCP for chat. Divergence is a bug ([core pattern](https://github.com/arenukvern/skill_steward/blob/main/skills/mcp-harness-repo-maintainer/references/core-and-interfaces.md)).
4. **Docs are the system of record** — Versioned markdown in git; Slack/docs outside repo are invisible to agents. `AGENTS.md` is a **map** (~100 lines), not an encyclopedia.
5. **Mechanical enforcement** — Linters, `make check-*`, `pnpm run validate`, schema validation at boundaries—error messages teach the agent how to fix.
6. **Progressive disclosure** — Router → ADR / DESIGN_FAQ (why) → DX_FAQ (how) → skills (procedures) → code (behavior SSOT).

## Skill Steward skill stack (use together)

| Phase | Skill | Action |
|-------|--------|--------|
| Charter / why | `concept-doc-store`, `adr-records` | ADR for harness boundaries; NORTH_STAR / router |
| Design fork (during work) | `adr-records` | Checkpoint brief before coding ([decision-checkpoints](../adr-records/references/decision-checkpoints.md)) |
| Releases | `release-changelog-harness` | Ecosystem Changesets / Melos / release-plz; DX_FAQ + CI gates |
| Package knowledge | `faq-driven-docs` | DESIGN_FAQ + DX_FAQ per module |
| Brand Identity | `repo-brand-identity` | Visual guidelines, custom SVG status badges, tone constraints |
| Ethics & Stewardship | `ethical-stewardship` | Eliciting values, defining constraints, building environment gates |
| Ship a procedure | `create-skill`, `skill-spec-review` | Agent-invokable workflow in `SKILL.md` |
| Multi-agent work | `multi-agent-handoff` | HANDOFF.md between implementer / closer |
| Wiring | ADR 0004 + `plugins/` | Hooks when skills CLI is not enough (Cursor) |
| Repo maintenance | `mcp-harness-repo-maintainer` | Product MCP / platform SDK / CLI harness / meta-steward archetypes |

Do not duplicate other skills’ content here—**invoke** them by name when in scope.

## Harness layers to build

```text
Human intent (prompt, plan, review)
        │
        ▼
┌───────────────────┐
│ Skills + AGENTS   │  Map & procedures (when to do what)
└─────────┬─────────┘
          ▼
┌───────────────────┐
│ CLI               │  doctor, exec, validate, contracts (deterministic)
└─────────┬─────────┘
          ▼
┌───────────────────┐
│ MCP server        │  fmt_* / tools for chat agents (same schemas)
└─────────┬─────────┘
          ▼
┌───────────────────┐
│ App / runtime     │  Legible UI, logs, metrics per worktree (optional)
└───────────────────┘
```

## Workflow: add agent-first capability

1. **Specify intent** — One sentence outcome + acceptance check (command output, test, or MCP call).
2. **Choose surface**
   - CI / script / gate → **CLI** first
   - Conversational debug loop → **MCP tool** (reuse CLI core)
   - One-off guidance → **skill** in `skills/`
   - Event enforcement (save, tool use) → **plugin** hook ([ADR 0004](../../docs/decisions/0004-plugin-packaging-and-install-path.mdx))
3. **Make legible** — JSON schema, `--json` output, stable error codes; document in DX_FAQ Memory Palace location.
4. **Document why** — ADR or DESIGN_FAQ Q&A (2–3 sentences); link **Authoritative source:** to code.
5. **Wire map** — `AGENTS.md` / `docs_map` row; never paste full schemas into AGENTS.
6. **Validate** — `pnpm run validate` (Skill Steward skills); project `make check-*` / contract tests (product repos).
7. **Human collab** — PR describes harness change; agent self-review loop optional; human reviews harness shape, not every line.

## Docs discipline (harness-aligned)

| Artifact | Max role |
|----------|----------|
| `AGENTS.md` | Table of contents + non-negotiables |
| `docs/DESIGN_FAQ.mdx` | Why harness choices |
| `docs/DX_FAQ.mdx` | CLI/MCP commands, install, validate |
| `docs/decisions/` | ADRs for significant harness splits |
| `skills/*/SKILL.md` | Repeatable agent procedures |
| Code / examples | Behavior—link, do not copy |

Article pattern: [FAQ-driven development](https://dev.to/arenukvern/faq-driven-development-or-new-old-way-to-write-docs-rules-prompts-25jl).

## Anti-patterns

- 1,000-line `AGENTS.md` (crowds out task context)
- CLI and MCP with different validation rules
- Docs that paraphrase code instead of linking
- Domain tutorials in Skill Steward (wrong repo—meta harness only)
- Relying on vector search instead of structured docs + `skills find`
- Implementing architectural forks without `adr-records` checkpoint or accepted ADR

## Checklist before claiming “harness ready”

- [ ] Agent can discover what to run from in-repo docs alone
- [ ] CLI command exists for CI/gates (or documented why not)
- [ ] MCP tool shares schema/validation with CLI (if MCP applies)
- [ ] Failure messages say how to remediate
- [ ] Design forks were checkpointed (`adr-records`); ADR or DESIGN_FAQ explains why split exists
- [ ] Skill Steward `pnpm run validate` passes if skills changed

## Install

```bash
npx skills add arenukvern/skill_steward --skill harness-engineering-culture
```

## References

- [harness-principles.md](references/harness-principles.md) — OpenAI article distilled
- [cli-mcp-pattern.md](references/cli-mcp-pattern.md) — Dual surface, shared core
- [steward-composition.md](references/steward-composition.md) — Which Skill Steward skill when
- [preferred-tooling.md](references/preferred-tooling.md) — Language and task runner choices for harness CLIs (Dart + Justfile default, guidance for other ~/mcp repos)

## Sources

See [references/sources.md](references/sources.md). When researching, follow `skill-source-citations`.
