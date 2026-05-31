---
name: missing-license
description: A skill that is intentionally missing its license frontmatter field to test the validator warning path.
---

# Missing License

This fixture exercises the `validateLicense` warning in the validator.
It has no `license:` key in the frontmatter and a `references/sources.md` so only
the license warning fires.

## When to use

- (Test fixture only — not a real skill)
