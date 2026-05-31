# Product documentation lattice (analysis)

Why structured product repositories use the reference layout for **concept-doc-store**.

## Design intent

1. **Separate audiences** — humans (`start_here`, guides), agents (`ai_agents`, `AGENTS.md`), maintainers (`decisions`, `superpowers`).
2. **Router first** — `docs/start_here/docs_map.mdx` is a full index; root `QUICK_START.md` only points inward.
3. **Decisions ≠ tutorials** — `docs/decisions/` ADRs are compressed *why*; they explicitly say day-to-day docs live elsewhere.
4. **Code is behavior SSOT** — ADRs link to core implementation files instead of copying APIs.
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
| `docs/superpowers/` | Core program: specs, plans, tracker, closure, evals |
| `docs/platform/` | Platform product checklists (regression, external repo) |
| `docs/NORTH_STAR.md` | Charter |
| Root `AGENTS.md` | Agent rules + table to superpowers docs |
| `plugin/skills/` | Installable Agent Skills |

## What structured lattices avoid

- Putting full tool schemas in ADRs (→ tool descriptions, code, schema validation CLI)
- Treating archived phase plans as executable truth (→ tracker + closure)
- Mixing user marketing copy into decision records

## Vectorless

Docs are plain Markdown/MDX in git. Discovery = router + grep + links. Graph assistance tools are optional graph assistance, not a replacement for the lattice.
