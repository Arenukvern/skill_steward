---
"skill-steward": minor
---

Remove the nine superseded skill directories as a hard cut (they were redirect stubs): `docs-refresh-lifecycle`, `mcp-harness-repo-maintainer`, `mixture-of-experts`, `plugin-marketplace-setup`, `skill-eval-improve`, `skill-source-citations`, `steward-continuity-boundary-lifecycle`, `storytelling-ethics-lifecycle`, and `vision-alignment-foresight`. Installs of these names no longer resolve; their procedures live in the six guild skills.

The eval-case schema, paired-dogfood guide, benchmark-adoption guide, October 2026 evaluation research, and the offline `compare_dogfood.dart` helper move to `skill-authoring-lifecycle`; the output-guidance reference moves to `harness-engineering-lifecycle`. The validate-on-save plugin references only `skill-authoring-lifecycle`, and `steward map` recommends only living skills. This breaks consumers installing or referencing the removed names.
