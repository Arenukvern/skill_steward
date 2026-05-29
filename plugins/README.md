# Plugins

**Plugins** wire agent runtimes (hooks, rules, commands). **Skills** (`skills/`) hold instructions and install via `npx skills`.

| Install | What |
|---------|------|
| `npx skills add arenukvern/skill_steward --skill <id>` | Skill only (portable, 50+ agents) |
| Plugin README + `install` (per plugin) | Hooks and other wiring — **not** covered by `npx skills` on Cursor |

**Specification:** [ADR 0004 — plugin packaging and install paths](../docs/decisions/0004-plugin-packaging-and-install-path.md)

**Scaffold:** [`_template/`](_template/)

**Shipped:**

| Plugin | Purpose |
|--------|---------|
| [guild-validate-on-save](guild-validate-on-save/) | Cursor `afterFileEdit` → validate when `skills/**/SKILL.md` changes (wired in [`.cursor/hooks.json`](../.cursor/hooks.json)) |

**Planned:** `guild-faq-reminder` (ADR 0004).
