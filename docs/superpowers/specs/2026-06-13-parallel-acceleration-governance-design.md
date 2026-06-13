# Parallel Acceleration Governance Design

Date: 2026-06-13

## Purpose

Clarify Skill Steward governance so it accelerates repo-wide work instead of turning into a serial brake. The North Star already says useful stewardship turns cold exploration into hot paths for future agents with the same or stronger proof bar. This design makes the missing implication explicit:

> Governance is successful when it lets many agents move faster without losing truth, ownership, or proof.

The change does not move the repository center. It clarifies how the existing North Star should behave when modern agent execution can dispatch many independent agents at once.

Skill Steward should not become its own agentic behavior framework. Coding agents and hosts may coordinate with batches, graphs, queues, trees, A2A handoffs, A2Human checkpoints, worktrees, reviewers, or custom prompts. Steward's role is to teach agents how to address repository pain with the tools they already have, and to provide repo-local tools, contracts, checks, and evidence boundaries that make that work reproducible.

## Problem

Existing stewardship language can be misread as caution-first. In particular, "smallest useful disposition" can drift into "smallest action" or "one next step." That interpretation becomes wrong when the pain is repo-wide and many agents can work in parallel.

The real failure mode is not too many agents. The failure mode is unclear decomposition: agents without owner boundaries, acceptance checks, validation gates, evidence boundaries, or parent synthesis.

The parent synthesis step is especially important. The parent must be able to compare lane results, reject out-of-scope edits, resolve conflicts, run aggregate gates, size the final claim, and promote repeated verification into a hot path when the same comparison or proof work will recur.

## Design Principle

"Smallest useful disposition" should mean the smallest truthful coordination unit, not the smallest amount of work.

If the pain is local, the right coordination unit may be one fix, FAQ row, validation command, or evidence update. If the pain is repo-wide, the right unit may be a disposable execution map that supports 2, 20, 200, or more agents. The parent agent chooses batch size based on task shape, available execution capacity, independence, risk, and integration cost. Skill Steward should not impose a numeric cap.

Raw agent count is never usefulness proof. Use as many independent lanes as can be assigned, reviewed, integrated, and validated without losing ownership or claim honesty.

## Dispatch Lane Candidates

A dispatch lane candidate is temporary execution scaffolding for possible parallel work. It is not a durable governance artifact, backlog, or write authorization. It should disappear after integration unless a specific lesson earns a durable owner.

Each lane candidate must declare:

- `lane_id`: stable identifier for this batch only.
- `owner`: file, doc, package, command, skill, module, or surface that owns truth.
- `owner_update_route`: where durable changes should land if the lane succeeds.
- `scope`: where the agent may act.
- `write_set`: exact files or surfaces the worker may edit, if any.
- `forbidden_paths`: files or surfaces the worker must not touch.
- `dependencies`: other lanes, commands, or external states that must happen first.
- `allowed_action`: `explore`, `fix`, `implement`, `verify`, `compress`, `promote`, or `stop`.
- `direct_fix_allowed`: whether this lane may make changes directly.
- `risk_class`: expected change risk, for example `low`, `medium`, `high`, or `unknown`.
- `acceptance_check`: what proves the lane is done.
- `native_gate`: command, test, schema check, eval, benchmark, or blocked state.
- `claim_ceiling`: strongest claim the lane result can support.
- `non_claims`: adjacent stronger claims not proven.
- `retention`: lane map retention rule, normally `delete_after_integration`.
- `integration_rule`: how the parent agent accepts, merges, rejects, or escalates the result.

Create only as many lane candidates as are needed to make parallel work legible. Do not create lanes to describe lanes.

## Senior-Agent Lane Rule

Worker lanes may fix, implement, or complete bounded low-impact work directly only when the parent lane contract sets `direct_fix_allowed: true`, the `write_set` is exact, forbidden paths are declared, and validation is available. A worker should not create a recommendation queue when direct completion is safer and faster inside that lane.

The worker must still report:

- files or surfaces changed,
- commands run,
- commands skipped,
- skip reason,
- proof level,
- artifact paths,
- final disposition,
- claim ceiling and non-claims,
- unresolved risks,
- any scope pressure that should return to the parent.

The parent agent remains accountable for synthesis, conflicts, final validation, and final claims.

## Parent Batch Contract

Before dispatching a broad batch, the parent should declare:

- integration capacity: how many lane results it can realistically review and merge.
- conflict policy: how overlapping write sets are rejected, serialized, or escalated.
- merge order: whether results merge independently, by dependency order, or after comparison.
- comparison strategy: whether reviewers, diff tools, generated summaries, schema checks, or Steward commands will compare lane outputs.
- aggregate gates: commands or checks that must run after integration.
- stop condition: what aborts the batch, narrows scope, or returns to the human.
- final evidence boundary: weakest true claim allowed after the batch.
- hot-path promotion check: whether repeated comparison or verification should become a tool, check, eval, benchmark, schema, diagnostic, or skill update.

Parent synthesis should produce a compact table with each lane's terminal state:

