# Contributing to Skill Steward

Thank you for improving the Engineering Stewardship layer.

## Quick start

Read [docs/NORTH_STAR.mdx](docs/NORTH_STAR.mdx) for scope, [docs/start_here/docs_map.mdx](docs/start_here/docs_map.mdx) for canonical doc owners, [docs/DX_FAQ.mdx](docs/DX_FAQ.mdx) for commands, and [docs/DESIGN_FAQ.mdx](docs/DESIGN_FAQ.mdx) for standing rationale.

1. Fork and clone the repo.
2. Identify the canonical owner before editing docs or specs.
3. For a skill, copy `templates/skill/` to `skills/your-skill-name/` and follow [docs/STANDARDS.mdx](docs/STANDARDS.mdx).
4. For a repo-quality contract change, follow [docs/repo-quality-contracts.mdx](docs/repo-quality-contracts.mdx).
5. Run the relevant validation before PR.
6. Update registry/catalog surfaces when adding or renaming installable skills.
7. If the PR changes consumer-facing surfaces, run `pnpm changeset` and commit the generated `.changeset/*.md` ([ADR 0009](docs/decisions/0009-adopt-changesets-for-repo-releases.mdx)).
8. Open a pull request.

## Skill quality bar

- **Focused**: one clear capability per skill.
- **Discoverable**: description names user intents ("govern repo", "review PR", "write ADR", "validate skills").
- **Portable**: avoid agent-specific paths unless documented in `compatibility`.
- **Small context**: short `SKILL.md`; scripts and references for heavy content.

## Pull request checklist

- [ ] `pnpm run steward:analyze` passes (same as CI)
- [ ] `pnpm run validate` passes
- [ ] `pnpm run eval` passes when Tier-1 skill routing changed
- [ ] Changeset added when required (or PR title `[skip changeset]` with justification)
- [ ] `pnpm run docs:check` passes if you changed `docs/` or `docs.json`
- [ ] Visual/brand changes cite `docs/brand.mdx` + [ADR 0012](docs/decisions/0012-adopt-visual-brand-identity-system.mdx)
- [ ] Skill added to `skills.sh.json` using the current repo schema
- [ ] README and [docs/skills-catalog.mdx](docs/skills-catalog.mdx) updated when the skill catalog changed
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
