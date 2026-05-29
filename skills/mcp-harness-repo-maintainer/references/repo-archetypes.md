# Repo archetypes (reference)

Classification for `~/mcp/*` and similar agentic monorepos.

**Shared shape:** CLI and MCP (when present) are **thin**; **core** holds logic. See [core-and-interfaces.md](core-and-interfaces.md).

## Comparison table

| | **A Product MCP** | **B Platform** | **C CLI harness** | **D Visual sidecar** | **E Meta steward** |
|---|-------------------|----------------|-------------------|----------------------|------------------|
| **Example** | mcp_flutter | agentkit | flutter_harness | flutter_visual_reconstruct | skill_steward |
| **Primary ship unit** | Plugin + MCP binary | Pub packages | HS CLI + fixtures | Profiles + compare CLI | SKILL.md packages |
| **MCP server in-repo** | Yes | Adapter pkg only | No (consumes toolkit) | No | No |
| **plugin/mcp.json** | Yes | No | No | No | No |
| **init \<agent\>** | Yes (`flutter-mcp-toolkit`) | No | No | No | No |
| **Marketplace manifests** | .cursor + .claude + .codex | Rare | Optional skills only | No | N/A (skills.sh) |
| **Contract CI** | `make check-contracts` | analyze + publish dry-run | HS fixture scripts | `dart test` + profile lint | `pnpm run steward:validate` |
| **Dogfood app** | flutter_test_app | via mcp_flutter | harness/examples | goldens only | N/A |
| **ADR location** | decisions/ + docs/decisions | minimal | decisions/ | decisions/ | docs/decisions/ |
| **Superpowers /specs** | docs/superpowers/ | PRE_RELEASE docs | plans/, specs/ | specs/, plans/ | exec-plans optional scratch |

## Decision tree

```text
Does the repo expose an MCP server agents call in chat?
  No → Does it ship Agent Skills for npx skills only?
    Yes, meta/process → E (skill_steward)
    Yes, domain workflows in a product → skills under plugin/ or skills/ (supporting)
  No → Is the main artifact a CLI over apps/tests?
    Yes, HS/Maestro → C (flutter_harness)
    Yes, pixels/profiles only → D (flutter_visual_reconstruct)
  Yes → Does it publish multi-package SDK for others?
    Yes → B (agentkit) + integration test in A
    No → A (mcp_flutter-style product MCP)
```

## What to copy when forking

| From mcp_flutter | Copy to new product MCP | Skip for guild/harness |
|------------------|-------------------------|-------------------------|
| plugin/ + mcp.json | Yes | Yes — meta only |
| init_command + writers | Yes | Yes |
| skill_assets embed + sync-skills | Yes | Yes |
| tool/contracts/* | Pattern yes | Adapt to pnpm/skills |
| docs/ai_agents/overview.mdx | Yes | Shorten for guild |
| fmt_* capability layout | If VM/debug product | Yes |
