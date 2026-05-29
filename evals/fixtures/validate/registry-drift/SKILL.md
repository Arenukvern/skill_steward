---
name: registry-drift
description: Simulates a skill directory that is well-formed but absent from skills.sh.json, to exercise registry drift detection in the validator.
license: MIT
metadata:
  author: skill-steward
  version: "0.1.0"
  category: example
---

# Registry Drift

This skill is correctly formatted but its name will not appear in the registry groupings.

## When to use

- Testing validator registry checks
- Simulating unlisted skills

## Instructions

1. Validate the fixture collection
2. Observe drift warning for this entry

## Sources

See references/sources.md.