# Design Decisions FAQ — Skill Steward

Quick reference for **why** this repository is shaped the way it is. For charter detail see [ADR 0001](docs/decisions/0001-repository-purpose-as-skills-meta-layer.mdx). For operational how-to see [DX_FAQ.md](DX_FAQ.md).

## Charter

**Q: Where is the repo charter maintained?**  
A: [docs/NORTH_STAR.mdx](docs/NORTH_STAR.mdx) is canonical; published via [docs.json](docs.json). `AGENTS.md` is only the agent map (~100 lines). Skill `north-star-governance` maintains this split.

**Q: Why are plans and roadmaps not kept after implementation?**  
A: Any plan format is fine (Superpowers, session plans, Issues, etc.)—Skill Steward does not define a template. When done, **extract** durable knowledge to ADR, FAQ, code, or harness, then **remove** the plan file so agents are not misled. [Plan hygiene](docs/start_here/executable-plans.mdx) · [ADR 0005](docs/decisions/0005-executable-plans-and-docs-page.mdx).

**Q: Why does Skill Steward exist instead of another skills catalog?**  
A: The open skills ecosystem has huge domain libraries; Guild is a **meta-layer**—managing, validating, and improving skills and processes—not competing on React/Flutter/cloud recipes. Domain skills stay in other repos.

**Q: Why skills and plugins instead of skills only?**  
A: **Skills** are portable instructions (`SKILL.md`, `npx skills`). **Plugins** are wiring (editor hooks, install glue) that skills CLI does not handle automatically. See [ADR 0004](docs/decisions/0004-plugin-packaging-and-install-path.mdx).

**Q: How do public vs private marketplaces work across agents?**  
A: **Public skills:** public Git + `npx skills add` + skills.sh. **Public plugins:** Editor marketplace manifests (`.cursor-plugin/`, `.claude-plugin/`). **Private:** private Git with team install (editor team marketplaces, agent `/plugin` commands + tokens, same `npx skills` if clone access). Skill `plugin-marketplace-setup` has the full matrix.

**Q: How should sibling repos differ?**  
A: One archetype per repo (agent-enabled product, platform libs, CLI harness, visual sidecar, meta steward). Product-centric repos own plugin SSOT + `init`; skill_steward owns meta-skills only. Skill `harness-repo-maintainer` (mixture-of-experts checklists) documents layout, contract gates, and production agent patterns.

**Q: Why both CLI and agent-protocol in product harnesses?**  
A: They are **thin interfaces** to the same **core**—CLI for CI and scripts, agent-protocols for in-chat agents. Logic belongs in core packages (e.g. product packages or core libraries); adapters must not diverge. Repos without agent-protocols (CLI harnesses, visual sidecars) still use CLI → core only.

**Q: Why require `references/sources.md` per skill?**  
A: Research and external knowledge must survive beyond one chat—links are provenance for humans and agents. Skill `skill-source-citations` defines the practice; `skill-eval-improve` adds eval/improve loops (plugin-eval, SkillOpt-style gates). Validator warns if `sources.md` is missing.

**Q: Why keep each skill small and focused?**  
A: Agents load name + description first; bloated skills waste context. One outcome per skill; depth in `references/` or separate skills.

**Q: Why Changesets for a skills repo that is not an npm product?**  
A: **Release legibility**—structured `.changeset/*.md` in PRs and `CHANGELOG.md` in git so humans and agents know what shipped at each repo version. Skills themselves are not semver’d; the root `skill-steward` package version tags the repository. [ADR 0009](docs/decisions/0009-adopt-changesets-for-repo-releases.mdx) · skill `release-changelog-harness`.

**Q: Why doesn’t Skill Steward ship precompiled release binaries?**  
A: **Different primary artifact.** Consumers install **skills** with `npx skills add arenukvern/skill_steward` (no full clone). `steward_cli` validates the **in-repo** `skills/` tree and delegates to Node—useful for maintainers with a checkout, not a standalone product binary. Product harness repos should ship Release tarballs + `install.sh`. [ADR 0010](docs/decisions/0010-binary-releases-for-product-harness-not-meta-steward.mdx) · skill `release-changelog-harness` → `references/binary-release-contract.md`.

