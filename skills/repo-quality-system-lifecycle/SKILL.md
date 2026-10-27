---
name: repo-quality-system-lifecycle
description: >-
  For adopt/baseline, stewardship quality-contract audits, evidence and maturity proof, producer/consumer boundaries, repo ecology compress/merge/retire, and claim-honesty reviews.
  Not for ADR/FAQ-only governance, harness generalization after baseline, release CI, skill packaging, or routine product repairs with a known native gate.
license: MIT
type: governance
metadata:
  author: skill-steward
  version: "1.0.0"
  category: governance
---



# Repo Quality System Lifecycle

## Concept bridge

Load digests in `references/` when the docs tree is absent: stewardship-loop, evolutionary-simplicity, generational-architecture-ladder. Full essays on docs.page.

Use this skill to make a repository legible, safe, and improvable for humans and agents. It is broader than Agent Skill authoring and narrower than product implementation.

Ordinary work: [work discipline](references/work-discipline.md). Do not restate it. `steward adopt` writes the full procedure into a new `AGENTS.md`.

## When to use

- Setting up Engineering Stewardship in an app, library, CLI/tool, plugin, harness, or meta repo.
- Auditing whether a repo has enough charter, docs, decisions, validation, evidence, and safety metadata for agents to work without hidden local context.
- Designing a repo quality contract before adding harness actions, diagnostics, or automation.
- Separating repo stewardship proof from product runtime correctness.
- Auditing a multi-repo integration chain where one repo must publish, tag, or stabilize before a consumer repo can truthfully cut over.
- Deciding whether repeated repo friction should stay native, become docs/FAQ, become an API/schema/generator, become harness proof, or be deleted/collapsed.
- Auditing broad product claims such as platform support, compatibility, maturity, or "works everywhere" language against live evidence and owner boundaries.
- Running a repository ecology review over plans, specs, docs, skills, schemas, tools, evidence, and validation surfaces to choose explicit dispositions.

## When not to use

- Writing product/domain features directly; use the repo's native stack and product skills.
- Creating or packaging an Agent Skill; use `skill-authoring-lifecycle`.
- Maintaining a `steward.yaml` action contract, probes, benchmarks, or CLI/MCP parity after the baseline exists; use `harness-engineering-lifecycle`.
- Generalizing a proven harness across producer/consumer repos; use `harness-engineering-lifecycle`.

## Workflow

### Entry: choose the needed depth

Identify the original goal, owning surface, and native gate from the existing
agent map. If a routine repair has a clear owner and gate, leave native: complete
the repair and validation, then stop. Do not establish a new baseline, ledger,
contract, or maturity review for that task.

For recurring friction, read only the workflow section that owns it. Run the
full ecology review when the user requests it or the owner remains unclear.
Related skills are routing options, not a checklist of skills to load. Reuse
current session context; reopen sources when they changed or a claim needs it.

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
| Research/experiment | Experiment log, oracle, and metric | Held-out trial with falsifier; repo owns runner—Steward summarizes verdict only |

### 2. Establish the stewardship baseline

A baseline is not a giant docs rewrite. It is the minimum map a fresh agent needs.

- Charter or North Star: what the repo is, is not, and optimizes for.
- Agent map: where an agent starts and what it must not bloat.
- Claims and evidence router: ADR for decisions, FAQ/docs for standing guidance, checks/tools/tests for deterministic drift, current ledger for weakest true status, evidence for real proof or blocked proof, delete completed plans after extraction.
- Docs map: canonical owner for why, how, specs, decisions, behavior, and procedures.
- Behavior SSOT: code, schemas, tests, or generated artifacts that docs link to.
- Validation command: one native command or truthful blocked state.
- Release path: changelog/version/artifact provenance, even if immature.

If the repo is not ready for Steward CLI, bootstrap manually: add the claim/evidence router and `north_star_impact` prompt to `AGENTS.md`, name the native validation command, and create `docs/evidence/current-status.mdx` only when a current claim or blocker needs a durable pointer. If the repo has Steward CLI, `steward adopt` creates the local agent map with that North Star impact habit, and `steward evidence init --minimal` creates that ledger without adding harness machinery.

### 3. Define the quality contract

Write the smallest contract that can be checked. For shipping archetypes (`app`, `library`, `cli_tool`, `plugin`, `harness`), `steward adopt` sets `moe_required_for_architecture: false`. Only `meta_governance` defaults it on. `steward doctor` is health inventory; the recorded native validate command is the delivery gate.

