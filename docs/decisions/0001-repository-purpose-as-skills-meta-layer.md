---
status: accepted
date: 2026-05-29
decision-makers: Skill Steward maintainers
consulted:
informed:
---

# Skill Steward as a meta-layer for skills and process improvement

## Context and Problem Statement

The open Agent Skills ecosystem (`npx skills`, [skills.sh](https://skills.sh), [agentskills.io](https://agentskills.io/)) makes it easy to publish and install many instruction packages. Repositories often grow into **large catalogs** of domain skills (framework guides, cloud recipes, design audits) with little cohesion.

Skill Steward was bootstrapped with marketplace scaffolding and several starter skills. Without an explicit charter, it risks being read as “another bag of skills” competing with `vercel-labs/agent-skills`, `anthropics/skills`, and thousands of community packages.

**Why should this repository exist, and what belongs here?**

## Decision Drivers

* **Focus**: Each artifact must be small, concise, and single-purpose—high signal per token for agents.
* **Meta, not domain**: Prefer capabilities that help teams **manage**, **compose**, **review**, and **improve** skills and agent workflows—not replace domain-specific skill libraries.
* **Cross-agent**: Installable via `npx skills` into Cursor, Claude Code, Codex, and peers without forked formats.
* **Continuous improvement**: Support evolving processes (handoffs, ADRs, validation, retros) rather than one-off prompts.
* **Plugins as well as skills**: Room for installable **plugins** (hooks, automations, registry glue) where a skill alone is insufficient—still kept minimal and purposeful.
* **Sustainable maintenance**: A small surface area a maintainer can keep correct beats a wide catalog that rots.

## Considered Options

* **A. General-purpose skills marketplace** — Accept any contributed skill; optimize for breadth and skills.sh leaderboard presence.
* **B. Curated domain guild** — Deep skills for one stack only (e.g. Flutter, Firebase, MCP).
* **C. Meta-layer guild (skills + plugins for managing skills and processes)** — Narrow charter: tooling, quality, orchestration, and improvement loops; defer domain knowledge to other repos.
* **D. Documentation-only org** — No installable packages; ADRs and guides only.

## Decision Outcome

Chosen option: **"C. Meta-layer guild (skills + plugins for managing skills and processes)"**, because it gives Skill Steward a clear reason to exist alongside larger marketplaces and matches the maintainer’s intent: **not a bunch of unrelated skills**, but a **concise control plane** for agent capability and process quality.

### Consequences

* Good, because contributors can reject out-of-scope PRs with a documented charter (this ADR).
* Good, because agents loading this repo get consistent “how to run the guild” behavior instead of random domain trivia.
* Good, because `validate-skills`, `skill-spec-review`, `create-skill`, `adr-records`, `faq-driven-docs`, and `multi-agent-handoff` are exemplars of the intended shape.
* Bad, because the repo will **not** replace specialized skill libraries; users must install domain skills elsewhere.
* Bad, because hook install is a second step on Cursor until plugin installers land — see [ADR 0004](0004-plugin-packaging-and-install-path.md).
* Neutral, because skills.sh listing remains useful for discovery, but popularity is not the primary success metric.

### Confirmation

* New skills are evaluated against the **inclusion criteria** below before merge.
* README and `skills.sh.json` groupings emphasize meta/process categories, not domain stacks.
* Follow-up delivered in [ADR 0004](0004-plugin-packaging-and-install-path.md) (`plugins/` layout and install paths).

## Inclusion criteria (what belongs in Skill Steward)

| Include | Exclude |
|---------|---------|
| Authoring, validating, and publishing skills | Framework-specific coding guides (React, Flutter, …) |
| Reviewing skill quality and spec compliance | Large reference corpora copied into skills |
| ADRs, FAQ-driven docs (DESIGN_FAQ / DX_FAQ), handoffs | One-off prompts with no reuse story |
| Registry/marketplace hygiene (index, validate, list) | Skills that duplicate official vendor packs without meta value |
| Small plugins that enforce or automate skill/process workflows | Heavy applications or long-running services in-repo |
| Continuous improvement loops (retro, update, deprecate skills) | “Everything bucket” contributions |

**Size rule of thumb:** prefer one clear outcome per skill; keep `SKILL.md` lean; push depth to `references/`; use scripts only when they save context or enforce checks.

## Repository shape (intended)

```
skill_steward/
├── skills/           # Installable meta-skills (small, focused)
├── plugins/          # Future: hooks/automation packages (ADR pending)
├── docs/decisions/   # Why the guild exists and how it evolves
├── scripts/          # Repo-level validation and tooling
└── templates/        # Scaffolding, not published as skills
```

Domain knowledge stays in **other repositories**; Skill Steward links to them via documentation, not by ingesting their content.

## Pros and Cons of the Options

### A. General-purpose marketplace

* Good, because fastest growth and skills.sh visibility.
* Bad, because indistinguishable from existing catalogs; high maintenance; violates concise/focused goal.

### B. Curated domain guild

* Good, because deep expertise in one stack.
* Bad, because overlaps vendor and community repos; wrong scope for “managing other skills.”

### C. Meta-layer guild

* Good, because unique charter; composes with any domain skill set.
* Good, because aligns with continuous improvement and orchestration.
* Bad, because requires discipline to reject scope creep.
* Neutral, because audience is smaller than mass-market skill packs.

### D. Documentation-only

* Good, because zero install surface.
* Bad, because fails the goal of installable skills/plugins via `npx skills`.

## More Information

* Y-Statement (short): In the context of a fragmented Agent Skills ecosystem, facing unbounded catalog growth and stale domain packs, we decided for a **meta-layer repository** to achieve **focused tooling for skill lifecycle and process improvement**, accepting that **domain skills must be sourced elsewhere**.
* Related: [ADR 0000](0000-use-markdown-architectural-decision-records.md)
* External: [adr.github.io](https://adr.github.io/) · [Agent Skills spec](https://agentskills.io/) · [vercel-labs/skills](https://github.com/vercel-labs/skills)
