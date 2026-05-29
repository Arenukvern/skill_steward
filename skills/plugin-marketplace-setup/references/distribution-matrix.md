# Distribution matrix (reference)

Extended channel list for skills + plugins. Verify against upstream docs when shipping.

## Skills (`npx skills`)

| Channel | Public | Private | MCP | Hooks |
|---------|--------|---------|-----|-------|
| `npx skills add owner/repo` | Yes | Yes (if git access) | No | No |
| skills.sh index | Yes (public repos) | No | No | No |
| Project scope | `.agents/skills/` + agent symlinks | Same | No | No |
| Global `-g` | `~/.agents/skills/` | Same | No | No |

## Plugins by agent

| Channel | Manifest | Marketplace install | Private team |
|---------|----------|---------------------|--------------|
| Cursor public | `.cursor-plugin/plugin.json` | cursor.com/marketplace publish | N/A |
| Cursor team | `.cursor-plugin/marketplace.json` | Dashboard import GitHub repo | Teams / Enterprise |
| Claude Code | `.claude-plugin/*` | `/plugin marketplace add` | Private git + tokens |
| Codex | per OpenAI plugin layout | `codex plugin marketplace add` | Private git |
| Cline / Kiro hooks | varies | skills CLI + native hooks | varies |

## Product example (mcp_flutter)

| Step | Command |
|------|---------|
| Skills only | `npx skills add Arenukvern/mcp_flutter` |
| Full harness | `flutter-mcp-toolkit init cursor` |
| Claude marketplace | `/plugin marketplace add Arenukvern/mcp_flutter` |
| Codex marketplace | `codex plugin marketplace add Arenukvern/mcp_flutter` |

## When to use which

```text
Only instructions, many agents     → skills repo + npx skills
Hooks / MCP / commands bundle      → plugin manifest per agent
Multiple plugins one repo          → marketplace.json
Cursor org-internal only           → team marketplace (private Git)
Claude team private git            → .claude-plugin/marketplace.json + tokens
```
