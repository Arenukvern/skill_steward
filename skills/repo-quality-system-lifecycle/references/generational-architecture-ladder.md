# Generational architecture ladder (portable digest)

**Canonical:** https://docs.page/arenukvern/skill_steward/core/generational-architecture-ladder
**Parent pattern:** [Evolutionary simplicity](evolutionary-simplicity.md)
**Status:** concept digest for installed skills · full article stays on docs.page

Help a repo grow, split, compress, demote, or delete the **next useful layer** only when the product has earned it. Higher is not better by default.

## Ladder

| Level | Name | Prefer when |
|-------|------|-------------|
| **G0** | Native workbench | Still proving product shape — language/framework, direct tests, short docs |
| **G1** | Visible repo grammar | Agents keep asking where truth lives — folders, AGENTS map, docs map, FAQ split |
| **G2** | Stable public surface | Callers need a dependable contract — API, schema, adapter boundary, compatibility tests |
| **G3** | Declarative / generated | Hand-written repetition is now risk — schema, codegen, lint, template, golden test |
| **G4** | Harness / feedback loop | Repeatable proof, probes, actions, benchmarks — thin CLI/MCP over core |
| **G5** | Ecology improvement | Proven local lesson upgrades future tools/skills — or deletes stale layers |

## Skeptic checks (before promoting)

- What user/maintainer goal does this serve?
- Is the pain repeated, or one-off from this run?
- Can language feature, native command, FAQ, or error message solve it?
- Would deleting, collapsing, or moving knowledge closer to behavior cost less?
- If generating: is the source schema smaller and more stable than the output?
- If harnessing: does it improve a real proof path, or become a detour?
- What falsifier shows the new layer is wrong, stale, or not worth keeping?

Unclear → observation / unknown case. Do not promote.

## Pattern Promotion Review

Lightweight evidence note when a real run exposes repeated friction or a proposal to add abstraction/generator/harness/skill/deletion. Not a new doctrine. Do **not** create a standalone skill from one review — only after repeated evidence that existing stewardship skills cannot cover the workflow (see DESIGN_FAQ / ADR 0019).

Minimum shape: original goal · repeated pattern · current vs proposed layer · boldest useful outcome · deletion option · maintenance delta · evidence needed · falsifier · non-claims.
