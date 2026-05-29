---
name: north-star-governance
description: Maintains docs/NORTH_STAR.md, wires AGENTS.md as a short agent map, and applies plan hygiene (any format—Superpowers, session plans, etc.) by extracting durable knowledge into ADR, FAQ, code, or harness then removing stale plan files. Use when updating charter, repo navigation, closing work, or docs.page structure. Does not define a new plan template.
license: MIT
metadata:
  author: skill-steward
  version: "1.0.0"
  category: governance
paths:
  - "docs/NORTH_STAR.md"
  - "AGENTS.md"
  - "docs.json"
  - "docs/start_here/**"
  - "docs/exec-plans/**"
---

# North Star governance

Keep Skill Steward **legible**: charter in one place, `AGENTS.md` as a **map**, plan artifacts **removed after extract** (any planning tool the user chooses).

## When to use

- Updating repo scope, boundaries, or success criteria
- Rewiring `AGENTS.md` or `docs.json` sidebar
- Creating or closing plans, roadmaps, todos in-repo
- After a milestone: “where should this knowledge live?”

## Canonical files

| File | Role | Max size guidance |
|------|------|-------------------|
| [docs/NORTH_STAR.md](../../docs/NORTH_STAR.md) | Charter: what we own, boundaries, success | ~1 screen |
| [AGENTS.md](../../AGENTS.md) | Agent **map** only—pointers, not encyclopedia | ~100 lines |
| [docs/start_here/docs_map.mdx](../../docs/start_here/docs_map.mdx) | Human + agent doc index |
| [docs.json](../../docs.json) | [docs.page](https://docs.page) sidebar |
| [docs/start_here/executable-plans.mdx](../../docs/start_here/executable-plans.mdx) | Plan hygiene — extract & remove (not a format spec) |

Root [DESIGN_FAQ.md](../../DESIGN_FAQ.md) / [DX_FAQ.md](../../DX_FAQ.md): standing why/how—not charter. Link from map; do not merge into North Star.

## Plan hygiene (format-agnostic)

**Do not invent a Guild plan format.** Users/agents may use Superpowers, Cursor plans, engineering-loop, Issues, `docs/exec-plans/active/`, or no file.

**Plans are temporary.** They drive work; they are not repo truth.

When work completes, **extract** durable bits and **delete** (or archive as non-executable) the plan:

```text
Done?  →  ADR (why) | DESIGN/DX FAQ | code/CI | skill/plugin/harness
       →  delete docs/exec-plans/active/* (or archive one-liner into ADR Notes)
       →  never leave checked boxes as history
```

| If the outcome is… | Put it in… |
|--------------------|------------|
| A decision with trade-offs | `docs/decisions/NNNN-*.md` + index row |
| Ongoing “why we do X” | `DESIGN_FAQ.md` Q&A |
| Commands / workflow | `DX_FAQ.md` location |
| Automation or gate | `scripts/`, `.github/workflows/`, future CLI |
| Agent procedure | `skills/{name}/SKILL.md` |
| Scope change | `docs/NORTH_STAR.md` (+ ADR if large) |

**Forbidden:** leaving finished checklists in-tree as if current; duplicate plan + ADR; executing archived Superpowers plans without tracker/spec.

Optional Guild scratch (not a standard): `docs/exec-plans/active/YYYY-MM-DD-short-title.md` until PR merges, then delete.

## Wire AGENTS.md (map pattern)

`AGENTS.md` must contain:

1. One paragraph purpose + `npx skills add` one-liner
2. **Documentation router** table → North Star, FAQs, decisions, standards, key skills
3. **Non-negotiables** (3–5 bullets): validate before PR, meta-only scope, plan hygiene (extract & remove), no secrets
4. **Install paths** table (Cursor, Claude, Codex, `.agents/skills`)
5. Link: “Skill authoring detail → [docs/STANDARDS.md](docs/STANDARDS.md)”

Move long skill-creation prose out of AGENTS—never grow AGENTS into a skill tutorial.

## Wire docs.json

When adding a new `docs/` section:

1. Add page file under `docs/`
2. Add sidebar entry in `docs.json`
3. Add row to `docs_map.mdx` Quick router
4. If agent-critical, add one line to `AGENTS.md` router table

Update `github` URL in `docs.json` when remote is known.

## Workflow: charter change

1. Draft North Star diff (scope, own/do-not-own table).
2. If architecturally significant → new ADR; link from North Star.
3. Trim AGENTS if it duplicated the charter.
4. Update DESIGN_FAQ only for new standing **why** Q&As.
5. No new permanent plan file—use PR description for ephemeral tracking.

## Guild skills to combine

| Task | Also use |
|------|----------|
| ADR from decision | `adr-records` |
| FAQ updates | `faq-driven-docs` |
| Doc lattice | `concept-doc-store` |
| Harness / CLI culture | `harness-engineering-culture` |
| New skill from outcome | `create-skill` |

## Install

```bash
npx skills add arenukvern/skill_steward --skill north-star-governance
```

## Sources

See [references/sources.md](references/sources.md). When researching, follow `skill-source-citations`.
