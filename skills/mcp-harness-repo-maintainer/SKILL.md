---
name: mcp-harness-repo-maintainer
description: Maintains MCP-and-harness repositories where CLI and MCP are thin agent-facing interfaces and core libraries hold domain logic (e.g., skill_steward and generic sibling repos). Use when refactoring adapters, enforcing CLI/MCP/core parity, contract gates, or sibling repo layout.
license: MIT
metadata:
  author: skill-steward
  version: "1.1.0"
  category: harness
paths:
  - "AGENTS.md"
  - "docs/**"
  - "plugin/**"
  - "packages/**"
  - "src/**"
  - "mcp_server_*/**"
  - "Makefile"
  - "makefile"
  - "package.json"
  - "Cargo.toml"
  - "pyproject.toml"
  - "pubspec.yaml"
  - "**/mcp.json"
  - ".github/workflows/**"
  - "tool/**"
---

# MCP & harness repo maintainer

Maintain **agent-first repos** in the `<workspace>/` family without copying the wrong shape into the wrong repo.

## Core principle (all archetypes)

**MCP and CLI are thin interfaces—APIs for agents and CI.** **Core** contains the real logic, schemas, and registries. Adapters parse wire format (argv, MCP JSON-RPC); they delegate immediately.

```text
Agents / CI  →  CLI ──┐
                      ├──► Core (logic, contracts, tests)
Agents / chat →  MCP ──┘
```

Full layering: [core-and-interfaces.md](references/core-and-interfaces.md). **Parity:** every MCP tool must call the same core entrypoint as its CLI twin (or CLI-only repos expose core via commands only).

## When to use

- Bootstrapping or auditing product MCP repos (MCP + plugin + `init` command)
- Maintaining platform libraries, CLI harnesses, or visual comparison sidecars
- Keeping meta-stewards meta-only (skills/plugins, no product MCP, e.g. **skill_steward**)
- Wiring **sibling clones**, version pins, or contract CI across repos
- Applying production MCP patterns (resources vs tools, versioning, auth)

## Mixture of experts (pick one lead)

Read [repo-archetypes.md](references/repo-archetypes.md) for the full matrix. Route by **primary artifact**:

| Expert lens | Repo examples | Owns | Does not own |
|-------------|---------------|------|----------------|
| **A — Product MCP** | `<custom_mcp>` | `plugin/mcp.json`, tool prefixing, init utility (`[tool] init`), check contracts tasks | Harness scripts, visual comparisons |
| **B — Platform libs** | `<platform_libs>` | Platform packages/modules, adapters (MCP/WebMCP/native), publish sequence | Shippable plugin tree, dogfood apps |
| **C — CLI harness** | `<cli_harness>` | Harness engine, app registry, fixture lint/run tasks | MCP server binary, marketplace manifests |
| **D — Visual sidecar** | `<visual_sidecar>` | Profile configs, compare/deconstruct CLI | VM/MCP, dynamic registry |
| **E — Meta steward** | `skill_steward`, `<meta_steward>` | `skills/`, `plugins/`, validator CLI, documentation lattice | Product MCP, domain tools |
| **F — Security/Ops** | all remotes | OAuth gateway, token brokering, tool schema stability | Feature code |

**Rule:** One repo = one North Star. Cross-repo deps flow **down** the graph (see [sibling-layout.md](references/sibling-layout.md)), never circular.

## Universal maintainer spine (every archetype)

1. **Charter** — `docs/NORTH_STAR.md` (or root pointer); `AGENTS.md` = map only (~100 lines).
2. **Behavior SSOT** — code + schemas; docs hold **why** (ADR, DESIGN_FAQ) and **how** (DX_FAQ, skills).
3. **Thin adapters, thick core** — implement once in core; CLI + MCP are wrappers; CI uses CLI, chat uses MCP ([core-and-interfaces.md](references/core-and-interfaces.md)).
4. **Mechanical gates** — contract checks / validate commands / unit tests before merge; errors teach remediation.
5. **Plan hygiene** — any plan format OK; extract to ADR/FAQ/code/skill then **delete** plan files ([executable-plans](../../docs/start_here/executable-plans.mdx)).
6. **Version honesty** — single `VERSION` or release-please manifest; plugin manifests + generated embeds stay in sync.
7. **Distribution** — document per channel: `npx skills`, `init <agent>`, git marketplace ([plugin-marketplace-setup](../plugin-marketplace-setup/SKILL.md)).

## Archetype A — Product MCP

**SSOT tree:** `plugin/` (manifests, `mcp.json`, canonical `skills/`), CLI embeds via skill synchronization.

