# Design Decisions FAQ — Agent Guild

Quick reference for **why** this repository is shaped the way it is. For charter detail see [ADR 0001](docs/decisions/0001-repository-purpose-as-skills-meta-layer.md). For operational how-to see [DX_FAQ.md](DX_FAQ.md).

## Charter

**Q: Where is the repo charter maintained?**  
A: [docs/NORTH_STAR.md](docs/NORTH_STAR.md) is canonical; published via [docs.json](docs.json). `AGENTS.md` is only the agent map (~100 lines). Skill `north-star-governance` maintains this split.

**Q: Why are plans and roadmaps not kept after implementation?**  
A: They are executable work orders. When done, knowledge moves to ADR, FAQ, code, or harness—then plans are removed. Stale checklists mislead agents. [ADR 0005](docs/decisions/0005-executable-plans-and-docs-page.md).

**Q: Why does Agent Guild exist instead of another skills catalog?**  
A: The open skills ecosystem has huge domain libraries; Guild is a **meta-layer**—managing, validating, and improving skills and processes—not competing on React/Flutter/cloud recipes. Domain skills stay in other repos.

**Q: Why skills and plugins instead of skills only?**  
A: **Skills** are portable instructions (`SKILL.md`, `npx skills`). **Plugins** are wiring (Cursor hooks, install glue) that skills CLI does not install on Cursor. See [ADR 0004](docs/decisions/0004-plugin-packaging-and-install-path.md).

**Q: Why keep each skill small and focused?**  
A: Agents load name + description first; bloated skills waste context. One outcome per skill; depth in `references/` or separate skills.

## Documentation

**Q: Why ADRs in `docs/decisions/`?**  
A: Durable **why** for repo evolution; PR-reviewable. FAQs hold operational compression; ADRs hold strategic decisions. [ADR 0000](docs/decisions/0000-use-markdown-architectural-decision-records.md).

**Q: Why DESIGN_FAQ and DX_FAQ at repo root?**  
A: [FAQ-driven development](https://dev.to/arenukvern/faq-driven-development-or-new-old-way-to-write-docs-rules-prompts-25jl) separates **why** (this file) from **how** (DX_FAQ). No duplication between them. [ADR 0002](docs/decisions/0002-adopt-faq-driven-documentation.md).

**Q: Why a concept doc lattice skill but no full `docs/superpowers/` here?**  
A: Guild is small; router + ADRs + FAQs suffice. `concept-doc-store` teaches the mcp_flutter-style lattice for larger repos. [ADR 0003](docs/decisions/0003-concept-doc-store-lattice.md).

## Packaging

**Q: Why are all installable skills under `skills/` only?**  
A: `npx skills` discovers `skills/{name}/SKILL.md`. Templates live in `templates/`; plugins in `plugins/`—neither is a skill package.

**Q: Why must `name` in frontmatter match the directory name?**  
A: Agent Skills spec + our validator; prevents install/discovery mismatches across 50+ agents.

**Q: Why `skills.sh.json` groupings?**  
A: skills.sh directory UI categories—not install logic. Listing is optional metadata for discovery.

**Q: Why no SKILL.md copies inside `plugins/`?**  
A: Skills are canonical in `skills/`; plugins reference skill ids in `plugin.yaml` to avoid drift. [ADR 0004](docs/decisions/0004-plugin-packaging-and-install-path.md).

## Harness

**Q: Why a harness-engineering-culture skill instead of only product CLIs?**  
A: Guild teaches **how to build** agent-first harnesses (CLI+MCP parity, docs map, Guild skill composition). Product repos (`mcp_flutter`, `agentkit`) ship the actual tools; see [OpenAI harness engineering](https://openai.com/index/harness-engineering/).

**Q: Why emphasize CLI before MCP in harness docs?**  
A: Deterministic gates (`doctor`, contracts, validate) belong in terminal/CI; MCP is the conversational layer on the same catalog—pattern from mcp_flutter [CLI vs MCP](https://github.com/Arenukvern/mcp_flutter/blob/main/docs/start_here/cli_vs_mcp.mdx).

## Quality

**Q: Why `npm run validate` instead of only human review?**  
A: Cheap CI gate on frontmatter, naming, and registry consistency before merge.

**Q: Why reject domain/framework skills in this repo?**  
A: Inclusion criteria in ADR 0001—out-of-scope PRs dilute the meta-layer and rot faster than maintainers can update.

**Q: Why MIT license at repo root?**  
A: Default for marketplace skills; per-skill `license` frontmatter can narrow if needed later.
