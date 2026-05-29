---
"skill-steward": patch
---

Add `release.yml` GitHub Actions workflow: uses `changesets/action` to create a "Version Packages" PR when changesets accumulate on main, then tags and creates a GitHub Release automatically when that PR is merged. Adds `release:tag` script (`changeset tag && git push --tags`) used by the action's publish step.
