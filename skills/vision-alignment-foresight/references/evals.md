# Evals — vision-alignment-foresight

## Should trigger

| ID | User prompt | Pass criteria |
|----|-------------|---------------|
| T1 | Critically analyze whether this harness vision fits user intent and future agent direction | Produces evidence, future-fit, falsifiers, and smallest proof. |

## Should not trigger

| ID | User prompt | Pass criteria |
|----|-------------|---------------|
| N1 | Write an ADR for an accepted repository decision | Routes to `repository-governance-lifecycle`. |

## Held-out

| ID | Prompt | Notes |
|----|--------|-------|
| H1 | Run broad MoE critique only | Should route to `mixture-of-experts`. |

## Edit log

| Date | Change | Kept? |
|------|--------|-------|
| 2026-06-05 | Added T1 behavior-critical routing cases for vision-vs-governance boundary coverage | Yes |
