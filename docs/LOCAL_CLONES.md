# Local clone names

GitHub product name: **Skill Steward** (`Arenukvern/skill_steward`). Many workspaces clone it as **`agent_guild/`** beside harness repos (e.g. in `~/mcp/` or any sibling directory).

## Maintainer setup

```bash
# Clone wherever you keep your workspace (e.g. ~/mcp/, ~/dev/, etc.)
cd <workspace>/agent_guild
pnpm install
pnpm run validate
```

## Consumer install (from a sibling repo)

```bash
# Project scope (example: flutter_harness)
cd <workspace>/flutter_harness
make agent-skills
# or install from the cloned local copy:
npx skills add <workspace>/agent_guild --skill mcp-harness-repo-maintainer -a cursor -y
```

## Harness bundle (recommended for product repos)

| Skill | Role |
|-------|------|
| `north-star-governance` | Charter, AGENTS map, plan hygiene |
| `harness-engineering-culture` | CLI/MCP harness culture |
| `mcp-harness-repo-maintainer` | Archetype checklists, sibling layout |
| `adr-records` | ADRs in `decisions/` |
| `faq-driven-docs` | DESIGN_FAQ + DX_FAQ |
| `create-skill` / `skill-spec-review` | Author and audit `plugin/skills/` |

See [flutter_harness AGENTS.md](https://github.com/Arenukvern/flutter_harness/blob/main/AGENTS.md) for the wired consumer example.