**Q: How are skills evaluated (Microsoft / Google / Codex style)?**  
A: **Tiered:** Tier-1 charter skills require `evals/cases/*.yaml` + `pnpm run eval` (rule-based, no LLM in CI). Behavioral suites and judges stay offline (`references/evals.md`, plugin-eval, SkillOpt loop). Design language from [Chrome evals](https://developer.chrome.com/docs/ai/evals/design). [ADR 0011](docs/decisions/0011-tiered-skill-evals-and-rule-based-ci.mdx) · skill `skill-eval-improve`.

**Q: Where does GitHub profile / bio copy live?**  
A: **Not in this repo.** Public bio should point at the product harness and [skill_steward](https://github.com/Arenukvern/skill_steward) ([ADR 0008](docs/decisions/0008-adopt-skill-steward-product-name.mdx)). Repo-shape audits use `north-star-governance` + `concept-doc-store`, not product-specific boundary audits.

## Documentation

**Q: Why ADRs in `docs/decisions/`?**  
A: Durable **why** for repo evolution; PR-reviewable. FAQs hold operational compression; ADRs hold strategic decisions. [ADR 0000](docs/decisions/0000-use-markdown-architectural-decision-records.mdx).

**Q: Why DESIGN_FAQ and DX_FAQ at repo root?**  
A: [FAQ-driven development](https://dev.to/arenukvern/faq-driven-development-or-new-old-way-to-write-docs-rules-prompts-25jl) separates **why** (this file) from **how** (DX_FAQ). No duplication between them. [ADR 0002](docs/decisions/0002-adopt-faq-driven-documentation.mdx).

**Q: Why a concept doc lattice skill but no full `docs/superpowers/` in Guild?**  
A: Guild is small; router + ADRs + FAQs suffice. Teams may still use Superpowers (or any planner) in Guild or product repos—`concept-doc-store` teaches the layered doc lattice when you need it. [ADR 0003](docs/decisions/0003-concept-doc-store-lattice.mdx).

**Q: Where is the visual brand identity documented?**  
A: Practical reference + hero prompts in [docs/brand.mdx](docs/brand.mdx) · strategic decision, palette, and exact prompts in [ADR 0012](docs/decisions/0012-adopt-visual-brand-identity-system.mdx). Wired into README hero and `docs.json` (`socialPreview` + theme).

## Packaging

**Q: Why are all installable skills under `skills/` only?**  
A: `npx skills` discovers `skills/{name}/SKILL.md`. Templates live in `templates/`; plugins in `plugins/`—neither is a skill package.

**Q: Why must `name` in frontmatter match the directory name?**  
A: Agent Skills spec + our validator; prevents install/discovery mismatches across 50+ agents.

**Q: Why `skills.sh.json` groupings?**  
A: skills.sh directory UI categories—not install logic. Listing is optional metadata for discovery.

**Q: Why no SKILL.md copies inside `plugins/`?**  
A: Skills are canonical in `skills/`; plugins reference skill ids in `plugin.yaml` to avoid drift. [ADR 0004](docs/decisions/0004-plugin-packaging-and-install-path.mdx).

## Harness

**Q: Why a harness-engineering-culture skill instead of only product CLIs?**  
A: Guild teaches **how to build** agent-first harnesses (CLI+MCP parity, docs map, Guild skill composition). Product repos ship the actual tools; see [OpenAI harness engineering](https://openai.com/index/harness-engineering/).

**Q: Why emphasize CLI before MCP in harness docs?**  
A: Deterministic gates (`doctor`, contracts, validate) belong in terminal/CI; MCP is the conversational layer on the same catalog—standard CLI vs MCP parity pattern.

## Quality

**Q: Why `pnpm run validate` instead of only human review?**  
A: Cheap CI gate on frontmatter, naming, and registry consistency before merge.

**Q: Why reject domain/framework skills in this repo?**  
A: Inclusion criteria in ADR 0001—out-of-scope PRs dilute the meta-layer and rot faster than maintainers can update.

**Q: Why MIT license at repo root?**  
A: Default for marketplace skills; per-skill `license` frontmatter can narrow if needed later.
