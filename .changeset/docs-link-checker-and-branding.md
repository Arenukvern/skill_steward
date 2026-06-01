---
"skill-steward": patch
---

docs: add automated docs validation tests and improve documentation readability

- Add a Dart-based test suite `docs_test.dart` to validate `docs.json` configuration integrity, verify sidebar pages, and automatically find broken internal markdown links.
- Add ADR 0014 to the `docs.json` sidebar configuration.
- Correct outdated references to removed Node.js validation scripts in `docs/STANDARDS.mdx` and update the binary release Q&A in `docs/DESIGN_FAQ.mdx`.
- Clean up duplicate installation instructions and update the repository layout diagram in `README.md`.
- Expand the visual branding guide in `docs/brand.mdx` with copy-pasteable repository status badges and a guide on custom badge creation (capsules and Shields.io base64 dynamic badges).
