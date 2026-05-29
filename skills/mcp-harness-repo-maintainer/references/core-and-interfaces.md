# Core vs interfaces (reference)

**Canonical pattern for the `<workspace>/` sibling family:** MCP and CLI are **thin agent-facing interfaces** (APIs). **Core** holds domain logic, schemas, and orchestration. Adapters translate; they do not own business rules.

## Layer diagram

```text
                    ┌─────────────────────────────────────┐
  Human / CI        │  CLI (thin)                         │
  ───────────────►  │  doctor, validate, init, exec, …    │
                    └──────────────┬──────────────────────┘
                                   │ same catalog / schemas
                    ┌──────────────▼──────────────────────┐
  Agent in chat     │  MCP (thin)                         │
  ───────────────►  │  tools, resources, prompts          │
                    └──────────────┬──────────────────────┘
                                   │
                    ┌──────────────▼──────────────────────┐
                    │  Core (thick)                       │
                    │  • domain logic & invariants        │
                    │  • schema / contract validation     │
                    │  • registries (tools, capabilities) │
                    │  • shared models (IntentCall, packages) │
                    └──────────────┬──────────────────────┘
                                   │
                    ┌──────────────▼──────────────────────┐
                    │  Runtime / IO                       │
                    │  VM Service, FS, HTTP, subprocess, …  │
                    └─────────────────────────────────────┘
```

## Responsibilities

| Layer | Responsibility | Must not |
|-------|----------------|----------|
| **CLI** | Parse argv; stable flags; `--json` for agents/CI; exit codes; call core | Embed domain rules only here |
| **MCP** | Map tool/resource names to core; structured errors; auth at transport | Duplicate logic missing from CLI path |
| **Core** | Single implementation of each capability; testable without MCP or TTY | Know about Cursor vs Codex UI |
| **Runtime** | IO and process boundaries | Leak into tool descriptions |

## Parity rule

> If a capability exists for agents (MCP tool), CI and scripts must reach the **same core entrypoint** via CLI (or a shared library called by both).

Divergence is a **bug**. New feature workflow:

1. Implement in **core** (with unit tests).
2. Expose **CLI** subcommand (for `make check`, doctor, CI).
3. Register **MCP** tool (or resource) with identical semantics and error shapes.
4. Document once in skills/docs; reference both surfaces.

## Examples in sibling repos

| Repo | CLI (thin) | MCP (thin) | Core (thick) |
|------|------------|------------|--------------|
| **mcp_flutter** | `flutter-mcp-toolkit` (`doctor`, `exec`, `validate-runtime`) | `flutter-mcp-toolkit-server` `fmt_*` tools | `packages/core`, `server_capability_*`, registry |
| **IntentCall** (`agentkit/`) | catalog `exec` commands | `intentcall_mcp` adapter | `intentcall_core`, `intentcall_schema` |
| **flutter_harness** | `flutter_harness` lint/run/consume | (none—by design) | HS engine, adapters, app registry |
| **flutter_visual_reconstruct** | `compare`, `deconstruct`, `guild validate` | (none—by design) | profile engine, verdict pipeline |
| **skill_steward** | `steward validate` / `steward list` / `steward eval` | (future meta index) | `packages/steward_cli` (Dart) |

Repos without MCP still use the **CLI → core** split; MCP is optional second adapter.

## IntentCall pattern (explicit)

```text
intentcall_schema   → contracts (Tier A validation)
intentcall_core     → registry, invoke, domain types
intentcall_mcp      → MCP wire adapter only
CLI                 → CommandCatalog → intentcall_core
```

## Anti-patterns

- Fat MCP tool handler with 200 lines and no shared core function
- CLI `doctor` that checks different things than MCP `fmt_doctor`
- Copy-paste between `bin/*.dart` and `lib/src/mcp/*` instead of one `core` call
- Putting “how to fix” strings only in MCP JSON—not in CLI stderr for CI

## Guild (meta)

Guild’s **product** is skills/docs, not a domain core—but the same shape applies:

- **Core:** validation rules (`packages/steward_cli` — Dart; `steward validate` / `steward eval`)
- **CLI:** `steward validate` (thin wrapper)
- **MCP:** future skill-index server—thin over same validators

Do not put marketplace or harness **philosophy** in CLI code; keep it in skills and ADRs.
