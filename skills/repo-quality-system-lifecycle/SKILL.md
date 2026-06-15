---
name: repo-quality-system-lifecycle
description: Establish or audit a structural quality contract for any agent-operated engineering repository: app, library, CLI/tool, plugin, harness, or meta repo. Use when a repo needs charter clarity, docs/decision ownership, type-native validation gates, evidence paths, safe action policy, cold-start legibility, maturity proof, repair-loop routing, consumer/producer owner-boundary routing, or a repo ecology pass to decide what should be compressed, merged, removed, updated, created, retired, or moved to checks.
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
- Running a repository ecology review over plans, specs, docs, skills, schemas, tools, evidence, and validation surfaces to choose explicit dispositions.

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
- Claims and evidence router: ADR for decisions, FAQ/docs for standing guidance, checks/tools/tests for deterministic drift, current ledger for weakest true status, evidence for real proof or blocked proof, delete completed plans after extraction.
- Docs map: canonical owner for why, how, specs, decisions, behavior, and procedures.
- Behavior SSOT: code, schemas, tests, or generated artifacts that docs link to.
- Validation command: one native command or truthful blocked state.
- Release path: changelog/version/artifact provenance, even if immature.

If the repo is not ready for Steward CLI, bootstrap manually: add the claim/evidence router and `north_star_impact` prompt to `AGENTS.md`, name the native validation command, and create `docs/evidence/current-status.mdx` only when a current claim or blocker needs a durable pointer. If the repo has Steward CLI, `steward adopt` creates the local agent map with that North Star impact habit, and `steward evidence init --minimal` creates that ledger without adding harness machinery.

### 3. Define the quality contract

Write the smallest contract that can be checked.

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

For multi-repo roadmaps, also record dependency order, source-of-truth repo, consumer gate, dirty-state policy, and do-not-touch exceptions. Do not claim a downstream consumer is ready from local path dependency success when the upstream package or binary still lacks publish evidence. The producer repo owns architecture, public contract, release provenance, and compatibility claims; consumer repos own adoption proof, local deltas, blocked state, and cutover commands.

Use [docs/repo-quality-contracts.mdx](../../docs/repo-quality-contracts.mdx) as the normative spec.

For product repos, do not count Steward activity as product acceleration unless
it lands in the owner checkout as either a source-owned product delta or a
product-native proof. Examples: a changed Flutter interaction, a public API or
adapter contract, a CLI output/failure mode, a plugin install path, a real
visual screenshot, a performance metric, or a release/publish preflight. If the
only result is a cleaner ledger, eval, action contract, or proof tool, the honest
claim is stewardship maintenance, orientation, or harness candidate, not product
progress. For visual/performance-heavy repos, tests are support evidence; the
claim ceiling stays low until a human-inspectable capture or metric proves the
product surface moved.

For visual, shader, renderer, loader, or performance tasks, route to the
product-native experiment loop before Steward work. The product repo owns the
variant runner, browser/server orchestration, image oracle, screenshots, videos,
and performance metrics. Steward may summarize the winning campaign through an
`experiment-campaign-summary/v1` artifact, block false claims, and record
non-claims. It must not become the inner loop. If two Steward detours fail to
improve the product metric, stop Steward work and return to native experiments.
Parallel lanes should test independent product hypotheses, not evidence
paperwork.

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
| Skill routing is covered | `pnpm run eval` plus T1 behavior-critical cases |
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

### 7. Run a repository ecology review

Use this when the user asks what should be compressed, changed, merged, removed, updated, created, retired, or moved into checks. Dogfood or benchmark evidence may be relevant, but it is not required for every ecology pass.

Inspect the repo ecology surfaces that matter for the request:

- Plans and specs: in-flight, implemented, stale, or extracted.
- Docs and maps: canonical owner, duplicated truth, stale proof, or missing links.
- ADRs and FAQs: durable decisions versus standing why/how.
- Skills and evals: activation clarity, overlap, missing cases, or bloat.
- Schemas and generated artifacts: machine-readable drift and behavior SSOT.
- CLI/MCP/tools: deterministic checks, JSON shape, and bounded effects.
- Evidence: current proof, historical proof, superseded proof, templates, blocked evidence, current-status pointers, next disposition, and non-claims.

Loop smells to name before creating another artifact: a third evidence note or packet for the same blocker, repeated blocker proof, a tool tunnel, stale proof loop, repair replacing the original goal, or status artifacts multiplying faster than fixes.

Prefer a single disposition table over a new doctrine page:

| Surface | Current owner | Signal | Disposition | Destination | Evidence/gate | Non-claim |
|---------|---------------|--------|-------------|-------------|---------------|-----------|
| `path/or/surface` | canonical owner or unknown | duplicated/stale/missing/repeated | keep/merge/update/remove/create/defer/move to check | ADR/FAQ/skill/check/evidence/native | command, eval, benchmark, blocked state, or none | stronger claim not proven |

