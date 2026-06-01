---
"skill-steward": minor
---

feat: add repo-local skill registration commands and validation

- Implement `steward install` supporting local project installation, git cloning, and target-specific profile translation (scrubbing/relocating agent-specific metadata keys like `paths` for Cursor).
- Implement `steward update` to compare and update local skills based on locked SHAs in `skills.json` using fast `git ls-remote` checks.
- Extend `steward validate` with a `--local` flag to validate `.agents/skills/` against the `skills.json` configuration file.
- Update `docs/STANDARDS.mdx` with recommendations for nested namespaces (e.g. `metadata.cursor.paths`) and the recommended local layout.
