# Evals — mcp-harness-repo-maintainer

## Should trigger

| ID | User prompt | Pass criteria |
|----|-------------|---------------|
| T1 | Enforce CLI/MCP/core split on product MCP PR | Archetype A checklist |
| T2 | Bootstrap a local repo harness with `steward.yaml` and prove the cold-start contract before diagnosing failures | Runs `doctor -> actions list -> action inspect -> probe -> benchmark`, interprets `durability_blocked`, and does not invent diagnostics |

## Should not trigger

| ID | User prompt | Pass criteria |
|----|-------------|---------------|
| N1 | Sourdough recipe | Dormant |

## Held-out

| ID | Prompt | Notes |
|----|--------|-------|
| H1 | Generalize a local Steward harness change across ecsly and intentcall after each repo already has a passing contract scenario | Should route primarily to `harness-engineering-lifecycle`; use this skill only for local contract shape questions |

## Edit log

| Date | Change | Kept? |
|------|--------|-------|
| 2026-06-05 | Added cold-start contract routing case after Steward benchmark proof loop landed | Yes |