Use these disposition meanings:

- `keep`: current canonical owner is still right.
- `compress`: reduce duplicated prose while preserving the owner.
- `merge`: move remaining truth into another live surface.
- `update`: current owner is right but stale.
- `remove`: content is implemented, stale, duplicated, or no longer useful after extraction.
- `create`: a missing surface is justified by repeated friction or proof needs.
- `defer`: the signal is real but not ready for a durable surface.
- `move to ADR`: the durable value is a decision or trade-off.
- `move to FAQ`: the durable value is standing why/how guidance.
- `move to skill`: the durable value is repeatable agent procedure.
- `move to check`: deterministic drift or freshness should fail mechanically.
- `move to evidence`: a real run should be preserved with proof and non-claims.
- `move to consumer proof`: this repo owns local adoption proof, not producer architecture.
- `leave native`: the repo's language, framework, or product command is the right layer.

When `steward ecology snapshot --json` is available, use it as inventory only. The snapshot can reduce tedious state gathering, but it does not award maturity, adoption, H2/H5, or steward status.

When `steward ecology route --json` emits `dispatch_lane_candidates`, treat them as disposable advisory hints derived from the same route facts. They are not write authorization, action candidates, backlog items, parent lane contracts, maturity evidence, or scheduler state. Use them only to make repo-wide pain legible for a parent agent, then assign real work through `multi-agent-handoff` or delete the scaffolding after synthesis. Do not generate or trust lane candidates from `leave_native`.

For evidence surfaces, apply the envelope in [docs/core/evidence-artifacts.mdx](../../docs/core/evidence-artifacts.mdx). Prefer `move to check` over `move to evidence` when the same deterministic drift will recur; prefer a current ledger over many historical notes when the reader only needs the present weakest true claim.

When proof includes maintainer-local paths, temp replays, or one workstation's setup, keep that context in the current ledger or historical evidence and label it as maintainer-local. Create or update a public reproducibility card only when a public reader needs to audit the claim from durable anchors: public repo URL, fetchable commit SHA, portable command, and artifact hash or CI artifact name.

Run ecology as a disposition loop, not an evidence treadmill or a tool tunnel:

- Prefer `orient`, `compress`, `validate`, `tutor_pain`, `promote_tool`, `leave_native`, or `stop` before creating any new artifact.
- When a proposed mechanism starts acting like the umbrella, classify `north_star_impact`. `sub_star` needs a parent/child boundary; `amends` or `conflicts` needs governance and an ADR before product direction changes.
- When the review finds invalid config, dirty declared inputs, schema/output drift, blocked payload routing, stale navigation, or a broken native gate, update the owning surface and rerun the same gate when that is the smallest safe disposition.
- For `tutor_pain`, name the pain signal, owner, native gate, smallest disposition, rerun route, hot-path residue, and non-claim.
- For product repos, name the product impact check before adding or trusting
  Steward proof. If no product-native behavior, API, UI/visual, performance,
  release, or workflow surface changed or was directly proven, downgrade the
  outcome to stewardship support and return to the product owner surface.
- For experiment campaigns, require a product-owned oracle/capture/metric before
  any product-acceleration claim. Summaries with only Steward docs, schemas,
  evals, or harness changes are `support_only: true`.
- After two learning loops on the same friction, stop PDSA and produce a disposition table. Extract the durable lesson into ADR, FAQ, skill, check, CLI diagnostic, or current ledger, then delete/retire duplicate plans or historical packets from active navigation.
- Do not add sub-stewards, new broad skills, new benchmark scenarios, or new evidence indices from the same blocked detour unless the repaired owner still cannot represent the repo honestly.

## Output contract

When reporting an audit or adoption pass, include:

- Repo archetype and primary artifact.
- Current maturity stage (`S0`-`S5`) and evidence for audits, adoption claims, or readiness claims.
- Missing contract areas when they block the requested work or a claim.
- Pattern layer chosen, smaller layer considered, and expected maintenance delta.
- `north_star_impact` when the work could alter the repo center, ownership, or refusal boundaries.
- Smallest next improvement.
- Product impact check and product delta, or the explicit reason the work is
  stewardship support only.
- Ecology dispositions when the request is about compression, cleanup, or surface changes.
- What was not validated.
- Any skipped generators, blocked checks, or non-claims behind broad product language.

For normal implementation tasks, the shorter output is enough: original goal, chosen disposition, native gate, smallest change or reason to leave native/stop, validation result, and the hot-path residue left for future agents.

## Install

```bash
npx skills add arenukvern/skill_steward --skill repo-quality-system-lifecycle
```

## Sources

See [references/sources.md](references/sources.md).
