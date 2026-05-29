---
name: harness-engineering-culture
description: Develops agent-first engineering culture via harness design—CLI and MCP with shared contracts, mechanical gates, and in-repo docs. Use when building agentic tooling, harness loops, Codex/Cursor workflows, or applying OpenAI harness engineering with Guild meta-skills.
license: MIT
metadata:
  author: agent-guild
  version: "1.0.0"
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
Local patterns: [mcp_flutter CLI vs MCP](https://github.com/Arenukvern/mcp_flutter/blob/main/docs/start_here/cli_vs_mcp.mdx), [agentkit](https://github.com/Arenukvern/agentkit) (schema, registry, adapters).

## Core beliefs

1. **Missing capability → harness gap** — When an agent fails, ask what is not *legible* or *enforceable*, then add CLI command, MCP tool, linter, or skill—not “try harder.”
2. **CLI + MCP, one catalog** — Same semantics: CLI for CI, scripts, `doctor`, contracts; MCP for chat loops. Divergence is a bug ([mcp_flutter tier-A parity](https://github.com/Arenukvern/mcp_flutter/blob/main/flutter_test_app/AGENTKIT_PLATFORM.md)).
3. **Docs are the system of record** — Versioned markdown in git; Slack/docs outside repo are invisible to agents. `AGENTS.md` is a **map** (~100 lines), not an encyclopedia.
4. **Mechanical enforcement** — Linters, `make check-*`, `npm run validate`, schema validation at boundaries—error messages teach the agent how to fix.
5. **Progressive disclosure** — Router → ADR / DESIGN_FAQ (why) → DX_FAQ (how) → skills (procedures) → code (behavior SSOT).

## Guild skill stack (use together)

| Phase | Skill | Action |
|-------|--------|--------|
| Charter / why | `concept-doc-store`, `adr-records` | ADR for harness boundaries; NORTH_STAR / router |
| Package knowledge | `faq-driven-docs` | DESIGN_FAQ + DX_FAQ per module |
| Ship a procedure | `create-skill`, `skill-spec-review` | Agent-invokable workflow in `SKILL.md` |
| Multi-agent work | `multi-agent-handoff` | HANDOFF.md between implementer / closer |
| Wiring | ADR 0004 + future `plugins/` | Hooks when skills CLI is not enough (Cursor) |

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
   - Event enforcement (save, tool use) → **plugin** hook ([ADR 0004](../../docs/decisions/0004-plugin-packaging-and-install-path.md))
3. **Make legible** — JSON schema, `--json` output, stable error codes; document in DX_FAQ Memory Palace location.
4. **Document why** — ADR or DESIGN_FAQ Q&A (2–3 sentences); link **Authoritative source:** to code.
5. **Wire map** — `AGENTS.md` / `docs_map` row; never paste full schemas into AGENTS.
6. **Validate** — `npm run validate` (Guild skills); project `make check-*` / contract tests (product repos).
7. **Human collab** — PR describes harness change; agent self-review loop optional; human reviews harness shape, not every line.

## Docs discipline (harness-aligned)

| Artifact | Max role |
|----------|----------|
| `AGENTS.md` | Table of contents + non-negotiables |
| `DESIGN_FAQ.md` | Why harness choices |
| `DX_FAQ.md` | CLI/MCP commands, install, validate |
| `docs/decisions/` | ADRs for significant harness splits |
| `skills/*/SKILL.md` | Repeatable agent procedures |
| Code / examples | Behavior—link, do not copy |

Article pattern: [FAQ-driven development](https://dev.to/arenukvern/faq-driven-development-or-new-old-way-to-write-docs-rules-prompts-25jl).

## Anti-patterns

- 1,000-line `AGENTS.md` (crowds out task context)
- CLI and MCP with different validation rules
- Docs that paraphrase code instead of linking
- Domain tutorials in Agent Guild (wrong repo—meta harness only)
- Relying on vector search instead of structured docs + `skills find`

## Checklist before claiming “harness ready”

- [ ] Agent can discover what to run from in-repo docs alone
- [ ] CLI command exists for CI/gates (or documented why not)
- [ ] MCP tool shares schema/validation with CLI (if MCP applies)
- [ ] Failure messages say how to remediate
- [ ] ADR or DESIGN_FAQ explains why split exists
- [ ] Guild `npm run validate` passes if skills changed

## Install

```bash
npx skills add arenukvern/agent_guild --skill harness-engineering-culture
```

## References

- [harness-principles.md](references/harness-principles.md) — OpenAI article distilled
- [cli-mcp-pattern.md](references/cli-mcp-pattern.md) — Dual surface, shared core
- [guild-composition.md](references/guild-composition.md) — Which Guild skill when
