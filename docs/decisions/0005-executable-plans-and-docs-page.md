---
status: accepted
date: 2026-05-29
decision-makers: Agent Guild maintainers
consulted:
informed:
---

# Executable plans and docs.page publishing

## Context and Problem Statement

Agent Guild needs a published documentation site (like [mcp_flutter on docs.page](https://docs.page)) and a clear rule for **plans, todos, and roadmaps**: they are executable work orders, not permanent repo knowledge. Stale plans poison agent context (same failure mode as a 1,000-line `AGENTS.md`).

**What site structure and plan lifecycle do we adopt?**

## Decision Drivers

* **Agent map** — `AGENTS.md` stays short; deep docs live under `docs/`.
* **North Star** — single charter file agents and humans read first.
* **docs.page** — standard publishing via root `docs.json` + `docs/` MDX/Markdown.
* **Harness alignment** — [OpenAI harness engineering](https://openai.com/index/harness-engineering/) treats plans as versioned artifacts but expects hygiene; we go further: **completed plans must merge into ADR/docs/code/harness and leave the tree**.
* **Small repo** — no standing `docs/superpowers/` until a real multi-phase program needs it.

## Considered Options

* **Git-only docs** — No docs.page; README + root FAQs only.
* **docs.page + eternal roadmaps** — Published site but plans never deleted.
* **docs.page + ephemeral plans doctrine** — `docs/NORTH_STAR.md`, `docs.json`, executable-plans page, skill `north-star-governance`.
* **Monolithic AGENTS.md** — Rejected per harness article.

## Decision Outcome

Chosen option: **"docs.page + ephemeral plans doctrine"**.

### Publishing

* Root **`docs.json`** configures [docs.page](https://docs.page).
* Canonical charter: **`docs/NORTH_STAR.md`**.
* Agent entry: **`AGENTS.md`** (~100 lines) points to North Star, docs map, skills, validation—no skill-authoring encyclopedia in AGENTS.
* Root `DESIGN_FAQ.md` / `DX_FAQ.md` remain for repo-local and `npx skills` consumers; site indexes them via docs map (GitHub links until duplicated if needed).

### Executable plans

* Plans/todos/roadmaps are **temporary** only.
* On completion → **ADR | FAQ | code | harness (skills/plugins/CLI)**; then **remove** active plan files.
* Documented in `docs/start_here/executable-plans.mdx` and enforced by skill **`north-star-governance`**.

### Consequences

* Good, because agents get a map + charter without context bloat.
* Good, because public docs match mcp_flutter contributor experience.
* Bad, because dual root FAQs + `docs/` need cross-links maintained.
* Neutral, because `arenukvern` placeholder in `docs.json` until GitHub remote is set.

### Confirmation

* `docs.json` committed.
* `docs/NORTH_STAR.md`, `docs/index.mdx`, `docs/start_here/docs_map.mdx`, `docs/start_here/executable-plans.mdx` exist.
* Skill `north-star-governance` shipped.
* `AGENTS.md` trimmed to map role.

## More Information

* [ADR 0003 — concept doc store](0003-concept-doc-store-lattice.md)
* [mcp_flutter docs.json](https://github.com/Arenukvern/mcp_flutter/blob/main/docs.json)
