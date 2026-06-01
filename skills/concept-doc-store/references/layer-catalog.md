# Layer catalog

Pick layers minimal for your repo. Delete unused layers from the router table.

## Router (`docs_map`)

**Purpose:** Zero-content navigation — only “I want to…” → link.

**Update when:** New top-level doc area added.

## Charter (`NORTH_STAR` / `why_this_repo_matters`)

**Purpose:** Why the product exists; what it owns; what it explicitly does **not** own.

**Update when:** Scope or positioning changes.

**Not:** API reference, changelog detail.

## Decisions (`docs/decisions/`)

**Purpose:** Durable **why** for codebase shape. Short ADRs, append-only.

**Update when:** Architecturally significant choice.

**Not:** How to call an API (→ DX_FAQ / examples).

## Concepts (`docs/core/*_architecture`, boundaries)

**Purpose:** Mental model — components, flows, invariants for humans **and** agents making design judgments.

**Update when:** Boundaries or major flows change.

**Not:** Duplicating source; use diagrams + links to packages.

## Agent ops (`docs/ai_agents/`, `AGENTS.md`)

**Purpose:** How agents should install, verify, and operate in this repo.

**Update when:** Init paths, gates, or agent-specific troubleshooting changes.

## Programs (`docs/superpowers/`)

**Purpose:** Multi-phase work with **spec** + **tracker** + **closure** discipline.

**Update when:** Starting or closing a program phase.

**Not:** General product docs.

## Skills (`skills/`, `.cursor/skills/`)

**Purpose:** Bounded procedures (“audit boundary”, “update FAQ”, “dogfood iteration”).

**Update when:** Procedure steps change.

**Not:** Replacing ADRs or architecture pages.

## Examples & tests

**Purpose:** **Behavior SSOT** — the “how it works” the user asked not to duplicate in prose.

**Update when:** Behavior changes — **before** updating concept docs.

## Package FAQs (optional)

**Purpose:** Compressed per-package why/how — see `faq-driven-docs` skill.

**Placement:** Next to package root (`DESIGN_FAQ.mdx` / `.md`, `DX_FAQ.mdx` / `.md`).
