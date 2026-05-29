# Contributing to Agent Guild

Thank you for adding skills to the marketplace.

## Quick start

Read [DX_FAQ.md](DX_FAQ.md) for commands; [DESIGN_FAQ.md](DESIGN_FAQ.md) for what belongs in Guild.

1. Fork and clone the repo.
2. Copy the template: `templates/skill/` → `skills/your-skill-name/`.
3. Edit `SKILL.md` (frontmatter + instructions).
4. Run `npm run validate`.
5. Update `skills.sh.json` and `README.md`.
6. Open a pull request.

## Skill quality bar

- **Focused**: one clear capability per skill.
- **Discoverable**: description names user intents ("deploy", "review PR", "write tests").
- **Portable**: avoid agent-specific paths unless documented in `compatibility`.
- **Small context**: short SKILL.md; scripts and references for heavy content.

## Pull request checklist

- [ ] `npm run validate` passes
- [ ] Skill added to `skills.sh.json` groupings
- [ ] `README.md` skill table updated
- [ ] No unrelated changes
- [ ] License compatible with MIT (repo default)

## Publishing to skills.sh

After merge to the default branch on GitHub, the public registry indexes repos that contain valid `SKILL.md` files. Ensure the repo is public and install commands use the correct `owner/repo` slug.

## Questions

Open an issue with the `skill-proposal` label for new categories or structural changes.
