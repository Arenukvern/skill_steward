# mcp_flutter documentation lattice (analysis)

Why this repo is the reference for **concept-doc-store**.

## Design intent

1. **Separate audiences** — humans (`start_here`, guides), agents (`ai_agents`, `AGENTS.md`), maintainers (`decisions`, `superpowers`).
2. **Router first** — `docs/start_here/docs_map.mdx` is a full index; root `QUICK_START.md` only points inward.
3. **Decisions ≠ tutorials** — `docs/decisions/` ADRs are compressed *why*; they explicitly say day-to-day docs live elsewhere.
4. **Code is behavior SSOT** — ADR 0001 links `Authoritative source: packages/server_capability_kernel/lib/` instead of copying APIs.
5. **Spec-driven agent programs** — `docs/superpowers/` holds spec (truth), plan (tasks), tracker YAML (machine state), closure (evidence), archive (do not execute).
6. **North star** — `docs/NORTH_STAR.md` states what the product owns in bullet form, not implementation.
7. **Skills are procedures** — `plugin/skills/` teach *how to run a task*; architecture lives in `docs/core/` and ADRs.

## Folder map

| Path | Role |
|------|------|
| `docs/start_here/` | Positioning, feature map, migrations, **docs_map** router |
| `docs/core/` | Conceptual architecture for agents (flows, components) |
| `docs/ai_agents/` | Install, playbooks, marketplace, agent troubleshooting |
| `docs/guides/` | Task workflows (debugging, dynamic tools) |
| `docs/troubleshooting/` | Symptom → fix |
| `docs/decisions/` | ADRs (symlink to root `decisions/`) |
| `docs/superpowers/` | Agentkit program: specs, plans, tracker, closure, evals |
| `docs/agentkit/` | Product checklists (regression, external repo) |
| `docs/NORTH_STAR.md` | Charter |
| Root `AGENTS.md` | Agent rules + table to superpowers docs |
| `plugin/skills/` | Installable Agent Skills |

## What mcp_flutter avoids

- Putting full tool schemas in ADRs (→ MCP_RPC_DESCRIPTION, code, `schema` CLI)
- Treating archived phase plans as executable truth (→ tracker + closure)
- Mixing user marketing copy into decision records

## Vectorless

Docs are plain Markdown/MDX in git. Discovery = router + grep + links. GitNexus in `AGENTS.md` is optional graph assistance, not a replacement for the lattice.
