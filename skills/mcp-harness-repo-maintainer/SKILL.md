---
name: mcp-harness-repo-maintainer
description: Maintains repo-local action contracts and harness repositories where product CLI and MCP adapters stay thin over core libraries. Use when adopting or improving steward.yaml actions, cold-start proof loops, probes, benchmarks, CLI/MCP/core parity, adapter refactors, packages/core boundaries, or sibling harness layout; use repo-quality-system-lifecycle first for general app/library/tool stewardship baselines.
license: MIT
type: governance
metadata:
  author: skill-steward
  version: "1.2.0"
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
  - "Justfile"
  - "justfile"
  - "package.json"
  - "Cargo.toml"
  - "pyproject.toml"
  - "pubspec.yaml"
  - "**/mcp.json"
  - "**/mcp*.json"
  - ".github/workflows/**"
  - "tool/**"
  - "scripts/**"
---

# Action Contract & Harness Repo Maintainer

Build and maintain repo-local action contracts and harnesses where agents execute and humans steer. The historical `mcp-` name remains because many adopters arrive through MCP work, but this skill is not MCP-only. For general app, library, tool, plugin, or meta-repo stewardship baselines, use `repo-quality-system-lifecycle` first; use this skill only when typed actions, probes, benchmarks, or CLI/MCP parity are in scope.

## Core principle (action-contract and harness repos)

**MCP and CLI are thin interfaces—APIs for agents and CI.** **Core** contains the real logic, schemas, and registries. Adapters parse wire format (argv, MCP JSON-RPC); they delegate immediately.

```text
Agents / CI  →  CLI ──┐
                      ├──► Core (logic, contracts, tests)
Agents / chat →  MCP ──┘
```

Full layering: [core-and-interfaces.md](references/core-and-interfaces.md). **Parity:** every MCP tool must call the same core entrypoint as its CLI twin.

**Progressive Automation (Agent-Driven Workflows):** Harnesses should let agents turn repeated friction into reviewed, durable capability. If an agent discovers a complex fix or command sequence, it should capture an unknown case or typed action candidate with owner, risk class, inputs, outputs, effects, provenance, and verification. Permanent `steward.yaml` changes must go through reviewable diffs and validation; do not teach agents to save raw bash permanently from MCP.

## Core Beliefs & Culture

1. **Missing capability → harness gap** — When an agent fails, ask what is not *legible* or *enforceable*, then add CLI command, MCP tool, linter, or skill.
2. **Ambiguous design → decision checkpoint** — Before coding a fork, use `repository-governance-lifecycle`; record an accepted ADR after agreement.
3. **Mechanical enforcement** — Linters, validate commands, schema validation at boundaries—error messages teach the agent how to fix. Use structured parsing (YAML, JSON, or AST).
4. **Progressive disclosure** — Router → ADR / DESIGN_FAQ (why) → DX_FAQ (how) → skills (procedures) → code (behavior SSOT).

## Harness Layers to Build

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

## Mixture of experts (pick one lead)

Route by **primary artifact** when the repo is harness or action-contract shaped. For the broader app/library/tool taxonomy, use `repo-quality-system-lifecycle`.

| Expert lens | Repo examples | Owns | Does not own |
|-------------|---------------|------|----------------|
| **Plugin/MCP** | `<plugin_repo>` | `plugin/mcp.json`, tool prefixing, init utility | Harness scripts, visual comparisons |
| **Library** | `<library_repo>` | Platform packages/modules, adapters | Shippable plugin tree, dogfood apps |
| **Harness/CLI** | `<harness_repo>` | Harness engine, app registry, fixture lint | MCP server binary, marketplace manifests |
| **D — Visual sidecar** | `<visual_sidecar>` | Profile configs, compare/deconstruct CLI | VM/MCP, dynamic registry |
| **Meta/governance** | `skill_steward` | `skills/`, `plugins/`, validator CLI, docs | Product MCP, domain tools |
| **F — Security/Ops** | all remotes | OAuth gateway, token brokering | Feature code |

## Universal maintainer spine (every archetype)

