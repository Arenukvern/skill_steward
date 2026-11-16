---
"skill-steward": patch
---

CI drift guard: plugin manifests and root marketplace entries must match package.json version (extends `mcp:registry:check`). MCP publish pushes GHCR `:version` and `:latest` (same build) when version matches main; `server.json` stays pinned to the exact version tag.