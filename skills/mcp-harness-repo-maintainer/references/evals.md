# Evals — mcp-harness-repo-maintainer

## Should trigger

| ID | User prompt | Pass criteria |
|----|-------------|---------------|
| T1 | Enforce CLI/MCP/core split on product MCP PR | Archetype A checklist |
| T2 | Bootstrap a local repo harness with `steward.yaml` and prove the cold-start contract before diagnosing failures | Runs `doctor -> actions list -> action inspect -> probe -> benchmark`, interprets `durability_blocked`, and does not invent diagnostics |
| T3 | Repeated adoption friction should become an unknown case or action candidate | Uses the H3→H5 promotion packet; captures first, promotes only after review |
| T4 | Single fresh-agent transcript asks for immediate diagnostic promotion | Rejects same-run promotion; records unknown case first |
| T5 | Adoption proof contains local-only Steward invocation paths | Routes to portable invocation hierarchy; keeps absolute paths as provenance only |

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
| 2026-06-10 | Added H3→H5 adoption promotion routing cases | Yes |
| 2026-06-10 | Added portable Steward invocation routing case after local-path adoption proof drift | Yes |
