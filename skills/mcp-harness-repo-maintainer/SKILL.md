---
name: mcp-harness-repo-maintainer
description: Maintains repo-local action contracts and harness repositories where product CLI and MCP adapters stay thin over core libraries. Use when adopting or improving steward.yaml actions, capability-level adoption evidence, cold-start proof loops, probes, benchmarks, CLI/MCP/core parity, adapter refactors, packages/core boundaries, or sibling harness layout; use repo-quality-system-lifecycle first for general app/library/tool stewardship baselines.
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

## Concept bridge (read before procedural steps)

Skill Steward procedures assume three portable lenses. If you only have this skill installed, load the digests in `references/` (they ship with the skill). Full essays live on docs.page.

| Lens | One-line | When to apply | Digest | Full |
|------|----------|---------------|--------|------|
| **Engineering Stewardship** | Keep the repo ecology understandable and improvable via observe → decide → update → prove → preserve | Friction repeats or survives one session | [stewardship-loop.md](references/stewardship-loop.md) | [docs.page](https://docs.page/arenukvern/skill_steward/core/stewardship-loop) · [North Star](https://docs.page/arenukvern/skill_steward/NORTH_STAR) |
| **Evolutionary simplicity** | Evolve toward lower future confusion (split / compress / promote / demote / delete / stay native) — not always fewer parts | Before adding, splitting, merging, or deleting a surface | [evolutionary-simplicity.md](references/evolutionary-simplicity.md) | [docs.page](https://docs.page/arenukvern/skill_steward/core/evolutionary-simplicity) |
| **Generational architecture** | Choose the smallest useful layer (G0–G5); higher is not automatically better; mature stewardship can move down | Before promoting codegen, harness actions, or new abstractions | [generational-architecture-ladder.md](references/generational-architecture-ladder.md) | [docs.page](https://docs.page/arenukvern/skill_steward/core/generational-architecture-ladder) |

**Install-world rule:** never rely on `../../docs/core/...` alone — those paths only work inside a skill_steward checkout. Prefer the digests above and absolute docs.page URLs.

These lenses are not a new doctrine skill (see [DESIGN_FAQ](https://docs.page/arenukvern/skill_steward/DESIGN_FAQ)). This skill *applies* them; the digests *teach* them when the docs tree is not present.

Build and maintain repo-local action contracts and harnesses where agents execute and humans steer. The historical `mcp-` name remains because many adopters arrive through MCP work, but this skill is not MCP-only. For general app, library, tool, plugin, or meta-repo stewardship baselines, use `repo-quality-system-lifecycle` first; use this skill only when typed actions, probes, benchmarks, or CLI/MCP parity are in scope.

## Core principle (action-contract and harness repos)

**MCP and CLI are thin interfaces—APIs for agents and CI.** **Core** contains the real logic, schemas, and registries. Adapters parse wire format (argv, MCP JSON-RPC); they delegate immediately.

```text
Agents / CI  →  CLI ──┐
                      ├──► Core (logic, contracts, tests)
Agents / chat →  MCP ──┘
```

Full layering: [core-and-interfaces.md](references/core-and-interfaces.md). **Parity:** every MCP tool must call the same core entrypoint as its CLI twin.

PLACEHOLDER_REST_OF_FILE_WILL_FOLLOW_IN_NEXT_COMMIT
