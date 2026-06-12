---
name: repo-quality-system-lifecycle
description: Establish or audit a structural quality contract for any agent-operated engineering repository: app, library, CLI/tool, plugin, harness, or meta repo. Use when a repo needs charter clarity, docs/decision ownership, type-native validation gates, evidence paths, safe action policy, cold-start legibility, or maturity proof before agents can work reliably.
license: MIT
type: governance
metadata:
  author: skill-steward
  version: "1.0.0"
  category: governance
---

# Repo Quality System Lifecycle

Use this skill to make a repository legible, safe, and improvable for humans and agents. It is broader than Agent Skill authoring and narrower than product implementation.

## When to use

- Setting up Engineering Stewardship in an app, library, CLI/tool, plugin, harness, or meta repo.
- Auditing whether a repo has enough charter, docs, decisions, validation, evidence, and safety metadata for agents to work without hidden local context.
- Designing a repo quality contract before adding harness actions, diagnostics, or automation.
- Separating repo stewardship proof from product runtime correctness.
- Auditing a multi-repo integration chain where one repo must publish, tag, or stabilize before a consumer repo can truthfully cut over.
- Deciding whether repeated repo friction should stay native, become docs/FAQ, become an API/schema/generator, become harness proof, or be deleted/collapsed.
- Auditing broad product claims such as platform support, compatibility, maturity, or "works everywhere" language against live evidence and owner boundaries.

## When not to use

- Writing product/domain features directly; use the repo's native stack and product skills.
- Creating or packaging an Agent Skill; use `skill-authoring-lifecycle`.
- Maintaining a `steward.yaml` action contract, probes, benchmarks, or CLI/MCP parity after the baseline exists; use `mcp-harness-repo-maintainer`.
- Generalizing a proven harness across producer/consumer repos; use `harness-engineering-lifecycle`.

## Workflow

### 1. Classify the repo

Pick one primary archetype. Do not let every repo become a harness repo.

| Archetype | Primary artifact | First proof |
|-----------|------------------|-------------|
| App | Product behavior and runtime | Product validation gate plus debugging path |
| Library | Public API and package contract | Tests, package dry-run, compatibility note |
| CLI/tool | Commands and machine-readable outputs | `--help`, `--json`, golden output or command test |
| Plugin | Host integration | Manifest, permissions, install/rollback note |
| Harness/action contract | Agent-facing action/probe/benchmark | Quick-safe action and benchmark scenario |
| Meta/governance | Skills, docs, policies, validators | Skill validation, eval cases, registry consistency |

### 2. Establish the stewardship baseline

A baseline is not a giant docs rewrite. It is the minimum map a fresh agent needs.

- Charter or North Star: what the repo is, is not, and optimizes for.
- Agent map: where an agent starts and what it must not bloat.
- Docs map: canonical owner for why, how, specs, decisions, behavior, and procedures.
- Behavior SSOT: code, schemas, tests, or generated artifacts that docs link to.
- Validation command: one native command or truthful blocked state.
- Release path: changelog/version/artifact provenance, even if immature.

### 3. Define the quality contract

Write the smallest contract that can be checked.

| Contract area | Required question |
|---------------|-------------------|
| Quality gate | What command proves the repo's native quality claim? |
| Evidence | Where does output, summary, or blocked state persist? |
| Decisions | When does a change require an ADR or FAQ update? |
| Safety | What actions read, write, touch network/secrets, or need confirmation? |
| Handoff | What context lets another agent resume without re-spelunking? |
| Feedback | How do repeated failures become durable tests, docs, evals, or actions? |
| Pattern layer | Should this change live in native code, repo grammar, public API, schema/codegen, harness, ecology-level skill/tooling, or deletion? |
| Product claims | Which claims are implemented, generated, fallback, planned, or speculative, and who owns the proof? |

For multi-repo roadmaps, also record dependency order, source-of-truth repo, consumer gate, dirty-state policy, and do-not-touch exceptions. Do not claim a downstream consumer is ready from local path dependency success when the upstream package or binary still lacks publish evidence. The producer repo owns architecture, public contract, release provenance, and compatibility claims; consumer repos own adoption proof, local deltas, blocked state, and cutover commands.

