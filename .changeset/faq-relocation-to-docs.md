---
"skill-steward": patch
---

docs: move DESIGN_FAQ, NORTH_STAR pointer, and DX_FAQ into docs/ folder and convert to MDX

- Move `DESIGN_FAQ.md` to `docs/DESIGN_FAQ.mdx`
- Move `DX_FAQ.md` to `docs/DX_FAQ.mdx`
- Remove root pointer `NORTH_STAR.md` (canonical version is `docs/NORTH_STAR.mdx`)
- Update `docs.json` sidebar configuration to route them natively
- Update all reference links and paths across `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `docs/**/*.mdx`, and all custom skills in the repository
