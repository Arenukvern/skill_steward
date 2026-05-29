# guild-validate-on-save

First Agent Guild **plugin** ([ADR 0004](../../docs/decisions/0004-plugin-packaging-and-install-path.md)): mechanical gate after skill edits.

## Why this plugin first?

| Factor | Assessment |
|--------|------------|
| **Scope** | Meta-only; only runs in Agent Guild repos |
| **Harness fit** | OpenAI harness pattern: enforce invariants mechanically |
| **Pain addressed** | Merged broken `SKILL.md` frontmatter without running validate |
| **Dependencies** | Node (`npm run validate`) + optional `guild validate` (Dart) |
| **Cursor gap** | `npx skills` does **not** install hooks — plugin documents merge |
| **Risk** | Low — read-only validation; fails PR if invalid |
| **Alternatives** | CI only (already exists) — hook gives **immediate** agent/human feedback |

**Not chosen first:** MCP meta server (heavier), FAQ auto-edit (noisy), global shell gate (too broad).

## Install (Cursor, project)

1. Install skills (if not already):

   ```bash
   npx skills add arenukvern/agent_guild -y
   ```

2. Merge hook into `.cursor/hooks.json`:

   ```json
   {
     "version": 1,
     "hooks": {
       "afterFileEdit": [
         {
           "command": ".cursor/plugins/guild-validate-on-save/hooks/validate-on-skill-edit.sh"
         }
       ]
     }
   }
   ```

   Or copy from [hooks.json.snippet](hooks.json.snippet). Adjust path if you symlink this plugin elsewhere.

3. Ensure scripts are executable:

   ```bash
   chmod +x plugins/guild-validate-on-save/hooks/validate-on-skill-edit.sh
   ```

## Behavior

On `afterFileEdit`, if the file path matches `skills/**/SKILL.md`, runs from repo root:

1. `cd packages/guild_cli && dart run :guild validate` when Dart SDK present
2. Else `npm run validate`

Non-skill edits are ignored.

## Uninstall

Remove the `afterFileEdit` entry from `.cursor/hooks.json`.
