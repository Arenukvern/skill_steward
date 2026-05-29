# Composing Agent Guild skills for harness work

## Typical sequence

1. **north-star-governance** — charter, AGENTS map, executable plans
2. **harness-engineering-culture** — frame CLI/MCP/docs approach
3. **adr-records** — ADR for harness boundary (e.g. CLI-only gate vs MCP exposure)
4. **concept-doc-store** — router, NORTH_STAR, doc lattice in product repo
5. **faq-driven-docs** — DESIGN_FAQ (why doctor exists) + DX_FAQ (how to run CLI)
6. **create-skill** — skill for agents using your harness (`flutter-mcp`, etc.)
7. **skill-spec-review** — before publishing skill to skills.sh
8. **multi-agent-handoff** — implementer/closer for large harness programs

## Repo type

| Repo | Guild focus |
|------|-------------|
| **agent_guild** | Meta-skills only; this skill + doc skills |
| **Product** (mcp_flutter, your app) | Apply harness skill *from install*; local ADRs + CLI/MCP |
| **agentkit** | Schema/core library; consumers integrate |

## Install bundle (consumer)

```bash
npx skills add arenukvern/agent_guild -a cursor -a claude-code -y
# Prioritize for harness builds:
#   north-star-governance, harness-engineering-culture, faq-driven-docs, adr-records
```

Hooks/plugins: install separately per [ADR 0004](../../../docs/decisions/0004-plugin-packaging-and-install-path.md).