- `integrated_to_owner`
- `rejected`
- `blocked_to_current_ledger`
- `promoted_to_durable_owner`
- `deleted`

The parent may dispatch agents to compare implementations, build small comparison tools, or use Steward-style verification in the hot step. New tooling is appropriate when it makes future changes reproducible and verifiable, not when it merely records that many agents were used.

## Agent Coordination Boundary

Steward should stay agnostic about the coordination algorithm. It can support:

- A2A work, where agents pass evidence, diffs, and critiques to each other.
- A2Human checkpoints, where a human chooses between lanes, approves risky write sets, or resolves product intent.
- Graph-shaped workflows, where exploration, implementation, review, validation, and promotion nodes run in parallel or dependency order.

Skill Steward should provide the vocabulary, lane candidate contract, validation hooks, evidence boundaries, and optional CLI hints. It should not prescribe a universal scheduler, hierarchy, or custom multi-agent framework.

## Durable Integration

This should not become a new standalone skill yet. Existing surfaces should change behavior:

- `docs/NORTH_STAR.mdx`: add the acceleration rule and clarify that governance enables parallel action with proof.
- `docs/decisions/0025-parallel-acceleration-governance.mdx`: record the decision and the rejected serial-brake failure mode.
- `skills/repo-quality-system-lifecycle/SKILL.md`: allow repository ecology review to emit disposable execution lane candidates when pain is repo-wide.
- `skills/multi-agent-handoff/SKILL.md`: support parallel batch contracts and the senior-agent lane rule.
- `skills/mixture-of-experts/SKILL.md`: use MoE for lane discovery, contradiction detection, and evidence-boundary critique before or during large batches.
- `packages/steward_cli/lib/src/commands/ecology_command.dart`: extend `steward ecology route --json` with optional advisory `dispatch_lane_candidates`.
- `docs/schemas/ecology-route-v1.schema.json` and tests: preserve the JSON contract if CLI output changes.

## CLI Shape

`steward ecology route --json` should remain non-mutating and advisory. It may infer lane candidate hints from existing ecology route facts such as invalid config, schema drift, active plan candidates, stale evidence, dirty state, and missing actions.

The output must not award maturity, adoption, or health. It should describe possible work lane candidates and their boundaries.

The field should be named `dispatch_lane_candidates`, not `dispatch_lanes`, and every candidate should be marked:

- `advisory: true`
- `ephemeral: true`
- `requires_parent_assignment: true`
- `not_write_authorization: true`
- `retention: delete_after_integration`

Candidate fields:

- `lane_id`
- `pain_signal`
- `owner`
- `owner_update_route`
- `scope`
- `write_set`
- `forbidden_paths`
- `dependencies`
- `allowed_action`
- `direct_fix_allowed`
- `risk_class`
- `acceptance_check`
- `native_gate`
- `claim_ceiling`
- `non_claims`
- `integration_rule`

Existing dispositions remain canonical: `orient`, `compress`, `validate`, `tutor_pain`, `promote_tool`, `leave_native`, and `stop`. Lane actions are subordinate execution modes. No lane candidate should be generated from `leave_native`.

Because `ecology-route-v1.schema.json` is contract-sensitive, implementation should either make a carefully documented additive v1 schema expansion or move to a route v2 if the shape becomes too large for v1.

## Anti-Bureaucracy Rules

Lane maps are disposable. After a batch finishes:

- successful fixes land in code, docs, tests, tools, schemas, or skills;
- repeated lessons promote to the appropriate durable owner;
- blocked facts go to a current ledger or evidence artifact only when useful;
- stale lane maps disappear.

Do not preserve lane maps as permanent project management artifacts. Do not create a new broad "parallel acceleration" skill until repeated real use proves existing skills cannot carry the behavior.

This design spec is also disposable. After implementation, durable truth should live in the North Star, ADR, skills, CLI/schema/tests, and any necessary current ledger or evidence artifact. The spec should then be deleted or explicitly retired so it does not become permanent governance clutter.

## Validation

Implementation should run the repo's native validation after changes:

- `pnpm run validate`
- `pnpm run eval`
- `pnpm run docs:check`
- `steward ecology route --json`

If CLI JSON changes, implementation should also run the Dart package tests that cover ecology route payloads and schema conformance.

## Success Criteria

After implementation:

- North Star clearly says governance must accelerate many agents without losing truth, ownership, or proof.
- The ADR records why serial governance is rejected.
- Repo-quality review can route repo-wide pain into disposable execution lane candidates.
- Multi-agent handoff supports parallel execution, parent synthesis, and direct bounded fixes by worker agents.
- MoE can discover lanes and contradictions without turning into another doctrine.
- Ecology route can provide advisory dispatch hints without becoming a verdict.
- Parent synthesis can compare, integrate, validate, and promote reproducible hot-path tooling when earned.
- Steward remains agnostic about host agent coordination algorithms, including A2A, A2Human, and graph-shaped workflows.
- No new standalone skill or permanent lane artifact is introduced.
