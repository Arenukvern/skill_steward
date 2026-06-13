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

## Existing Pattern Intersections

Parallel acceleration should compose existing stewardship primitives. It should not create a second governance grammar.

| Spec concern | Existing owner | Reuse rule |
|--------------|----------------|------------|
| Cold-to-hot acceleration | North Star and ADR 0018 | Keep the acceleration rule compact; do not create a parallel doctrine page after extraction. |
| Repo-wide pain routing | `repo-quality-system-lifecycle` and ecology dispositions | Lane candidates are subordinate to `orient`, `compress`, `validate`, `tutor_pain`, `promote_tool`, `leave_native`, and `stop`. |
| Parent assignment, write authority, synthesis, and closure | `multi-agent-handoff` | Parent batch contracts live in handoff/scratch context, not CLI route output. |
| Independent critique and lane discovery | `mixture-of-experts` | MoE supplies lenses and contradiction checks; no new parallel-acceleration skill yet. |
| Claim proof and retention | Evidence ladder, evidence artifacts, current ledgers, adoption-run v2 | Preserve evidence only when it protects a claim, blocker, real run, observed effect, or falsifier. |
| Tool/action promotion | Unknown cases and action candidates | Dispatch lanes must not bypass the existing unknown-case to action-candidate review path. |
| Steward mode and self-model | ADR 0025 and `steward-continuity-boundary-lifecycle` | Parallelism may be a steward-presence readiness sign; it is not steward-status proof. |
| CLI inventory and routing | `steward ecology snapshot/route` | Derive advisory lane hints from existing snapshot facts; do not add a persisted scheduler. |

## Design Principle

"Smallest useful disposition" should mean the smallest truthful coordination unit, not the smallest amount of work.

If the pain is local, the right coordination unit may be one fix, FAQ row, validation command, or evidence update. If the pain is repo-wide, the right unit may be a disposable execution map that supports as many independent lanes as the parent can assign, review, integrate, and validate. The parent agent chooses batch size based on task shape, available execution capacity, independence, risk, and integration cost. Skill Steward should not impose a numeric cap.

Raw agent count and raw lane count are never usefulness proof. Use as many independent lanes as can be assigned, reviewed, integrated, and validated without losing ownership or claim honesty.

This design is meant to fix the bureaucracy failure mode, not make it prettier. The failure mode is governance that asks for smaller and smaller motions while repo-wide pain remains unsolved. The countermeasure is stewardship-first execution: name the owner, dispatch the truthful coordination unit, integrate real changes, run native gates, and keep only the evidence needed for a claim or blocker. Evidence is a support surface, not the direction of travel.

## Dispatch Lane Candidates

A dispatch lane candidate is temporary execution scaffolding for possible parallel work. It is not a durable governance artifact, backlog, action candidate, parent lane contract, or write authorization. It should disappear after integration unless a specific lesson earns a durable owner.

There are two related but separate shapes:

- `dispatch_lane_candidate`: an advisory hint, usually emitted by ecology review or `steward ecology route --json`.
- `parent_lane_contract`: a parent-assigned execution contract, usually carried in a handoff, issue, PR summary, or live parent synthesis.

The CLI may emit only `dispatch_lane_candidate`. Parent-assigned execution contracts belong to `multi-agent-handoff`.

Every advisory lane candidate has a minimum shape:

- `lane_id`: stable identifier for this batch only.
- `source_disposition`: the canonical ecology disposition that produced the hint.
- `pain_signal`: observed repo fact that made the lane plausible.
- `owner`: file, doc, package, command, skill, module, or surface that owns truth.
- `scope`: where the agent may act.
- `allowed_action`: subordinate execution mode such as `explore`, `verify`, `compress`, `fix`, `implement`, or `promote`.
- `write_set`: exact files or surfaces that a parent may later consider assigning, or an empty list for read-only candidates.
- `forbidden_paths`: files or surfaces the worker must not touch.
- `acceptance_check`: what proves the lane is done.
- `native_gate`: command, test, schema check, eval, benchmark, or blocked state.
- `suggested_claim_ceiling`: strongest possible claim if a parent assigns the lane and its gate passes.
- `integration_rule`: how the parent agent accepts, merges, rejects, or escalates the result.
- `advisory: true`
- `ephemeral: true`
- `requires_parent_assignment: true`
- `not_write_authorization: true`
- `authorization_source: none`
- `retention: delete_after_integration`

Expanded fields are required for high/unknown-risk or cross-lane-dependent candidates:

- `owner_update_route`: where durable changes should land if the lane succeeds.
- `dependencies`: other lanes, commands, or external states that must happen first.
- `direct_fix_eligible`: whether a parent may consider allowing direct fixes.
- `risk_class`: expected change risk, for example `low`, `medium`, `high`, or `unknown`.
- `non_claims`: adjacent stronger claims not proven.

Create only as many lane candidates as are needed to make parallel work legible. Do not create lanes to describe lanes.

## Senior-Agent Lane Rule

