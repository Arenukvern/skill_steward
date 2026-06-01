# Plugin template

Not installable. Copy to `plugins/{your-plugin-id}/`.

1. Read [ADR 0004](../../docs/decisions/0004-plugin-packaging-and-install-path.mdx).
2. Edit `plugin.yaml` — reference skills by id from `skills/`, do not copy SKILL.md here.
3. Add `hooks/` and install docs if Cursor (or other) wiring is required.
4. Document: `npx skills add …` **plus** hook install steps (hooks are not installed by skills CLI on Cursor).
