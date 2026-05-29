---
status: accepted
date: 2026-05-29
decision-makers: Skill Steward maintainers
consulted:
informed:
---

# Guild teaches harness meta; products own CLIs

## Context and Problem Statement

The open skills ecosystem has **product harnesses** with real CLIs and MCP servers (e.g. [mcp_flutter](https://github.com/Arenukvern/mcp_flutter) `flutter-mcp-toolkit`, [agentkit](https://github.com/Arenukvern/agentkit)). Skill Steward is a **meta-layer** ([ADR 0001](0001-repository-purpose-as-skills-meta-layer.md)) teaching how to build and document harnesses—not replacing product tools.

Contributors asked to formalize the split so Skill Steward does not grow a second Flutter MCP server or duplicate `doctor` / `exec` semantics.

## Decision Drivers

* **Clear ownership** — Users install Skill Steward for meta-skills; products for domain/runtime tooling.
* **Avoid confusion** — `npx skills add skill_steward` must not imply a debug MCP server ships here.
* **Teach by example** — Guild may ship a **small meta CLI** (validate, list skills) as reference harness, not a general automation platform.
* **Cross-promotion** — Product docs may recommend Skill Steward meta-skills (e.g. `harness-engineering-culture`) without merging repos.

## Considered Options

* **A. Guild ships full product-style CLI+MCP** — Competes with mcp_flutter; wrong scope.
* **B. Guild is skills-only forever** — No reference harness; harder to dogfood harness culture.
* **C. Skill Steward meta CLI (+ future meta MCP); products own domain CLIs** — Teach patterns; minimal typed tooling in Guild.
* **D. Document-only** — No executable harness in Guild.

## Decision Outcome

Chosen option: **"C. Skill Steward meta CLI (+ future meta MCP); products own domain CLIs"**.

### Split (normative)

| Layer | Repository | CLI / MCP examples | Guild skill support |
|-------|------------|--------------------|---------------------|
| **Meta harness** | `skill_steward` | `steward validate`, `steward list`; future MCP skill index | `harness-engineering-culture`, `north-star-governance`, … |
| **Product harness** | `mcp_flutter`, app repos | `flutter-mcp-toolkit`, `flutter-mcp-toolkit-server`, `fmt_*` | Install Guild skills via `npx skills` |
| **Library** | `agentkit` | Schema, registry adapters | Consumers integrate |

**Guild teaches:**

- **Thin CLI/MCP, thick core** — adapters are agent-facing APIs; domain logic lives in core libraries; both surfaces call the same entrypoints (pattern, not shared code)
- CLI + MCP **parity** on those shared contracts
- Docs map, North Star, plan hygiene doctrine ([ADR 0005](0005-executable-plans-and-docs-page.md))
- FAQ / ADR discipline

**Skill Steward does not teach:**

- Flutter VM service, widget tap, hot reload, or app dynamic tools

### Cross-promotion

Product repos (starting with mcp_flutter) may document:

```bash
npx skills add arenukvern/skill_steward --skill harness-engineering-culture
```

for contributors building or maintaining **product** harnesses.

### Consequences

* Good, because scope stays defensible in review.
* Good, because mcp_flutter remains the reference **product** harness; Guild is reference **meta** harness.
* Bad, because two CLIs in a contributor’s head—mitigated by naming (`steward` vs `flutter-mcp-toolkit`).
* Neutral, because meta MCP is deferred to phase 2 ([ADR 0007](0007-dart-for-guild-cli-and-harness-tooling.md)).

## Pros and Cons of the Options

### A. Full product CLI in Guild

* Good, because one repo for everything.
* Bad, because violates meta-layer charter; unmaintainable.

### B. Skills-only

* Good, because minimal.
* Bad, because no dogfood for harness-engineering-culture.

### C. Meta CLI + product CLIs (chosen)

* Good, because teaches without competing.
* Bad, because small amount of Dart tooling to maintain.

### D. Document-only

* Good, because zero code.
* Bad, because harness article emphasizes mechanical gates; validate CLI is the thinnest gate.

## More Information

* [OpenAI — Harness engineering](https://openai.com/index/harness-engineering/)
* [mcp_flutter CLI vs MCP](https://github.com/Arenukvern/mcp_flutter/blob/main/docs/start_here/cli_vs_mcp.mdx)
* Skill: `harness-engineering-culture`