Worker lanes may fix, implement, or complete bounded low-impact work directly only when the parent-assigned lane contract sets `direct_fix_allowed: true`, the `write_set` is exact, forbidden paths are declared, repo safety rules are inherited, required impact checks are satisfied, user permissions are respected, and validation is available. A worker should not create a recommendation queue when direct completion is safer and faster inside that lane.

`direct_fix_allowed` must never appear as authorization in advisory CLI or MCP output. Advisory surfaces may emit `direct_fix_eligible` or `parent_may_allow_direct_fix`; only a parent-assigned lane contract may authorize writes.

Direct fixes are low-risk only unless a human explicitly approves the exception. A direct-fix lane must not change product intent, public schema/API, steward status, self-model status, security posture, release behavior, or overlapping write sets unless the parent contract says so. If required validation is skipped or blocked, the worker result downgrades to `blocked` or `recommendation`, not `integrated_to_owner`.

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

Before dispatching a broad batch, the parent should declare only enough contract to move safely. This is not a new plan format; it is disposable handoff or scratch context. After integration, durable truth moves to code, docs, ADR, skill, check, schema, current ledger, or evidence only when the routing rules already require it.

The parent contract should declare:

- original goal: the user or maintainer outcome the batch serves.
- user acceptance check: what proves the original goal is solved or advanced.
- default native gate: the first product/repo gate to prefer before Steward-specific tooling.
- detour budget: when tool building, comparison tooling, or lane repair must stop and return to the goal.
- integration capacity: how many lane results it can realistically review and merge.
- conflict policy: how overlapping write sets are rejected, serialized, or escalated.
- merge order: whether results merge independently, by dependency order, or after comparison.
- comparison strategy: whether reviewers, diff tools, generated summaries, schema checks, or Steward commands will compare lane outputs.
- aggregate gates: commands or checks that must run after integration.
- aggregate skipped-gate reporting: skipped commands, skip reasons, and claims blocked by skipped validation.
- stop condition: what aborts the batch, narrows scope, or returns to the human.
- final evidence boundary: weakest true claim allowed after the batch.
- hot-path promotion check: whether repeated comparison or verification should become a tool, check, eval, benchmark, schema, diagnostic, or skill update.

Parent synthesis should produce a compact record before any acceleration claim:

- original user goal and acceptance check,
- parent lane assignments,
- lane terminal states,
- conflicts rejected or merged,
- aggregate gates run,
- aggregate gates skipped with reasons,
- final weakest true claim,
- unioned non-claims,
- current-ledger or evidence route,
- observed effect,
- maintenance delta,
- falsifier.

It should also include a compact table with each lane's terminal state:

- `integrated_to_owner`
- `rejected`
- `blocked_to_current_ledger`
- `promoted_to_durable_owner`
- `deleted`

The parent may dispatch agents to compare implementations, build small comparison tools, or use Steward-style verification in the hot step. New tooling is appropriate when it makes future changes reproducible and verifiable, not when it merely records that many agents were used.

Hot-path promotion requires more than a successful batch. Before C5, S5, H5, or promoted-capability language, record the named problem class, observed effect, future-agent rerun route, falsifier, maintenance delta, owner, risk/redaction boundary, and held-out or future repeat evidence.

Parent synthesis is not evidence by default. It becomes an evidence artifact only when it protects a claim, preserves a blocker, records a real run, justifies durable behavior change, or teaches a shorter future path. Otherwise it is deleted after extraction.

## Agent Coordination Boundary

Steward should stay agnostic about the coordination algorithm. It can support:

- A2A work, where agents pass evidence, diffs, and critiques to each other.
- A2Human checkpoints, where a human chooses between lanes, approves risky write sets, or resolves product intent.
- Graph-shaped workflows, where exploration, implementation, review, validation, and promotion nodes run in parallel or dependency order.

Graph-shaped coordination uses ordinary artifacts rather than a Steward scheduler. Nodes are lane contracts or lane results. Edges carry dependencies, evidence, diffs, critique, or human decisions. Human checkpoints are required for overlapping write sets, high or unknown risk, blocked validation, product-intent conflict, or any request to widen scope.

Skill Steward should provide the vocabulary, lane candidate contract, validation hooks, evidence boundaries, and optional CLI/MCP hints. It should not prescribe a universal scheduler, hierarchy, or custom multi-agent framework.

## Durable Integration

This should not become a new standalone skill yet. Existing surfaces should change behavior:

- `docs/NORTH_STAR.mdx`: add the acceleration rule and clarify that governance enables parallel action with proof.
- `docs/decisions/0026-parallel-acceleration-governance.mdx`: record the decision and the rejected serial-brake failure mode.
- `skills/repo-quality-system-lifecycle/SKILL.md`: allow repository ecology review to emit disposable execution lane candidates when pain is repo-wide.
- `skills/multi-agent-handoff/SKILL.md`: support parallel batch contracts and the senior-agent lane rule.
- `skills/mixture-of-experts/SKILL.md`: use MoE for lane discovery, contradiction detection, and evidence-boundary critique before or during large batches.
- `packages/steward_cli/lib/src/commands/ecology_command.dart`: extend `steward ecology route --json` with optional advisory `dispatch_lane_candidates` in the existing route v1 contract.
- `docs/schemas/ecology-route-v1.schema.json` and tests: update the v1 JSON contract in the same implementation so context does not drift.
- `packages/steward_cli/lib/src/commands/mcp_command.dart`: expose lane candidates only as a thin experimental adapter over the same validated CLI/core payload if MCP support is added.

