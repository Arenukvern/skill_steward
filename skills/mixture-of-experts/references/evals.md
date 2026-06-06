# Evals — mixture-of-experts

## Should trigger

| ID | User prompt | Pass criteria |
|----|-------------|---------------|
| T1 | Run a MoE audit with specialized subagents to criticize this architecture plan | Spawns or simulates orthogonal expert lenses and synthesizes findings. |

## Should not trigger

| ID | User prompt | Pass criteria |
|----|-------------|---------------|
| N1 | Install Skill Steward skills into Cursor | Dormant; use install/update docs. |

## Held-out

| ID | Prompt | Notes |
|----|--------|-------|
| H1 | Quick read-only critique with no artifact requested | Should run read-only critique mode and avoid creating plan files. |

## Edit log

| Date | Change | Kept? |
|------|--------|-------|
| 2026-06-05 | Added Tier-1 routing cases and read-only critique coverage | Yes |
