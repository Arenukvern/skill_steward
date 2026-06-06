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

For multi-repo roadmaps, also record dependency order, source-of-truth repo, consumer gate, dirty-state policy, and do-not-touch exceptions. Do not claim a downstream consumer is ready from local path dependency success when the upstream package or binary still lacks publish evidence.

Use [docs/repo-quality-contracts.mdx](../../docs/repo-quality-contracts.mdx) as the normative spec.

### 4. Prove the claim honestly

Use the weakest true claim, not the strongest desired one.

| Claim | Evidence |
|-------|----------|
| Stewardship baseline exists | Charter, agent map, docs map, validation command are discoverable |
| Quality contract is proven | Type-native gate runs or blocked state is documented |
| Skill routing is covered | `pnpm run eval` plus Tier-1 cases |
| Harness readiness is proven | `doctor`, `actions list`, `action inspect`, `probe`, benchmark scenario |
| Fresh-agent workflow is proven | Fresh agent completes one workflow without hidden context |

### 5. Promote repeated learning

If an agent discovers friction, do not immediately create permanent automation. First decide the durable artifact.

| Repeated friction | Promote to |
|-------------------|------------|
| Ambiguous direction | ADR, DESIGN FAQ, North Star clarification |
| Repeated command confusion | DX FAQ, script, validation error message |
| Hidden local context | AGENTS map, docs map, concept doc |
| Risky manual action | Typed action candidate with effects, limits, redaction, owner |
| Unclear skill activation | Eval case and skill description change |
| Runtime blind spot | Harness probe, benchmark scenario, unknown case |

## Output contract

When reporting an audit or adoption pass, include:

- Repo archetype and primary artifact.
- Current maturity stage (`S0`-`S5`) and evidence.
- Missing contract areas.
- Smallest next improvement.
- What was not validated.

## Install

```bash
npx skills add arenukvern/skill_steward --skill repo-quality-system-lifecycle
```

## Sources

See [references/sources.md](references/sources.md).
