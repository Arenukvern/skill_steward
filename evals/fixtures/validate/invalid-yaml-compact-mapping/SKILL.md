---
name: invalid-yaml-compact-mapping
description: Establish or audit a structural quality contract for any agent-operated engineering repository: app, library, CLI/tool, plugin, harness, or meta repo.
license: MIT
---

# Invalid YAML compact mapping

This fixture reproduces the `npx skills` skip: an unquoted description
contains `repository: app`, which js-yaml rejects as a nested mapping.
