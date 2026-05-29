# Contributing to Skill Steward

Thank you for adding skills to the marketplace.

## Quick start

Read [DX_FAQ.md](DX_FAQ.md) for commands; [DESIGN_FAQ.md](DESIGN_FAQ.md) for what belongs in Skill Steward.

1. Fork and clone the repo.
2. Copy the template: `templates/skill/` → `skills/your-skill-name/`.
3. Edit `SKILL.md` (frontmatter + instructions).
4. Run `pnpm run guild:validate` (or `pnpm run validate`).
5. Update `skills.sh.json` and `README.md`.
6. Open a pull request.

## Skill quality bar

- **Focused**: one clear capability per skill.
- **Discoverable**: description names user intents ("deploy", "review PR", "write tests").
- **Portable**: avoid agent-specific paths unless documented in `compatibility`.
- **Small context**: short SKILL.md; scripts and references for heavy content.

## Pull request checklist

- [ ] `pnpm run guild:validate` passes (same as CI)
- [ ] `pnpm run docs:check` passes (if you changed `docs/` or `docs.json`)
- [ ] Skill added to `skills.sh.json` groupings
- [ ] `README.md` skill table updated
- [ ] No unrelated changes
- [ ] License compatible with MIT (repo default)

## Documentation site

Published with [docs.page](https://docs.page): [https://docs.page/arenukvern/skill_steward](https://docs.page/arenukvern/skill_steward).

- Setup and preview: [docs/contributing/enable_docs_page.mdx](docs/contributing/enable_docs_page.mdx)
- Before PR: `pnpm run docs:check` (validates `docs.json` hrefs and doc links)

## Publishing to skills.sh

After merge to the default branch on GitHub, the public registry indexes repos that contain valid `SKILL.md` files. Ensure the repo is public and install commands use `arenukvern/skill_steward`.

## Questions

Open an issue with the `skill-proposal` label for new categories or structural changes.
