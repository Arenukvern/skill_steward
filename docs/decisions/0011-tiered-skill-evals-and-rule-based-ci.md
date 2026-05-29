---
status: accepted
date: 2026-05-29
decision-makers: Skill Steward maintainers
consulted:
informed:
---

# Tiered skill evals and rule-based CI

## Context and Problem Statement

Skill Steward needs **measurable** skill quality without pretending markdown-only CI can score full agent sessions. Industry practice (Google Chrome evals course, Microsoft SkillOpt, Codex plugin-eval) separates **objective gates**, **human/LLM behavioral suites**, and **text optimization loops**.

How much automation belongs in this meta repo?

## Decision Drivers

* **Agent heterogeneity** — Skills run in Cursor, Claude Code, Codex, etc.; no single CI agent is canonical.
* **Cost & flake** — LLM judges in PR CI are expensive and non-reproducible.
* **Charter risk** — Tier-1 skills (`north-star-governance`, `create-skill`, …) need stronger gates than utility skills.
* **Legibility** — Eval cases live in git (`evals/cases/*.yaml`), like changesets for releases.
* **Existing skill** — `skill-eval-improve` already defines layers 0–4; this ADR makes tiers and L0–L1 CI normative.

## Considered Options

* **Manual only** — `references/evals.md`; no CI (status quo).
* **Full agent matrix in CI** — Nightly Cursor/SDK runs + judge (high cost).
* **Tiered rule-based CI + optional human/LLM offline** — Chrome-style objective checks in `scripts/eval-skill.mjs`; behavioral suites documented, not gated in CI.

## Decision Outcome

Chosen: **Tiered rule-based CI + offline behavioral evals.**

| Tier | Skills | CI (`pnpm run eval`) | Offline (maintainer) |
|------|--------|----------------------|----------------------|
| **1 — Behavioral** | `north-star-governance`, `harness-engineering-culture`, `mcp-harness-repo-maintainer`, `create-skill` | ≥2 `evals/cases/*.yaml`; schema + static rules | `references/evals.md`, held-out prompts, plugin-eval, SkillOpt loop |
| **2 — Structural** | All other marketplace skills | `pnpm run validate` only | Optional `evals.md` when behavior-critical |

**CI scope (explicit non-goals):** No LLM judge in CI. No claim that rule-based routing simulation equals production agent routing.

**Schema:** `skills/skill-eval-improve/references/eval-case-schema.md` — versioned case files under `skills/{name}/evals/cases/`.

### Consequences

* Good, because PRs catch missing eval fixtures and description/body drift on charter skills.
* Good, because Chrome/Microsoft patterns are teachable without over-building.
* Bad, because Tier-1 can pass CI while still failing real agent sessions (mitigate with offline layer 2–3).
* Neutral, because Tier-2 skills remain validate-only until promoted.

### Confirmation

* `scripts/eval-skill.mjs` in CI after `pnpm run validate`.
* [docs/STANDARDS.md](../STANDARDS.md) documents tiers.
* `skill-eval-improve` v1.1+ references Chrome eval design.

## More Information

* [Chrome — Design evaluations](https://developer.chrome.com/docs/ai/evals/design)
* [SkillOpt](https://microsoft.github.io/SkillOpt/)
* Skill: `skill-eval-improve`