1. **Charter & Archetype** — `docs/NORTH_STAR.mdx` (or root pointer); `AGENTS.md` = map only.
2. **Behavior SSOT** — code + schemas; docs hold **why** and **how**.
3. **Thin adapters, thick core** — implement once in core; CLI + MCP are wrappers.
4. **Mechanical gates** — contract checks / validate commands / unit tests before merge.
5. **Plan hygiene** — extract to ADR/FAQ/code/skill then **delete** plan files.
6. **Version honesty** — single `VERSION` or release-please manifest.
7. **Distribution & Universal Translation** — Document per channel (`npx skills`, git marketplace). Avoid proprietary ecosystem lock-in. Ensure CLI tools natively compile governance to upstream IDE formats (e.g., `steward bundle` generating `.cursor/rules` and `.clinerules`).

## Workflow: Add Agent-First Capability

1. **Specify intent** — One sentence outcome + acceptance check.
2. **Choose surface**
   - CI / script / gate → **CLI** first
   - Conversational debug loop → **MCP tool** (reuse CLI core)
   - One-off guidance → **skill** in `skills/`
   - Event enforcement → **plugin** hook
3. **Make legible** — JSON schema, `--json` output, stable error codes, action effects, limits, and redaction policy; document in DX_FAQ.
4. **Document why** — ADR or DESIGN_FAQ Q&A.
5. **Wire map** — `AGENTS.md` / `docs_map` row.
6. **Validate** — `pnpm run validate` or project contract tests.
7. **Human collab** — PR describes harness change.

## Cold-start local harness proof loop

Use this loop before claiming a repo is harness-ready or diagnosing repo-specific symptoms. A fresh repo has no meaningful symptom catalog yet; first prove that agents can discover and safely execute declared contracts.

### Portable Steward invocation

Use `steward <command>` only after installing the released CLI or activating a local clone as a global command. Do not teach absolute local paths, private SDK paths, or sibling checkout paths as adoption instructions.

Preferred order:

1. Released adopter or CI path: `curl -fsSL https://raw.githubusercontent.com/Arenukvern/skill_steward/main/install.sh | bash`, then `steward <command>`.
2. Dart maintainer path from the Skill Steward clone: `cd packages/steward_cli && dart run :steward <command>`.
3. Local clone global activation: `dart pub global activate --source path packages/steward_cli`, then `steward <command>`.

Raw `dart --packages=... bin/steward.dart` commands are local provenance only. If evidence needs them, pair them with a portable command block and label the machine-specific path as non-copyable.

1. **Declare a small contract** — Add or update `steward.yaml` with one quick-safe action. The first action should inspect state, not mutate it.
2. **Expose the action** — Put the action under `probes.quick.actions` only when it passes quick policy: `default_policy: auto`, no confirmation, no shell, no network/secrets/destructive effects, no repo mutation, no `fs_write`.
3. **Add a scenario manifest** — Put committed scenarios under `steward/scenarios/*.yaml`; use a precise name such as `contract-status-smoke` until the scenario proves navigation or diagnosis.
4. **Run the proof loop**:

   ```bash
   steward doctor --json
   steward actions list --json
   steward action inspect <action-id> --json
   steward probe --profile quick --json
   steward benchmark --scenario <scenario-id> --output .steward/benchmark-summaries/<scenario-id>.json --json
   ```

5. **Interpret honestly** — `doctor`/`actions list` prove discovery, `action inspect` proves the executable boundary, `probe` proves the safe first observation, and `benchmark` proves durable execution only when it returns `result: "pass"`. `durability_blocked` is truthful blocked evidence when `steward.yaml` or `steward/scenarios/*.yaml` is modified or untracked; it is not H2 proof.
6. **Protect local state** — If the repo has temporary dirty files that must remain in place, write a do-not-touch exception and keep those files out of action inputs. Protected local state is not a benchmark blocker unless it is declared as a contract or scenario input.
7. **Grow from evidence** — If the probe exposes an unknown failure, capture an unknown case first. Promote a typed action candidate only after owner, effects, limits, redaction, validation command, and benchmark evidence exist. Do not promote diagnostics from the same run that discovered them.

### Native deterministic gate promotion

Prefer useful native gates over Steward-only scorekeeping. A repo may promote an existing deterministic script, test, or validation command into a Steward action when it has:

