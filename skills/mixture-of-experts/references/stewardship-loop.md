# Stewardship loop (portable digest)

**Canonical:** https://docs.page/arenukvern/skill_steward/core/stewardship-loop  
**Charter:** https://docs.page/arenukvern/skill_steward/NORTH_STAR  
**Status:** concept digest for installed skills · full article stays on docs.page

**Engineering Stewardship** is the loop that keeps a repository understandable and improvable for humans and agents — product plus the ecology around it (tools, docs, decisions, tests, release, debugging, agent rules).

```text
Observe friction
  → classify repo / archetype
  → decide or clarify intent
  → update docs / spec / code / eval / harness
  → run or record proof
  → preserve learning
```

## Durable outputs (examples)

| Friction | Durable output |
|----------|----------------|
| Ambiguous direction | North Star, ADR, DESIGN FAQ |
| Repeated command failure | DX FAQ, validation script, typed action candidate |
| Hidden repo knowledge | AGENTS map, docs map, concept doc |
| Skill routing drift | Eval case, skill description update |
| Runtime diagnostic gap | Harness action, benchmark, unknown case |
| Release confusion | Changeset, changelog, artifact provenance |

A plan is not durable by itself. When work is done: extract learning, then remove stale plan files.

## Adoption check

Use when friction repeats or survives one session. Convert the learning into **exactly one** durable owner (ADR, FAQ, code, eval, action candidate, benchmark, or unknown case). Do not promote a permanent diagnostic from the same single run that discovered the issue.
