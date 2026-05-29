# CLI + MCP pattern (mcp_flutter / agentkit)

## Why both

| Surface | Best for |
|---------|----------|
| **CLI** | CI, Make targets, snapshots, `doctor --json`, contract gates, non-interactive automation |
| **MCP** | Cursor, Codex, Claude—tool calls inside conversation |

Same **command catalog** and **schema validation** internally; UX differs.

## agentkit layering

```text
agentkit_schema   → wire types, validateAgainstSchema (Tier A)
agentkit_core     → AgentCallEntry, registry, invokeDirect
agentkit_mcp      → MCP adapter
CLI exec          → CommandCatalog + same schema factories
app dynamics      → VM extensions / WebMCP
```

**Rule:** New interaction → shared schema factory → register CLI + MCP + app path together.

## Preflight pattern

```bash
flutter-mcp-toolkit doctor --json
flutter-mcp-toolkit get_extension_rpcs
# then exec or MCP tools
```

Agents should run doctor-style commands before expensive debug loops.

## Guild analogue

| Product | Guild meta |
|---------|------------|
| `flutter-mcp-toolkit validate-runtime` | `npm run validate` (skills) |
| `make check-contracts` | CI `validate-skills.yml` |
| `fmt_*` MCP tools | `npx skills` + skills in repo |
| AGENTKIT_PLATFORM.md contract tables | `docs/STANDARDS.md`, skill-spec-review |

When bootstrapping a new product harness, copy the **shape**, not the Flutter-specific commands.