- positive proof on the current state
- a falsifier test or fixture that catches the regression class
- owner, risk class, effects, limits, and redaction policy
- a strict benchmark or eval that makes the capability discoverable
- explicit non-claims for product runtime correctness and broad H5 maturity

This is the path for turning evidence into a tool improvement packet. If the result cannot teach a later agent how to maintain or improve the repo's real tool surface, keep it as an observation or unknown case instead of promoting it.

## Adoption maturity ladder

Do not call a repository harness-ready until the proof stage matches the claim.

| Stage | Name | Proof |
|-------|------|-------|
| **H0** | Skills installed | Agent can discover the relevant Skill Steward skills. |
| **H1** | Local contract declared | `steward.yaml` exists with one quick-safe action and docs point to it. |
| **H2** | Smoke loop proven | Cold-start proof loop produces a durable benchmark summary with `result: "pass"`; `durability_blocked` keeps the repo below H2 until rerun cleanly. |
| **H3** | Repo feedback loop | Benchmark summaries, unknown cases, and action candidates accumulate from real work. |
| **H4** | Full agent workflow | A fresh agent completes one repo workflow without raw shell spelunking. |
| **H5** | Promoted harness capability | Repeated evidence promotes a diagnostic, action, eval, or local harness feature. |

## Archetypes Details

- **Archetype A (Product MCP):** `plugin/` is SSOT. Ship a **custom** server, do not patch community servers for product logic.
- **Archetype B (Platform Libs):** Core modules + wire protocol adapters only; no domain forks.
- **Archetype C (CLI Harness):** No MCP. Depends on product MCP core modules.
- **Archetype D (Visual sidecar):** No MCP. SSOT: `profiles/*.yaml`.
- **Archetype E (Meta Steward):** Core validators, thin CLI check. No `mcp.json`.
- **Archetype F (Production MCP):** Resources for read-only; tools for mutation. Return job IDs for long tasks. Use OAuth.

## Sibling layout

```text
<workspace>/
  <plugin_repo>/               # toolkit + MCP/plugin init
  <library_repo>/              # SDK platform/library packages
  <harness_repo>/              # CLI/harness runner
  <visual_sidecar>/            # D — comparison sidecar
  <meta_governance_repo>/      # meta skills & validation
```

## Checklist before claiming “harness ready”

Common proof:

- [ ] Agent can discover what to run from in-repo docs alone
- [ ] Repo is at least **H2** on the adoption maturity ladder
- [ ] Failure messages say how to remediate
- [ ] Design forks were checkpointed (`repository-governance-lifecycle`)
- [ ] Contract gate or validation scripts pass

Archetype-specific proof:

| Archetype | Required proof |
|-----------|----------------|
| Product MCP | MCP tools and CLI commands share the same core schema/validation entrypoints. |
| Platform libs | Protocol adapters are thin, core tests cover behavior, and no product-specific fork is embedded. |
| CLI harness | CLI command exists for CI/gates; MCP parity is not required unless the repo exposes MCP. |
| Visual sidecar | Profile/config schemas and compare/deconstruct commands are validated; MCP parity is not required. |
| Meta steward | Skill/plugin/validator surfaces pass skill validation and Tier-1 routing cases; no product runtime is bundled. |
| Security/Ops | Mutation surfaces require explicit risk class, redaction, and authorization policy. |

## Install

```bash
npx skills add arenukvern/skill_steward --skill mcp-harness-repo-maintainer
```

## References

- [core-and-interfaces.md](references/core-and-interfaces.md)
- [repo-archetypes.md](references/repo-archetypes.md)
- [maintainer-checklists.md](references/maintainer-checklists.md)
- [mcp-production-practices.md](references/mcp-production-practices.md)
- [sibling-layout.md](references/sibling-layout.md)
- [harness-principles.md](references/harness-principles.md)
- [cli-mcp-pattern.md](references/cli-mcp-pattern.md)
- [steward-composition.md](references/steward-composition.md)
- [preferred-tooling.md](references/preferred-tooling.md)

## Sources

See [references/sources.md](references/sources.md). When researching, follow `skill-source-citations`.
