# steward-validate-on-save

First Skill Steward **plugin** ([ADR 0004](../../docs/decisions/0004-plugin-packaging-and-install-path.mdx)): mechanical gate after skill edits.

`plugin.yaml` is a Steward v1 plugin manifest. It references canonical skills in `skills/`; it does not copy `SKILL.md` files into this plugin.

## Why this plugin first?

| Factor | Assessment |
|--------|------------|
| **Scope** | Meta-only; only runs in Skill Steward repos |
| **Harness fit** | OpenAI harness pattern: enforce invariants mechanically |
| **Pain addressed** | Merged broken `SKILL.md` frontmatter without running validate |
| **Dependencies** | Node (`pnpm run validate`) + optional `steward validate` (Dart) |
| **Cursor gap** | `npx skills` does **not** install hooks — plugin documents merge |
| **Risk** | Low — read-only validation; fails PR if invalid |
| **Alternatives** | CI only (already exists) — hook gives **immediate** agent/human feedback |

**Not chosen first:** MCP meta server (heavier), FAQ auto-edit (noisy), global shell gate (too broad).

## Install (Cursor, project)

1. Install skills (if not already):

   ```bash
   npx skills add arenukvern/skill_steward -y
   ```

2. Merge hook into `.cursor/hooks.json`:

   ```json
   {
     "version": 1,
     "hooks": {
       "afterFileEdit": [
         {
           "command": "plugins/steward-validate-on-save/hooks/validate-on-skill-edit.sh"
         }
       ]
     }
   }
   ```

   Or copy from [hooks.json.snippet](hooks.json.snippet). Adjust path if you symlink this plugin elsewhere.

3. Ensure scripts are executable:

   ```bash
   chmod +x plugins/steward-validate-on-save/hooks/validate-on-skill-edit.sh
   ```

4. Verify the manifest and skills from the repo root:

   ```bash
   pnpm run validate
   ```

## Behavior

On `afterFileEdit`, if the file path matches `skills/**/SKILL.md`:

- Warns if `skills/{name}/references/sources.md` is missing (citation discipline)
- Then runs validation from repo root:

1. `cd packages/steward_cli && dart run :steward validate` when Dart SDK present
2. Else `pnpm run validate` (npm fallback if pnpm missing)

Non-skill edits are ignored.

## Uninstall

Remove the `afterFileEdit` entry from `.cursor/hooks.json`.
