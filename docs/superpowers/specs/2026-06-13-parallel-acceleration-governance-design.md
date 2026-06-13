# Parallel Acceleration Governance Design

Date: 2026-06-13

## Purpose

Clarify Skill Steward governance so it accelerates repo-wide work instead of turning into a serial brake. The North Star already says useful stewardship turns cold exploration into hot paths for future agents with the same or stronger proof bar. This design makes the missing implication explicit:

> Governance is successful when it lets many agents move faster without losing truth, ownership, or proof.

The change does not move the repository center. It clarifies how the existing North Star should behave when modern agent execution can dispatch many independent agents at once.

## Problem

Existing stewardship language can be misread as caution-first. In particular, "smallest useful disposition" can drift into "smallest action" or "one next step." That interpretation becomes wrong when the pain is repo-wide and many agents can work in parallel.

The real failure mode is not too many agents. The failure mode is unclear decomposition: agents without owner boundaries, acceptance checks, validation gates, or evidence boundaries.

## Design Principle

"Smallest useful disposition" should mean the smallest truthful coordination unit, not the smallest amount of work.

If the pain is local, the right coordination unit may be one fix, FAQ row, validation command, or evidence update. If the pain is repo-wide, the right unit may be a disposable execution map that supports 2, 20, 200, or more agents. The parent agent chooses batch size based on task shape, available execution capacity, independence, risk, and integration cost. Skill Steward should not impose a numeric cap.

## Dispatch Lanes

A dispatch lane is temporary execution scaffolding for active parallel work. It is not a durable governance artifact and should disappear after integration unless a specific lesson earns a durable owner.

Each lane must declare:

- `owner`: file, doc, package, command, skill, module, or surface that owns truth.
- `scope`: where the agent may act.
- `allowed_action`: `explore`, `fix`, `implement`, `verify`, `compress`, `promote`, or `stop`.
- `acceptance_check`: what proves the lane is done.
- `native_gate`: command, test, schema check, eval, benchmark, or blocked state.
- `evidence_boundary`: what can and cannot be claimed from the lane result.
- `integration_rule`: how the parent agent accepts, merges, rejects, or escalates the result.

Create only as many lanes as are needed to make parallel work legible. Do not create lanes to describe lanes.

## Senior-Agent Lane Rule

Worker lanes may fix, implement, or complete bounded low-impact work directly when the lane scope is clear and validation is available. A worker should not create a recommendation queue when direct completion is safer and faster.

The worker must still report:

- files or surfaces changed,
- validation run or blocked,
- claim boundary,
- unresolved risks,
- any scope pressure that should return to the parent.

The parent agent remains accountable for synthesis, conflicts, final validation, and final claims.

## Durable Integration

This should not become a new standalone skill yet. Existing surfaces should change behavior:

- `docs/NORTH_STAR.mdx`: add the acceleration rule and clarify that governance enables parallel action with proof.
- `docs/decisions/0025-parallel-acceleration-governance.mdx`: record the decision and the rejected serial-brake failure mode.
- `skills/repo-quality-system-lifecycle/SKILL.md`: allow repository ecology review to emit disposable execution lanes when pain is repo-wide.
- `skills/multi-agent-handoff/SKILL.md`: support parallel batch contracts and the senior-agent lane rule.
- `skills/mixture-of-experts/SKILL.md`: use MoE for lane discovery, contradiction detection, and evidence-boundary critique before or during large batches.
- `packages/steward_cli/lib/src/commands/ecology_command.dart`: extend `steward ecology route --json` with optional advisory `dispatch_lanes`.
- `docs/schemas/ecology-route-v1.schema.json` and tests: preserve the JSON contract if CLI output changes.

## CLI Shape

`steward ecology route --json` should remain non-mutating and advisory. It may infer lane hints from existing ecology route facts such as invalid config, schema drift, active plan candidates, stale evidence, dirty state, and missing actions.

The output must not award maturity, adoption, or health. It should describe possible work lanes and their boundaries.

Suggested lane fields:

- `lane`
- `pain_signal`
- `owner`
- `scope`
- `allowed_action`
- `acceptance_check`
- `native_gate`
- `evidence_boundary`
- `claim_ceiling`
- `integration_rule`

## Anti-Bureaucracy Rules

Lane maps are disposable. After a batch finishes:

- successful fixes land in code, docs, tests, tools, schemas, or skills;
- repeated lessons promote to the appropriate durable owner;
- blocked facts go to a current ledger or evidence artifact only when useful;
- stale lane maps disappear.

Do not preserve lane maps as permanent project management artifacts. Do not create a new broad "parallel acceleration" skill until repeated real use proves existing skills cannot carry the behavior.

## Validation

Implementation should run the repo's native validation after changes:

- `pnpm run validate`

If CLI JSON changes, implementation should also run the Dart package tests that cover ecology route payloads and schema conformance.

## Success Criteria

After implementation:

- North Star clearly says governance must accelerate many agents without losing truth, ownership, or proof.
- The ADR records why serial governance is rejected.
- Repo-quality review can route repo-wide pain into disposable execution lanes.
- Multi-agent handoff supports parallel execution and direct bounded fixes by worker agents.
- MoE can discover lanes and contradictions without turning into another doctrine.
- Ecology route can provide advisory dispatch hints without becoming a verdict.
- No new standalone skill or permanent lane artifact is introduced.
