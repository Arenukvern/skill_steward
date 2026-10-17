# Plugins

**Plugins** wire agent runtimes (hooks, rules, commands). **Skills** (`skills/`) hold instructions and install via `npx skills`.

| Install | What |
|---------|------|
| `npx skills add arenukvern/skill_steward --skill <id>` | Skill only (portable, 50+ agents) |
| `plugins/{id}/plugin.yaml` + plugin README | Hooks and other wiring — **not** covered by `npx skills` on Cursor |

**Specification:** [ADR 0004 — plugin packaging and install paths](../docs/decisions/0004-plugin-packaging-and-install-path.mdx)

**Scaffold:** [`templates/plugin/`](../templates/plugin/)

**Host manifests:** repo-level plugin manifests live in `.codex-plugin/`,
`.cursor-plugin/`, `.claude-plugin/`, and `.plugin/`. Marketplace catalog roots
live in `.agents/plugins/marketplace.json`, `.cursor-plugin/marketplace.json`,
and `.claude-plugin/marketplace.json`. Use `dart run tool/install_agent_bundle.dart --check`
to preview the local copy layout before materializing generated payloads.

`plugin.yaml` uses `schema: steward/plugin-manifest/v1`: it must reference canonical skill ids, target agent surfaces, lifecycle actions, and any shipped wiring artifacts. `pnpm run validate` fails when plugin manifests drift.

**Shipped:**

| Plugin | Purpose |
|--------|---------|
| [steward-validate-on-save](steward-validate-on-save/) | Cursor `afterFileEdit` → validate when `skills/**/SKILL.md` changes (wired in [`.cursor/hooks.json`](../.cursor/hooks.json)) |

**Planned:** `steward-faq-reminder` (ADR 0004).

Discovery is shared by validation and bundling. A directory under `plugins/`
with `pubspec.yaml` or `mcp.json` and no `plugin.yaml` is treated as a native
Dart/MCP package and excluded from Steward wiring checks. Empty/cache-only directories are also excluded. Other directories with visible
wiring content still require a Steward manifest. A present `plugin.yaml` always
receives strict schema, references, lifecycle, path and artifact-hash checks,
even beside native package metadata. Native package correctness remains owned
by its native checks. A dangling manifest is an error, not an exemption.
