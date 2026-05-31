---
"skill-steward": patch
---

feat(steward_cli): enforce `license` frontmatter field via validator

Adds `validateLicense` to `skill_rules.dart` — a warning (not an error) when a
skill's `SKILL.md` frontmatter is missing the `license` key, or uses an identifier
not found in the recognized SPDX set.

This operationalizes the **Artisan Credit & Craftsmanship** principle from
`ethical-stewardship` and the citation/provenance requirements from
`skill-source-citations` in the automated validation pipeline.

### Changes

- `packages/steward_cli/lib/src/validation/skill_rules.dart`
  - Added `_knownSpdxIds` constant with common SPDX identifiers.
  - Added `validateLicense(String? license) → List<String>` (warnings only).
  - Called from `validateSkillStructure` after body-length checks, before `sources.md` check.

- `evals/fixtures/validate/missing-license/` — new fixture isolating the license warning.
- `evals/fixtures/validate/*/SKILL.md` — added `license: MIT` to fixtures that were missing it (keeps per-fixture test expectations stable and focused).
- `packages/steward_cli/test/validation_test.dart` — adds `missing-license` expectation; adds fixture to aggregate `okOnes` set.
