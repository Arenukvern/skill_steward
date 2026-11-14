---
"skill-steward": patch
---

0.7.1 is the first **published** release that ships the 0.7.0 product changes (never released as a GitHub Release): MCP legacy removal including hard-delete of pipeline execution tools such as `steward_run_pipeline`, steward v1 actions-only config, OCI image `ghcr.io/arenukvern/steward-mcp`, and official MCP Registry publishing as `io.github.Arenukvern/steward-mcp`. See CHANGELOG **0.7.0** and `docs/migrations/pre-v1-pipelines-to-steward-v1.mdx`.

CI and release pipeline: macOS 15 runners, existing-tag finish dispatch, actionlint in validate, checksum basename contract, partial-release gates, and pinned actionlint download.
