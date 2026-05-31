---
name: concept-doc-store
description: Bootstraps and maintains a vectorless, layered documentation store for concepts, architecture, and decisions—without duplicating how code works. Use when organizing repo docs, writing ADRs, north-star charters, agent playbooks, or product-style doc lattices.
license: MIT
metadata:
  author: skill-steward
  version: "1.0.0"
  category: documentation
paths:
  - "docs/**"
  - "NORTH_STAR.md"
  - "AGENTS.md"
  - "**/docs_map.mdx"
  - "decisions/**"
  - "docs/decisions/**"
  - "docs/superpowers/**"
---

# Concept doc store (vectorless)

Maintain documentation as a **git-native, linkable lattice**—not an embedding index. Agents and humans navigate by **role and question**, then jump to **code, examples, and tests** for behavior.

Reference layout: structured repository documentation directories (`docs/start_here/docs_map.mdx`, `docs/decisions/`, `docs/superpowers/`). Complements [faq-driven-docs](../faq-driven-docs/SKILL.md) (package-level DESIGN_FAQ / DX_FAQ).

## Core rule — three sources of truth

| Need | Authoritative source | Docs must… |
|------|---------------------|------------|
| **How code behaves** | Code, examples, tests | Link (`Authoritative source: path/`) — **never** paraphrase implementation |
| **Why we chose X** | ADRs, DESIGN_FAQ | Compress decision + trade-off only |
| **How to use the product** | DX_FAQ, guides, skills | Patterns and commands; defer API detail to examples |

If a doc paragraph could be replaced by reading a file or running an example, **delete the paragraph** and add a link.

## Doc lattice (layers)

Build only layers the repo needs. See [references/layer-catalog.md](references/layer-catalog.md).

| Layer | Typical path | Holds |
|-------|--------------|--------|
| **Router** | `docs/start_here/docs_map.mdx` | Tables: “I want to…” → one link |
| **Charter** | `docs/NORTH_STAR.md` | What the product owns; extension model; boundaries |
| **Decisions** | `docs/decisions/` or `decisions/` | ADRs — why the codebase looks like this |
| **Concepts** | `docs/core/`, `docs/start_here/why_*` | Architecture mental model, flows, glossary |
| **Agent ops** | `docs/ai_agents/`, `AGENTS.md` | Playbooks, init, troubleshooting for agents |
| **Programs** (optional) | `docs/superpowers/` | `specs/`, `plans/`, `tracker/*.yaml`, `closure/` |
| **Skills** | `skills/`, `plugin/skills/` | Procedural tasks — not architecture essays |
| **Published guides** | `docs/guides/` | Human-facing workflows |

**Vectorless** means: discovery is **structure + links + search in git**, not RAG over pasted code. Optional GitNexus/graph tools are adjuncts, not the doc store.

## What belongs in “concept” docs

Write when the reader needs **judgment**, not source lines:

- Boundaries (what this repo owns vs defers)
- Invariants and failure modes (“sticky session”, “prefix enforcement”)
- Agent/human roles (Implementer vs Closer, maintainer vs app dev)
- Diagrams of **components and data flow** (boxes and arrows, not full APIs)

Do **not** write:

- Line-by-line walkthroughs of functions (→ code + tests)
- Copy-pasted schemas that drift (→ `schema` command or generated types)
- Duplicate ADR rationale in README prose

## ADRs in the lattice

Use MADR-style ADRs per [adr-records](../adr-records/SKILL.md):

- Short, append-only, link to **authoritative source** paths
- Index table: id, title, status, shipped version
- `index.mdx` states: ADRs are for maintainers; day-to-day user docs live elsewhere

Example footer in ADR:

```markdown
**Authoritative source:** `packages/foo/lib/bar.dart`
```

## Optional: spec-driven programs (`superpowers/`)

For multi-phase agent work (e.g. structured program layouts):

```
docs/superpowers/
├── specs/           # Design SSOT (approved architecture)
├── plans/           # Human phase map + task lists
├── tracker/*.yaml   # Machine state for agents
├── closure/         # Gate evidence (verify against code)
├── evals/           # Verification rubrics
└── WHATS_NEXT.md    # Single forward index
```

**Tracker YAML** is state; **closure** is evidence; **plans/archive** is history — do not execute archived plans. Regenerate plans from tracker + spec when stale.

## Bootstrap workflow

1. Add **router** (`docs_map`) with Quick Router table.
2. Add **NORTH_STAR** (≤1 screen): ownership + extension model.
3. Add **decisions/** + index — meta-ADR `0000` if using ADRs.
4. Add **AGENTS.md** section: which doc to read for which question.
5. Root **QUICK_START.md** — pointers only, no duplicate architecture.
6. Wire publish config (`docs.json` / docs.page) if public site exists.

Checklist: [references/bootstrap-checklist.md](references/bootstrap-checklist.md).

## Maintain after changes

```
Change type?
├─ Architectural boundary / trade-off → ADR (+ optional DESIGN_FAQ)
├─ Public API usage pattern → DX_FAQ or guide (link to example)
├─ Agent procedure → skill SKILL.md
├─ Program phase complete → closure/ + tracker YAML + WHATS_NEXT
└─ Behavior detail changed → update code/tests/examples first; docs only link
```

Run `pnpm run validate` in skill_steward when touching skills; run project doc drift checks if present.

## Relationship to FAQ-driven docs

| Tool | Scope |
|------|--------|
| **concept-doc-store** (this skill) | Repo-wide lattice, ADRs, charters, agent programs |
| **faq-driven-docs** | Per-package DESIGN_FAQ + DX_FAQ compression |

Use both: lattice for navigation and decisions; FAQs for dense package knowledge.

## Install

```bash
npx skills add arenukvern/skill_steward --skill concept-doc-store
```

## References

- [Product documentation lattice analysis](references/product-doc-lattice.md)
- [Layer catalog](references/layer-catalog.md)
- [SSOT anti-duplication rules](references/ssot-rules.md)
- [FAQ-driven development article](https://dev.to/arenukvern/faq-driven-development-or-new-old-way-to-write-docs-rules-prompts-25jl)

## Sources

See [references/sources.md](references/sources.md). When researching, follow `skill-source-citations`.