Use [docs/repo-quality-contracts.mdx](../../docs/repo-quality-contracts.mdx) as the normative spec.

### 4. Run the generational architecture check

Before adding automation or a new abstraction, ask the Skeptic questions:

- Is the friction repeated across agents or workflows, or only from this run?
- Can a language/framework feature, native command, FAQ, validation message, or docs-map row solve it?
- Would deleting, merging, or demoting a layer reduce maintenance without losing proof?
- If codegen is proposed, is the schema smaller and more stable than the generated code?
- If a harness action is proposed, does it help the original task or a named future problem class?
- What falsifier or held-out task will show the promoted layer is stale, wrong, or not useful?

Use [docs/core/generational-architecture-ladder.mdx](../../docs/core/generational-architecture-ladder.mdx) for the stage model. Higher layers are not automatically better; mature stewardship can move down the ladder.

If the check rejects a proposed abstraction, promotes a new layer, updates an existing skill/tool, or changes durable repo policy, record a Pattern Promotion Review under `docs/evidence/pattern-promotion-review-YYYY-MM-DD-topic.mdx`. Keep it as evidence for a real run, not as a new skill or scorecard.

### 5. Prove the claim honestly

Use the weakest true claim, not the strongest desired one.

| Claim | Evidence |
|-------|----------|
| Stewardship baseline exists | Charter, agent map, docs map, validation command are discoverable |
| Quality contract is proven | Type-native gate runs or blocked state is documented |
| Skill routing is covered | `pnpm run eval` plus Tier-1 cases |
| Harness readiness is proven | `doctor`, `actions list`, `action inspect`, `probe`, benchmark scenario |
| Fresh-agent workflow is proven | Fresh agent completes one workflow without hidden context |

Before using machine-readable CLI output as evidence, run `steward schema check-outputs --json` in the owning repo when available. This catches schema/JSON drift; it does not prove runtime behavior or maturity by itself.

For broad compatibility or maturity claims, record a compact claim audit:

| Field | Question |
|-------|----------|
| `claim` | What exact sentence is being claimed? |
| `tier` | Is it `implemented`, `generated`, `fallback`, `planned`, or `speculative`? |
| `owner` | Which repo/package owns the canonical truth? |
| `evidence` | What code, schema, test, source, or benchmark proves only that tier? |
| `validation` | What command, generator, freshness check, source date, or blocked state supports it? |
| `falsifier` | What would prove the claim stale or too broad? |
| `non_claims` | What stronger adjacent claim is not proven? |

Skipped validation, blocked generators, blocked benchmarks, and manually synced generated files are useful notes, not readiness proof.

### 6. Promote repeated learning

If an agent discovers friction, do not immediately create permanent automation. First decide the durable artifact.

| Repeated friction | Promote to |
|-------------------|------------|
| Ambiguous direction | ADR, DESIGN FAQ, North Star clarification |
| Repeated command confusion | DX FAQ, script, validation error message |
| Hidden local context | AGENTS map, docs map, concept doc |
| Repeated structural duplication | Pattern review, public API boundary, package/module split, or deletion |
| Repeated boilerplate | Template, schema, generator, lint rule, or test fixture |
| Risky manual action | Typed action candidate with effects, limits, redaction, owner |
| Unclear skill activation | Eval case and skill description change |
| Runtime blind spot | Harness probe, benchmark scenario, unknown case |
| Stale or overgrown layer | Collapse, demote, or delete after the native gate still passes |

## Output contract

When reporting an audit or adoption pass, include:

- Repo archetype and primary artifact.
- Current maturity stage (`S0`-`S5`) and evidence.
- Missing contract areas.
- Pattern layer chosen, smaller layer considered, and expected maintenance delta.
- Smallest next improvement.
- What was not validated.
- Any skipped generators, blocked checks, or non-claims behind broad product language.

## Install

```bash
npx skills add arenukvern/skill_steward --skill repo-quality-system-lifecycle
```

## Sources

See [references/sources.md](references/sources.md).
