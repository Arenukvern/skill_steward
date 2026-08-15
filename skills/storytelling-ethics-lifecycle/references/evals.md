# Evals — storytelling-ethics-lifecycle

## Should trigger

| ID | User prompt | Pass criteria |
|----|-------------|---------------|
| T1 | Write a public story of how this repository was created and disclose what was generated vs curated | Role ledger, both ethics gates, disclosure block, story is not SSOT. |

## Should not trigger

| ID | User prompt | Pass criteria |
|----|-------------|---------------|
| N1 | Write an ADR for this accepted architectural decision | Routes to `repository-governance-lifecycle`. |

## Held-out

| ID | Prompt | Notes |
|----|--------|-------|
| H1 | Add sources.md citations for this new skill | Should route to `skill-source-citations`. |
| H2 | Write launch copy to grow signups | Must refuse hype; not a marketing skill. |

## Edit log

| Date | Change | Kept? |
|------|--------|-------|
| 2026-08-15 | Initial routing cases for public-story vs ADR vs citations | Yes |
