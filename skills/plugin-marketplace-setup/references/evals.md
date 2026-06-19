# Evals — plugin-marketplace-setup

## Should trigger

| ID | User prompt | Pass criteria |
|----|-------------|---------------|
| T1 | Design a private plugin marketplace for Codex and Cursor team installs | Routes to marketplace/channel matrix and install docs. |
| T2 | Create a reusable Codex/Cursor/Claude copy pattern like `mcp_flutter` | Routes to repo-local copy/init pattern, host manifests, install commands, cache/rollback notes, and bounded non-claims. |

## Should not trigger

| ID | User prompt | Pass criteria |
|----|-------------|---------------|
| N1 | Create a repo ADR about plan hygiene | Routes to `repository-governance-lifecycle`. |
| N2 | Install one public skill with `npx skills` | Stays skills-only and does not design host plugin marketplaces. |

## Held-out

| ID | Prompt | Notes |
|----|--------|-------|
| H1 | Install one public skill with `npx skills` | Should not trigger broad marketplace design. |

## Edit log

| Date | Change | Kept? |
|------|--------|-------|
| 2026-06-05 | Added T1 behavior-critical routing cases for plugin/marketplace boundary coverage | Yes |
| 2026-06-19 | Added repo-local copy/init pattern coverage for Codex/Cursor/Claude distribution | Yes |
