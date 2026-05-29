---
name: mcp-harness-repo-maintainer
description: Maintains MCP-and-harness repositories where CLI and MCP are thin agent-facing interfaces and core libraries hold domain logic—mcp_flutter, agentkit, flutter_harness, skill_steward. Use when refactoring adapters, enforcing CLI/MCP/core parity, contract gates, or ~/mcp sibling layout.
license: MIT
metadata:
  author: skill-steward
  version: "1.0.0"
  category: harness
paths:
  - "AGENTS.md"
  - "docs/**"
  - "plugin/**"
  - "packages/**"
  - "mcp_server_dart/**"
  - "Makefile"
  - "makefile"
  - "pubspec.yaml"
  - "**/mcp.json"
  - ".github/workflows/**"
  - "tool/**"
---

# MCP & harness repo maintainer

Maintain **agent-first repos** in the `~/mcp/` family without copying the wrong shape into the wrong repo.

## Core principle (all archetypes)

**MCP and CLI are thin interfaces—APIs for agents and CI.** **Core** contains the real logic, schemas, and registries. Adapters parse wire format (argv, MCP JSON-RPC); they delegate immediately.

```text
Agents / CI  →  CLI ──┐
                      ├──► Core (logic, contracts, tests)
Agents / chat →  MCP ──┘
```

Full layering: [core-and-interfaces.md](references/core-and-interfaces.md). **Parity:** every MCP tool must call the same core entrypoint as its CLI twin (or CLI-only repos expose core via commands only).

## When to use

- Bootstrapping or auditing **mcp_flutter**-style product repos (MCP + plugin + `init`)
- Maintaining **agentkit** (library platform), **flutter_harness** (CLI/HS), **flutter_visual_reconstruct** (offline compare)
- Keeping **skill_steward** meta-only (skills/plugins, no product MCP)
- Wiring **sibling clones**, version pins, or contract CI across repos
- Applying production MCP patterns (resources vs tools, versioning, auth)

## Mixture of experts (pick one lead)

Read [repo-archetypes.md](references/repo-archetypes.md) for the full matrix. Route by **primary artifact**:

| Expert lens | Repo examples | Owns | Does not own |
|-------------|---------------|------|----------------|
| **A — Product MCP** | `mcp_flutter` | `plugin/mcp.json`, `fmt_*` tools, `flutter-mcp-toolkit init`, `make check-contracts` | HS scripts, pixel guild profiles |
| **B — Platform libs** | `agentkit` | Dart packages, adapters (MCP/WebMCP/native), publish order | Shippable plugin tree, dogfood app |
| **C — CLI harness** | `flutter_harness` | HS v1/v2, app registry, fixture lint/run | MCP server binary, marketplace manifests |
| **D — Visual sidecar** | `flutter_visual_reconstruct` | `profiles/*.yaml`, compare/deconstruct CLI | VM/MCP, dynamic registry |
| **E — Meta steward** | `skill_steward` | `skills/`, `plugins/`, `steward validate`, docs.page | Product MCP, domain `fmt_*` |
| **F — Security/Ops** | all remotes | OAuth gateway, token brokering, tool schema stability | Feature code |

**Rule:** One repo = one North Star. Cross-repo deps flow **down** the graph (see [sibling-layout.md](references/sibling-layout.md)), never circular.

## Universal maintainer spine (every archetype)

1. **Charter** — `docs/NORTH_STAR.md` (or root pointer); `AGENTS.md` = map only (~100 lines).
2. **Behavior SSOT** — code + schemas; docs hold **why** (ADR, DESIGN_FAQ) and **how** (DX_FAQ, skills).
3. **Thin adapters, thick core** — implement once in core; CLI + MCP are wrappers; CI uses CLI, chat uses MCP ([core-and-interfaces.md](references/core-and-interfaces.md)).
4. **Mechanical gates** — `make check-*` / `pnpm run validate` / `dart test` before merge; errors teach remediation.
5. **Plan hygiene** — any plan format OK; extract to ADR/FAQ/code/skill then **delete** plan files ([executable-plans](../../docs/start_here/executable-plans.mdx)).
6. **Version honesty** — single `VERSION` or release-please manifest; plugin manifests + generated embeds stay in sync.
7. **Distribution** — document per channel: `npx skills`, `init <agent>`, git marketplace ([plugin-marketplace-setup](../plugin-marketplace-setup/SKILL.md)).

## Archetype A — Product MCP (mcp_flutter pattern)

**SSOT tree:** `plugin/` (manifests, `mcp.json`, canonical `skills/`), CLI embeds via `make sync-skills` → `skill_assets.g.dart`.

```text
plugin/
├── mcp.json
├── .cursor-plugin/plugin.json
├── .claude-plugin/plugin.json
├── .codex-plugin/plugin.json
└── skills/*/SKILL.md
.claude-plugin/marketplace.json   # source: ./plugin
mcp_server_dart/                  # thin CLI router + thin MCP server binary
packages/*, server_capability_*  # core logic (fmt_* implementation)
make check-contracts              # manifests, skills, version, asset drift
```

**Golden commands:**

```bash
make sync-skills && make check-contracts
flutter-mcp-toolkit init cursor   # or codex, claude-code, cline
flutter-mcp-toolkit doctor
```

**Do not** patch community MCP servers for product logic—ship a **custom** server ([production practices](references/mcp-production-practices.md)).

