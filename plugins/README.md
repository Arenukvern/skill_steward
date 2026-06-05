# Plugins

**Plugins** wire agent runtimes (hooks, rules, commands). **Skills** (`skills/`) hold instructions and install via `npx skills`.

| Install | What |
|---------|------|
| `npx skills add arenukvern/skill_steward --skill <id>` | Skill only (portable, 50+ agents) |
| `plugins/{id}/plugin.yaml` + plugin README | Hooks and other wiring — **not** covered by `npx skills` on Cursor |

**Specification:** [ADR 0004 — plugin packaging and install paths](../docs/decisions/0004-plugin-packaging-and-install-path.mdx)

**Scaffold:** [`templates/plugin/`](../templates/plugin/)

`plugin.yaml` uses `schema: steward/plugin-manifest/v1`: it must reference canonical skill ids, target agent surfaces, lifecycle actions, and any shipped wiring artifacts. `pnpm run validate` fails when plugin manifests drift.

**Shipped:**

| Plugin | Purpose |
|--------|---------|
| [steward-validate-on-save](steward-validate-on-save/) | Cursor `afterFileEdit` → validate when `skills/**/SKILL.md` changes (wired in [`.cursor/hooks.json`](../.cursor/hooks.json)) |

**Planned:** `steward-faq-reminder` (ADR 0004).
