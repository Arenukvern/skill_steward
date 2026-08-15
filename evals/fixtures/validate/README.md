# Script Validation Evals (Fixtures)

This directory contains **golden fixtures** used to test the skill validator logic (`validate-skills.mjs` and its future Dart equivalent).

## Purpose

Before any major refactor of the validation logic (especially the port from Node `.mjs` to Dart), we define the expected behavior using concrete examples.

This follows the project's own `skill-eval-improve` and ADR 0011 philosophy: rule-based, reproducible checks with no LLM judges.

## Fixture Structure

Each subdirectory under `evals/fixtures/validate/` represents one test case (a simulated skill).

| Fixture | Expected Outcome | What it tests |
|---------|------------------|---------------|
| `good-skill/` | `errors: []`, clean | Happy path + sources.md present |
| `bad-name-mismatch/` | error on name/dir mismatch | `validateName` rule |
| `invalid-name-format/` | error on kebab-case + characters | Name regex validation |
| `missing-sources/` | warning (no error) | `references/sources.md` check |
| `has-readme/` | warning only | README.md inside skill folder |
| `too-long-body/` | warning (line count) | Soft 500-line recommendation |
| `missing-frontmatter/` | error | No `--- ... ---` block |
| `very-short-body/` | `errors: []`; warning "SKILL.md body is very short..." | Body content length < 50 chars after frontmatter (short/incomplete instructions) |
| `missing-skill-md/` | error "Missing required file SKILL.md" | Complete absence of SKILL.md (no file at all) |
| `registry-drift/` | `errors: []`; registry-level warning "Skill ... not listed in skills.sh.json groupings" (when registry is consulted) | Registry drift: well-formed skill dir whose `name` is absent from skills.sh.json |
| `missing-description/` | error "Missing required frontmatter field: description" (name check still runs) | Required `description` field missing from frontmatter (parse succeeds) |
| `invalid-yaml-compact-mapping/` | error containing "Invalid YAML frontmatter" and "npx skills" | Unquoted `description` contains `repository: app` — the js-yaml skip that hid `repo-quality-system-lifecycle` |

## How to use these evals

1. Run the validator against a specific fixture (future Dart support or manual):
   ```bash
   # Example (once Dart port exists)
   dart run :steward validate --fixtures evals/fixtures/validate
   ```

2. Compare actual output against the documented expectations in this file.

3. When adding new validation rules, add a corresponding fixture + update this README.

## Current Validation Rules Under Test (from scripts/validate-skills.mjs)

- `name` must match directory name
- `name` must follow kebab-case rules
- `description` length and presence (including explicit missing field case)
- `SKILL.md` must exist and have frontmatter
- `references/sources.md` should exist (warning only)
- No `README.md` inside skill folder (warning)
- Line count recommendation (<500)
- SKILL.md body very short (<50 chars) → warning (add step-by-step instructions)
- Missing required file SKILL.md entirely → hard error
- Registry drift warnings (skill dir not in skills.sh.json groupings, or vice-versa)
- Frontmatter must be valid YAML (`loadYaml` + no unquoted compact mappings). `npx skills` skips skills js-yaml cannot parse.

These fixtures are **not** Tier-1 skill evals. They are meta-evals for the repository's own validation harness.
