---
"skill-steward": patch
---

Add `release.yml` GitHub Actions workflow: uses `changesets/action` with `commitMode: github-api` to create a "Version Packages" PR when changesets accumulate on main, then tags and creates a GitHub Release automatically when that PR is merged. Adds `release:tag` script (`changeset tag && git push --tags`). See [ADR 0013](docs/decisions/0013-automated-release-via-changesets-action.md).
