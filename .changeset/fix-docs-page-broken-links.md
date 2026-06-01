---
"skill-steward": patch
---

docs: fix docs.page broken links and enforce link validation constraints

- Strip `.md` and `.mdx` extensions from all relative and root-relative links under `docs/` to ensure proper routing on `docs.page`.
- Update traversals escaping the `docs/` directory to absolute GitHub URLs.
- Update `docs_test.dart` to enforce these link structure rules on all markdown files in `docs/`.