## CLI, Schema, And MCP Shape

`steward ecology route --json` should remain non-mutating and advisory. It may infer lane candidate hints from existing ecology route facts such as invalid config, schema drift, active plan candidates, stale evidence, dirty state, and missing actions.

The output must not award maturity, adoption, health, steward status, or write authority. It should describe possible work lane candidates and their boundaries.

The field should be named `dispatch_lane_candidates`, not `dispatch_lanes`, and every CLI-emitted candidate should be marked:

- `advisory: true`
- `ephemeral: true`
- `requires_parent_assignment: true`
- `not_write_authorization: true`
- `authorization_source: none`
- `retention: delete_after_integration`

CLI/schema candidate fields:

- `lane_id`
- `source_disposition`
- `pain_signal`
- `owner`
- `scope`
- `write_set`
- `forbidden_paths`
- `dependencies`
- `allowed_action`
- `direct_fix_eligible`
- `authorization_source`
- `risk_class`
- `acceptance_check`
- `native_gate`
- `suggested_claim_ceiling`
- `non_claims`
- `integration_rule`

CLI-generated candidates are not parent-assigned lanes. `suggested_claim_ceiling` means the maximum possible claim if a parent assigns the lane and its gate passes. The CLI itself only proves that a candidate was observed from snapshot facts.

Existing dispositions remain canonical: `orient`, `compress`, `validate`, `tutor_pain`, `promote_tool`, `leave_native`, and `stop`. Lane actions are subordinate execution modes. No lane candidate should be generated from `leave_native`.

Candidate generation must avoid fake precision. Emit write-capable or implementation-oriented candidates only when owner and exact path are deterministic. Otherwise emit a read-only `explore` candidate with an empty `write_set`, no write authorization, and an integration rule asking the parent to assign a real lane after inspection.

Implementation should derive candidates from `ecologySnapshotPayload()` and the same facts used by `_routeDispositions()`. Do not add `.steward/dispatch-lanes/*`, do not feed lane candidates into `steward.yaml`, and do not turn lane candidates into action candidates unless repeated friction later enters the existing unknown-case to action-candidate review path.

Implement this as a documented additive update to `ecology-route-v1.schema.json`; do not create an ecology route v2 for this change. Because route v1 is closed with `additionalProperties: false`, the schema, schema conformance tests, schema aliases, schema README, and `schema check-outputs` registration must be updated in the same change as the CLI payload.

MCP parity is optional and should remain a non-claim in the first implementation. If exposed later, MCP must call the same core route payload used by the CLI and return the same advisory lane candidates. MCP must not infer separate candidates, authorize writes, mutate `steward.yaml`, or execute lane work. It remains experimental until production MCP transport, typed action policy, timeouts, output caps, redaction, and permission gates are proven.

No CLI or MCP output may include `direct_fix_allowed: true`. Parent-assigned lane contracts are the only source of direct write authorization.

## Anti-Bureaucracy Rules

Lane maps are disposable. After a batch finishes:

- successful fixes land in code, docs, tests, tools, schemas, or skills;
- repeated lessons promote to the appropriate durable owner;
- blocked facts go to a current ledger or evidence artifact only when useful;
- stale lane maps disappear.

Do not preserve lane maps as permanent project management artifacts. Do not create a new broad "parallel acceleration" skill until repeated real use proves existing skills cannot carry the behavior.

Do not answer governance drag with more evidence about governance drag. If a parent can safely dispatch lanes and fix the owner surface now, the stewardship move is to do that work, run the native gate, and delete the scaffolding. Evidence is retained only when it changes future behavior or protects a live claim.

This design spec is also disposable. After implementation, durable truth should live in the North Star, ADR, skills, CLI/schema/tests, and any necessary current ledger or evidence artifact. The spec should then be deleted or explicitly retired so it does not become permanent governance clutter.

## Validation

Implementation should run the repo's native validation after changes:

- `pnpm run validate`
- `pnpm run eval`
- `pnpm run docs:check`
- `steward ecology route --json`
- targeted Dart tests covering ecology route payloads and schema conformance
- schema output checks for changed JSON payloads

If all implementation gates pass, the strongest claim is that parallel lane-candidate routing is documented, schema-conformant, and statically wired. Non-claims: acceleration usefulness, repo maturity, adoption, H2/H4/H5/S5, production agent behavior, parent synthesis quality, correctness of worker results, or usefulness of the lane candidates in real work.

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
- CLI/schema/MCP advisory surfaces are designed together in the initial implementation context.
- Advisory outputs never authorize writes; parent-assigned lane contracts are the only write authorization surface.
- The first implementation makes only static wiring claims, not acceleration or maturity claims.
- No new standalone skill or permanent lane artifact is introduced.
