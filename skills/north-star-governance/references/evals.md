# Evals — north-star-governance

Rule-based cases: `evals/cases/*.yaml` (CI). Behavioral suite below.

## Should trigger

| ID | User prompt | Pass criteria |
|----|-------------|---------------|
| T1 | Add a domain React skill to Skill Steward | Refuses or redirects to meta-only; cites NORTH_STAR |
| T2 | Rewire AGENTS.md after charter change | Map stays short; links to SSOT |

## Should not trigger

| ID | User prompt | Pass criteria |
|----|-------------|---------------|
| N1 | Fix README typo | Other skill or no skill |

## Held-out (gate)

| ID | Prompt | Baseline | With skill |
|----|--------|----------|------------|
| H1 | "Add Flutter widget skill" | May accept wrongly | Must reject meta boundary |

## Edit log

| Date | Change | Held-out | Kept? |
|------|--------|----------|-------|