```text
plugin/
├── mcp.json
├── .cursor-plugin/plugin.json
├── .claude-plugin/plugin.json
├── .codex-plugin/plugin.json
└── skills/*/SKILL.md
.claude-plugin/marketplace.json   # source: ./plugin
mcp_server/                       # thin CLI router + thin MCP server binary (e.g., mcp_server_rust)
packages/*, src/*                 # core logic / capabilities implementation
make check-contracts              # manifests, skills, version, asset drift checks
```

**Golden commands:**

```bash
make sync-skills && make check-contracts
[tool-cli] init cursor   # e.g., init command for cursor
[tool-cli] doctor       # check runtime capabilities
```

**Do not** patch community MCP servers for product logic—ship a **custom** server ([production practices](references/mcp-production-practices.md)).

## Archetype B — Platform libs

- **Core:** `[platform]_core`, `[platform]_schema` — registry, validation, invocation logic.
- **Adapters:** `[platform]_mcp`, WebMCP/native—wire protocol adapters only; no domain forks.
- **CLI:** CLI runner command -> same core logic as MCP tools.
- Multi-package/module workspace; integration tests validated in product MCP.

## Archetype C — CLI harness

- **No MCP** by design—CLI is the sole agent/CI interface; still **thin** over harness core (harness engine, registry).
- Entry point: CLI executable; depends on product MCP **core packages/modules**, not duplicated toolkit logic.
- Local workspaces use path dependencies/overrides (e.g. workspace overrides) for sibling development (see [sibling-layout.md](references/sibling-layout.md)).
- Validation: test suite execution + fixture checks (lint/run fixtures).
- Skills under `plugin/skills/` for capture/semantic-test **workflows** only.

## Archetype D — Visual sidecar

- **No MCP** — CLI commands wrap profile/compare **core** library.
- SSOT: `profiles/*.yaml` or visual/profile definitions.
- Consumers: harness comparison steps, dogfood output validation.

## Archetype E — Meta steward (e.g., skill_steward)

- **Core:** validators (e.g. validator CLI package, linter rules).
- **CLI:** thin CLI check/list/validation commands.
- **MCP:** deferred meta index—must stay thin over same validators.
- **Skills** in `skills/`; **plugins** for hooks only.
- No `mcp.json`, no domain-specific product tools.
- Cross-promote product installs in docs.

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

## Sibling layout

```text
<workspace>/
  <product_mcp>/               # A — toolkit + MCP + init
  <platform_libs>/             # B — SDK platform
  <cli_harness>/               # C — CLI/Harness runner
  <visual_sidecar>/            # D — comparison sidecar
  <meta_steward>/              # E — meta skills & validation (e.g., skill_steward)
```

See [sibling-layout.md](references/sibling-layout.md) for dependency direction and dogfood details.

## Workflow: audit an existing repo

1. Classify archetype (A–E) from [repo-archetypes.md](references/repo-archetypes.md).
2. Check North Star + AGENTS map exist and are not duplicated encyclopedias.
3. List install channels documented (skills CLI, init, marketplace)—fill gaps using `plugin-marketplace-setup`.
4. Run that repo’s **contract gate** (e.g., validate scripts, build commands, tests).
5. Verify version/manifest/sync scripts if releasable.
6. File ADR if boundary changes (new MCP tool family, new sibling dep).

## Workflow: bootstrap a new product MCP repo (minimal)

1. ADR: scope, transport (stdio vs HTTP), tool prefix, auth model.
2. `plugin/mcp.json` + one agent manifest (Cursor or Claude).
3. `skills/` with setup + maintainer skills; duplicate or symlink for `npx skills`.
4. CLI: doctor, init <agent>, validate command mirroring MCP checks.
5. `tool/contracts/` + CI job running them on every PR.
6. `docs/ai_agents/overview.mdx` install matrix; link Skill Steward meta-skills.

## Guild skills to combine

| Need | Skill |
|------|-------|
| New procedure in Guild | `create-skill` |
| Marketplace / private install | `plugin-marketplace-setup` |
| Harness philosophy | `harness-engineering-culture` |
| Doc lattice | `concept-doc-store` |
| Repository branding & status badges | `repo-brand-identity` |
| Moral values & stewardship | `ethical-stewardship` |
| ADR | `adr-records` |
| Charter / plan hygiene | `north-star-governance` |

## Anti-patterns

- Domain logic in MCP tool handlers or CLI entry points without a shared **core** module
- CLI and MCP implementing the same capability twice (adapter drift)
- meta steward hosting product `mcp.json` or product MCP server code
- visual sidecar growing an MCP server “for convenience”
- Patching generic community MCP servers with private CRM/domain endpoints
- `skills/` and `plugin/skills/` diverging without sync or CI drift check
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

