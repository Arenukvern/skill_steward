# Local clone names (`~/mcp/`)

GitHub product name: **Skill Steward** (`Arenukvern/skill_steward`). Many workspaces clone it as **`agent_guild/`** beside harness repos.

## Maintainer setup

```bash
cd ~/mcp/agent_guild
pnpm install
pnpm run steward:validate
```

## Consumer install (from a sibling repo)

```bash
# Project scope (example: flutter_harness)
cd ~/mcp/flutter_harness
make agent-skills
# or:
npx skills add ~/mcp/agent_guild --skill mcp-harness-repo-maintainer -a cursor -y
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