Adoption follows [work discipline](references/work-discipline.md). Do not add a loop-doctor action to enforce it.

| Contract area | Required question |
|---------------|-------------------|
| Quality gate | What command proves the repo's native quality claim? |
| Evidence | Where does output, summary, or blocked state persist, and is it current, historical, superseded, template, or retired? |
| Decisions | When does a change require an ADR or FAQ update? |
| Safety | What actions read, write, touch network/secrets, or need confirmation? |
| Handoff | What context lets another agent resume without re-spelunking? |
| Feedback | How do repeated failures become durable tests, docs, evals, or actions? |
| Pattern layer | Should this change live in native code, repo grammar, public API, schema/codegen, harness, ecology-level skill/tooling, or deletion? |
| Product claims | Which claims are implemented, generated, fallback, planned, or speculative, and who owns the proof? |
| Product impact | Did the work change or directly prove the repo's primary artifact: runtime behavior, public API, command output, plugin install behavior, visual output, performance, release path, or user/developer workflow? |
| North Star impact | Is the change `none`, `applies`, `clarifies`, `sub_star`, `amends`, or `conflicts`; and is it a mechanism or a new center? |

Multi-repo cutover: load [multi-repo.md](references/multi-repo.md) when producer publish gates consumer proof.

Use [Repo quality contracts](https://docs.page/arenukvern/skill_steward/repo-quality-contracts) as the normative spec. Product acceleration and experiment campaigns: [product-impact.md](references/product-impact.md).


### 4. Run the generational architecture check

Before adding automation, splitting a surface, compressing navigation, or creating a new abstraction, apply evolutionary simplicity. Decide whether this surface should split, compress, promote, demote, delete, or stay native.

Then ask the Skeptic questions (see evolutionary-simplicity digest): repeated friction?, native fix?, delete option?, falsifier?


Use [evolutionary simplicity](references/evolutionary-simplicity.md) ([full](https://docs.page/arenukvern/skill_steward/core/evolutionary-simplicity)) for the parent movement rule and the [generational architecture ladder](references/generational-architecture-ladder.md) ([full](https://docs.page/arenukvern/skill_steward/core/generational-architecture-ladder)) for the architecture stage model. Higher layers are not automatically better; mature stewardship can move down the ladder.

If the check promotes a layer or changes durable policy, record a Pattern Promotion Review (see generational architecture digest).

### 5. Prove the claim honestly

Use the weakest true claim, not the strongest desired one.

| Claim | Evidence |
|-------|----------|
| Stewardship baseline exists | Charter, agent map, docs map, validation command are discoverable |
| Quality contract is proven | Type-native gate runs or blocked state is documented |
| Skill routing is covered | `pnpm run eval` plus T1 behavior-critical cases |
| Harness readiness is proven | `doctor`, `actions list`, `action inspect`, `probe`, benchmark scenario |
| Fresh-agent workflow is proven | Fresh agent completes one workflow without hidden context |

Before using machine-readable CLI output as evidence, run `steward schema check-outputs --json` in the owning repo when available. This catches schema/JSON drift; it does not prove runtime behavior or maturity by itself.

For broad compatibility or maturity claims, use the claim-audit table in [repo-quality-contracts](https://docs.page/arenukvern/skill_steward/repo-quality-contracts).

Skipped validation, blocked generators, blocked benchmarks, and manually synced generated files are useful notes, not readiness proof.

### 6. Promote repeated learning

See friction→artifact routing in [ecology-review.md](references/ecology-review.md#promote-repeated-learning).

### 7. Repository ecology

Load [ecology-review.md](references/ecology-review.md) when the user asks what to compress, merge, retire, or move to checks—not for routine product repairs. Ecology passes apply the anti-bureaucracy gate defined there.


## Output contract

Report: archetype, weakest true maturity claim, missing contract blockers, boldest useful next step, ecology dispositions (if ecology), product-impact verdict (if product claim), validation result, and non-claims. Routine repairs: goal, disposition, native gate, result only.

  stewardship support only.
- Ecology dispositions when the request is about compression, cleanup, or surface changes.
- What was not validated.
- Any skipped generators, blocked checks, or non-claims behind broad product language.

For normal implementation tasks, the shorter output is enough: original goal, chosen disposition, native gate, boldest useful change or reason to leave native/stop, validation result, and the hot-path residue left for future agents.

## Install

```bash
npx skills add arenukvern/skill_steward --skill repo-quality-system-lifecycle
```

## Sources

See [references/sources.md](references/sources.md).
