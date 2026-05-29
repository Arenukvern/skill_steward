# Agent Guild — North Star

**Status:** active · **Audience:** humans and agents

## What we are

A **meta-layer** for the Agent Skills ecosystem: small **skills** and **plugins** that help teams **manage other skills**, validate quality, document decisions, and improve agent workflows.

We are **not** a general domain skill catalog (React, Flutter, cloud recipes live elsewhere).

## What we own

| Own | Do not own |
|-----|------------|
| Meta-skills (`skills/`) | Domain/framework instruction packs |
| Skill validation (`npm run validate`) | Product MCP servers (see mcp_flutter, agentkit) |
| Doc patterns (FAQ, ADR, docs.page lattice) | Long-lived roadmaps in-repo |
| Plugin manifests (`plugins/`) when wired | Copy-pasted API docs of other products |
| Harness **culture** skill (how to build CLI/MCP harnesses) | Executable app/runtime code |

## How we ship value

1. **`npx skills add arenukvern/agent_guild`** — portable `SKILL.md` packages.
2. **Docs as system of record** — [docs.page](https://docs.page) site from `docs/` + `docs.json`; `AGENTS.md` is the agent map only.
3. **Mechanical gates** — CI validates skills; contributors run `npm run validate`.
4. **Executable plans only** — plans/todos/roadmaps are temporary; when done they become [ADR](decisions/), FAQ, code, or harness—then removed. See [Executable plans](start_here/executable-plans.md).

## Boundaries (non‑negotiable)

- One clear outcome per skill; `SKILL.md` stays lean.
- Skills in `skills/`; wiring in `plugins/`; templates in `templates/` (not installable).
- **Behavior SSOT is code** — docs link inward; they do not paraphrase implementations.
- New strategic **why** → ADR; standing **why** → [DESIGN_FAQ.md](../DESIGN_FAQ.md); **how** → [DX_FAQ.md](../DX_FAQ.md).

## Success looks like

- Agents and humans can install Guild meta-skills without confusion about scope.
- Product repos adopt our harness + FAQ patterns via installed skills.
- The repo stays small enough to maintain; stale plans do not accumulate.

## References

- [ADR 0001 — repository purpose](decisions/0001-repository-purpose-as-skills-meta-layer.md)
- [Harness engineering (OpenAI)](https://openai.com/index/harness-engineering/)
- [FAQ-driven development](https://dev.to/arenukvern/faq-driven-development-or-new-old-way-to-write-docs-rules-prompts-25jl)
