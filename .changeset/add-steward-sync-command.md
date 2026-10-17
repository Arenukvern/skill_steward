---
"skill-steward": minor
---

Add `steward sync`: diff installed skill copies against the `skills.sh.json` marketplace manifest and prune skills this repository retired (report-only by default, `--prune` to delete, `--global` and repeatable `--path` to widen scope, `--json` for automation with exit 1 on drift). Steward-authored skills from other repos are reported as unrecognized and never pruned, and foreign skills sharing an install directory are untouched.