Product-specific depth: [mcp_flutter maintainer skill](https://github.com/Arenukvern/mcp_flutter/blob/main/plugin/skills/flutter-mcp-toolkit-repo-maintainer/SKILL.md) (install via `npx skills add Arenukvern/mcp_flutter --skill flutter-mcp-toolkit-repo-maintainer`).

## Archetype B — Platform libs (agentkit)

- **Core:** `agentkit_core`, `agentkit_schema` — registry, validation, invoke.
- **Adapters:** `agentkit_mcp`, WebMCP/native—wire only; no domain forks.
- **CLI:** `CommandCatalog` → same core as MCP tools.
- Multi-package workspace; integration proof in **mcp_flutter** (`make check-agentkit-integration`).

## Archetype C — CLI harness (flutter_harness)

- **No MCP** by design—CLI is the sole agent/CI interface; still **thin** over harness core (HS engine, registry).
- Entry: `bin/flutter_harness.dart`; depends on mcp_flutter **core packages**, not duplicated toolkit logic.
- `pubspec_overrides.yaml` for sibling `~/mcp/mcp_flutter` path.
- Validation: `dart test` + `tool/check_hs_fixtures.sh` (lint/run HS fixtures).
- Skills under `plugin/skills/` for capture/semantic-test **workflows** only.

## Archetype D — Visual sidecar (flutter_visual_reconstruct)

- **No MCP** — CLI commands (`compare`, `deconstruct`, `guild validate`) wrap profile/compare **core** library.
- SSOT: `profiles/*.yaml`; ADR for sidecar-only grounding.
- Consumers: flutter_harness HS `compare` steps, dogfood goldens in mcp_flutter.

## Archetype E — Meta steward (skill_steward)

- **Core:** validators (`scripts/validate-skills.mjs`; Dart parser later).
- **CLI:** `packages/steward_cli` — thin `steward validate` / `steward list`.
- **MCP:** deferred meta index—must stay thin over same validators.
- **Skills** in `skills/`; **plugins** for hooks only (`plugins/steward-validate-on-save`).
- No `mcp.json`, no `fmt_*` product tools—teach harness **culture**, not Flutter debug.
- Cross-promote product installs in docs; own `arenukvern/skill_steward` on skills.sh.

## Archetype F — Production MCP (all remotes)

Apply on every **remote** or **shared** MCP server:

| Practice | Action |
|----------|--------|
| Resources ≠ tools | Read-only data → resources; mutations → tools |
| Long work | Return job id + status resource; do not block stdio |
| Versioning | Additive tool schemas; bump server `version` |
| Auth | No token passthrough; OAuth 2.1 + PKCE for HTTP; env vars for stdio |
| Fleet | Gateway for audit/rate-limit when many servers |
| Supply chain | Pin server packages; review tool permissions like a public API |

Details: [mcp-production-practices.md](references/mcp-production-practices.md).

## Sibling layout (`~/mcp/`)

```text
~/mcp/
  mcp_flutter/                 # A — toolkit + MCP + init
  agentkit/                    # B — platform packages
  flutter_harness/             # C — HS CLI
  flutter_visual_reconstruct/  # D — compare (note: reconstruct, not reconstruction)
  skill_steward/                 # E — meta skills
```

See [sibling-layout.md](references/sibling-layout.md) for dependency direction and dogfood warm path.

## Workflow: audit an existing repo

1. Classify archetype (A–E) from [repo-archetypes.md](references/repo-archetypes.md).
2. Check North Star + AGENTS map exist and are not duplicated encyclopedias.
3. List install channels documented (skills CLI, init, marketplace)—fill gaps using `plugin-marketplace-setup`.
4. Run that repo’s **contract gate** (e.g. `make check-contracts`, `pnpm run validate`, `dart test`).
5. Verify VERSION/manifest/sync scripts if releasable.
6. File ADR if boundary changes (new MCP tool family, new sibling dep).

## Workflow: bootstrap a new product MCP repo (minimal)

1. ADR: scope, transport (stdio vs HTTP), tool prefix, auth model.
2. `plugin/mcp.json` + one agent manifest (Cursor or Claude).
3. `skills/` with setup + maintainer skills; duplicate or symlink for `npx skills`.
4. CLI: `doctor`, `init <agent>`, validate command mirroring MCP checks.
5. `tool/contracts/` + CI job running them on every PR.
6. `docs/ai_agents/overview.mdx` install matrix; link Skill Steward meta-skills.

## Guild skills to combine

| Need | Skill |
|------|-------|
| New procedure in Guild | `create-skill` |
| Marketplace / private install | `plugin-marketplace-setup` |
| Harness philosophy | `harness-engineering-culture` |
| Doc lattice | `concept-doc-store` |
| ADR | `adr-records` |
| Charter / plan hygiene | `north-star-governance` |

## Anti-patterns

- Domain logic in MCP tool handlers or CLI `main()` without a shared **core** module
- CLI and MCP implementing the same capability twice (adapter drift)
- skill_steward hosting product `mcp.json` or Flutter MCP server code
- flutter_visual_reconstruct growing an MCP server “for convenience”
- Patching generic community MCP servers with private CRM/domain endpoints
- `skills/` and `plugin/skills/` diverging without `sync-skills` or CI drift check
- Monolithic `AGENTS.md` replacing `docs/` + skills

## References

- [core-and-interfaces.md](references/core-and-interfaces.md) — thin CLI/MCP, thick core (start here)
- [repo-archetypes.md](references/repo-archetypes.md)
- [maintainer-checklists.md](references/maintainer-checklists.md)
- [mcp-production-practices.md](references/mcp-production-practices.md)
- [sibling-layout.md](references/sibling-layout.md)

## Install

```bash
npx skills add arenukvern/skill_steward --skill mcp-harness-repo-maintainer
```

## Sources

See [references/sources.md](references/sources.md). When researching, follow `skill-source-citations`.
