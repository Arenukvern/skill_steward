---
status: accepted
date: 2026-05-29
decision-makers: Skill Steward maintainers
consulted:
informed:
---

# Adopt Skill Steward as the public product name

## Context and Problem Statement

The repository was introduced as **Agent Guild** (`arenukvern/agent_guild`, now `arenukvern/skill_steward`). That name collided in search and mindshare with unrelated “guild” products (communities, agent runtimes, crypto marketplaces) and did not state the **meta-layer** role: validate, document, and govern portable `SKILL.md` packages—not install or translate skills ([Skillkit](https://github.com/rohitg00/skillkit) owns distribution).

The maintainer’s public work spans:

- **[mcp_flutter](https://github.com/Arenukvern/mcp_flutter)** — product **harness** (closed-loop Flutter agent tooling).
- **This repo** — **meta** skills for the [Agent Skills](https://agentskills.io/) ecosystem.
- **[Principles at work (credo)](https://dev.to/arenukvern/my-principles-at-work-credo-182c)** — ethical AI, care for end users and builders, FAQ-driven documentation, artisan credit.

We need one **public name** that expresses stewardship (care, ethics, governance) rather than “agent fellowship” or “skill kit,” without renaming every internal package in one step.

## Decision Drivers

* **Clarity** — cold readers must understand meta-layer vs product harness vs skill marketplace.
* **Credo alignment** — care, developer-as-user, mechanical quality gates ([credo](https://dev.to/arenukvern/my-principles-at-work-credo-182c), [FAQ-driven docs](https://dev.to/arenukvern/faq-driven-development-or-new-old-way-to-write-docs-rules-prompts-25jl)).
* **Search** — avoid **Skillkit** and crowded **Agent Guild** meanings.
* **Longevity** — anchor on **Skill** (artifact) not **Agent** (diluting over time).
* **Incremental migration** — GitHub repo rename without blocking skill content work.

## Considered Options

* **Keep Agent Guild** — no rename cost; continued confusion.
* **Skill Kit / Skillkit** — rejected; [Skillkit](https://github.com/rohitg00/skillkit) is an established cross-agent package manager.
* **Skill Kata** — memorable for repeatable `SKILL.md` forms; weaker fit for ethics/care/governance (performance metaphor).
* **Skill Colophon** — strong for provenance/docs; less accessible as a product name.
* **Skill Steward** — stewardship of skill quality, docs, and boundaries; distinct from harness and marketplace lanes.

## Decision Outcome

Chosen option: **"Skill Steward"** as the **public product name**, with GitHub repository **`Arenukvern/skill_steward`** and install path **`npx skills add arenukvern/skill_steward`**.

**Tagline (canonical):** *Meta skills for the Agent Skills ecosystem — validate, govern, document.*

### Consequences

* Good, because the name matches [ADR 0001](0001-repository-purpose-as-skills-meta-layer.md) intent (meta-layer) and the maintainer credo.
* Good, because it pairs naturally with **mcp_flutter** (runtime harness) in public bios and README without a third “guild” narrative.
* Neutral, because **historical** ADRs and ADR titles may still say “Agent Guild”; consumer-facing copy uses Skill Steward ([ADR 0008](0008-adopt-skill-steward-product-name.md)).
* Neutral, because ADR filenames and historical “guild” wording in older ADRs remain for traceability.

### Follow-up

| Item | Action |
|------|--------|
| Public surfaces | Done — `docs.json`, skills.sh, install footers, docs.page slug |
| Meta harness CLI | Done — `packages/steward_cli`, `steward validate` / `steward list`, `steward-validate-on-save` |
| ADR 0001 title | Historical; superseded in meaning by this ADR for **naming** only |

## Links

* [North Star](../NORTH_STAR.md)
* [GitHub profile copy](../GITHUB_PROFILE.md)
* [ADR 0001 — meta-layer purpose](0001-repository-purpose-as-skills-meta-layer.md)
