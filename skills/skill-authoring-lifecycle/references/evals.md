# Evals — skill-authoring-lifecycle

## Should trigger

| ID | User prompt | Pass criteria |
|----|-------------|---------------|
| T1 | Add skill `release-changelog-harness` | Valid layout, registry, validate passes |
| T2 | Review a skill for cross-agent marketplace/copy readiness | Checks copied-package assumptions, agent-specific metadata, citations, and bounded marketplace claims |

## Should not trigger

| ID | User prompt | Pass criteria |
|----|-------------|---------------|
| N1 | Deploy K8s with Terraform | Dormant |
| N2 | Install one existing public skill locally | Routes to install docs, not authoring |

## Held-out

| ID | Prompt | Notes |
|----|--------|-------|
| H1 | New skill with invalid `name` | Skill guides fix before merge |

## Edit log

| Date | Change | Kept? |
|------|--------|-------|
| 2026-06-19 | Added distribution-readiness coverage for copied skills and plugin bundles | Yes |
