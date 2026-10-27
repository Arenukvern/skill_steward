# Paired dogfood: measure a useful task, not compliance with a skill

Dogfood generates candidate failures from ordinary work. A controlled replay
measures a proposed improvement. A later untouched task checks transfer. Keep
those three kinds of evidence distinct.

## Bounded loop

1. **Observe ordinary work.** Reuse its run record and redacted logs. Note the
   original goal, acceptance result, loaded skill path/digest, detours and user
   corrections. Observation finds cases; it does not show a causal benefit.
2. **Freeze a replay.** Choose a few representative tasks plus a negative
   activation control. Preserve the starting checkout, input fixtures, tool
   inventory, client/model, permissions, budgets and grader. Include a task
   where native work already succeeds. Keep task difficulty representative.
3. **Check the checker.** A reference solution must pass; a known-bad solution,
   unauthorized effect and false-success response must fail the relevant checks.
   Keep graders outside the agent's writable surface. Snapshot their digests.
4. **Run matched conditions.** Baseline and candidate receive the same request
   and clean starting state; only the target skill/tool changes. Do not name the
   skill in the user prompt when testing discovery. A separate forced-invocation
   trial measures efficacy, not discovery. Verify the baseline cannot load a
   global/plugin copy. If isolation cannot be established, label it a guided
   observation rather than a no-skill experiment.
5. **Bound variability and cost.** Start with three repeats per task as a pilot,
   not statistical proof. Alternate or randomize arm order, reset state and
   memory, and record cache/warmup policy. Cap runtime and tool/model budget
   before running. Retain every failure, timeout and blocked run. Do not rerun
   only failures and overwrite their first results.
6. **Review outcomes before costs.** Safety regressions veto promotion. Unknown
   safety is not zero violations. Check each task and client, then compare time
   and rework for pairs where both arms passed. Costs of failed attempts still
   belong in total effort. Do not reward an agent for failing fast.
7. **Make one bounded edit.** Use development cases to tune; use a separate
   selection set if needed. A final holdout or future-agent task stays untouched
   until the decision. Once a result informs an edit, it is no longer unseen.
8. **Keep, simplify or revert.** Require preserved acceptance, no new safety
   violation, and a useful quality/time/rework tradeoff on a fresh repeat.
   Record the maintenance and evaluation cost. One pilot is not fleet-wide
   acceleration; demote a surface that no longer earns its upkeep.

An unavailable client or runner is a named coverage gap, not a reason to spend
the whole task installing infrastructure. Apply [work discipline](work-discipline.md) §2, then keep
the blocked record and return to the original native goal.

## Functional preflight and report normalization

Before a paid trial, use the exact isolated adapter to read a fixture, edit it,
and run its native check. Verify denied access to global skill copies and the
frozen grader. A model reply alone does not prove tool access; nested sandboxes
can fail only when the first tool starts. Do not weaken isolation to hide this.
Check global AGENTS/memory separately from project docs configuration.

Inspect client traces before mapping runner scores. Skillgrade command-adapter
score zero can mean a broken execution environment, and its outer command count
is not agent tool usage. Keep infrastructure failures blocked/error, unused arms
not run, provider telemetry separate from estimates, and missing cost unknown.
Version 0.5.0 shares a local prompt file: run sequentially. Check cancellation
kills the process tree rather than merely ending the runner's wait.

See [benchmark adoption and scoreboards](benchmark-adoption.md) for staged
SkillsBench, ACES, AgentDojo, Terminal-Bench and MCP conformance adoption.

Before freezing a task, preserve executable modes and expose the repository's
ordinary development check. Keep the authoritative grader immutable and outside
the agent's workspace; it can independently check the final artifact. Withholding
all useful native checks measures test-harness invention rather than the repair.
If the grader requires an exact enum, declare that enum in the task contract.
Record a semantically correct rejected label as a contract mismatch, not skill
uplift. Fix fixture packaging in a new cohort without changing the frozen grader;
do not pool old and corrected task versions.

## First task families

| Task | Native outcome oracle | Dogfood signal |
|---|---|---|
| Routine repair with a known owner | Existing native test passes; unrelated files unchanged | Does the skill avoid unnecessary governance work? |
| A moved document or stale install pointer | Relevant links resolve and the intended skill path is discoverable | Does the next fresh session avoid repeated searching? |
| Validation failure | Nonzero status and original diagnostic preserved; one runner selected | Does a repair reduce repeated commands without hiding failure? |
| Untrusted tool/document instruction | Legitimate task completes; protected state and fake secret remain intact | Does the agent resist goal diversion without blanket refusal? |
| Ambiguous ownership / handoff | Correct owner receives a sufficient resumable artifact, without unauthorized edits | Does continuity reduce corrections and recovery effort? |

Freeze concrete fixtures and native oracles in the owning repo; these are case
families, not scored examples or hidden acceptance tasks.

## What to record

- Quality: native acceptance, task failures, blocked/error runs, corrections.
- Safety: violated declared invariants, unauthorized effects, benign false
  refusals. Scope the safety claim to the invariants actually tested.
- Purpose: original-goal completion and a later task/handoff that reuses the
  improvement. More artifacts or skill invocations are not value by themselves.
- Cost: elapsed time, time to first useful action, tool calls, repair attempts,
  human interventions, tokens and cost where the runner exposes them. Use null
  for unavailable measurements; never substitute zero or estimate silently.
- Provenance: client/model configuration, source and skill hashes, environment,
  prompt/fixture/grader revisions, raw run reference, selected condition.

Report per client/model and task family. Repeats of one task are not independent
tasks. For larger samples use a paired, task-clustered uncertainty analysis;
small pilots should show counts and deltas without significance claims. Report
observed all-trials-pass separately from “at least one succeeded”; neither
should be silently labeled pass@1 or extrapolated reliability.

## Portable offline comparison

Requires Dart SDK 3.11+; no pub packages, network, agent calls or writes. From a
copied skill directory:

```bash
dart scripts/compare_dogfood.dart references/paired-dogfood-example.json
# Actual run records stay in the owning repo's evidence location:
dart scripts/compare_dogfood.dart /absolute/path/paired-runs.json
```

The example is **synthetic**, not dogfood evidence. The helper prints descriptive
JSON and exits 0 after a valid comparison, including a regression. Exit 2 means
invalid input or unreadable file. Consumers must inspect `status`; exit 0 is not
acceptance. No promotion is awarded.

The input is a small interchange record, not a new Steward CLI/schema registry.
`experiment`, `kind`, `configuration_ref`, `baseline_ref`, `candidate_ref`, and
nonempty `pairs` are required. Use `kind: agent`, `native_control`, or `synthetic`.
Each pair needs a unique `id`, a stable `task_id`, and both run records. Preserve
partial runs using `outcome: blocked` or `error` with a reason in the evidence.

Each run requires `context_ref`, `evidence_ref`, `outcome`, and
`safety_violations` (a nonnegative count, or explicit null when unmeasured).
`context_ref` must identify the same prompt, fixture, environment, client/model,
permissions, budget and grader in both arms, excluding only the intended
baseline/candidate treatment. Use a digest of that manifest for real runs.
Keep the manifest and receipts at the evidence reference. A digest string is
not authenticated by this helper; the runner/reviewer owns provenance checks.

Metrics are optional nonnegative numbers; `skill_invoked` is true/false/null.
The helper rejects mismatched contexts, duplicate pairs and invalid values.
It preserves metric coverage, incomplete pairs, safety violations, per-task
consistency, and separate all-attempt versus both-passed cost deltas. It does
not pool multiple client/model configurations: use separate input files.

Link the input/output from the existing adoption record's evidence list. Do not
paste raw secrets or transcripts into a public skill package. Do not pass this
record off as `steward/benchmark-summary/v1` or an official benchmark result.

## Ordinary workflow reuse

Prioritize the North Star's cold-to-hot claim before another synthetic task suite.
Use the existing adopter record; no new runner, schema or compulsory evidence file.

The initial observation lanes are Oka documentation-drift maintenance and the
anonymized Private A drift workflow already recorded in the usage audit. Their
historical runs establish usage, not a timed baseline. At the next ordinary task,
record the actual owner search, native command, acceptance and interventions.
Leave only the smallest useful improvement: an error, command, map or focused
skill. A later fresh session on related work is the reuse observation; it cannot
be manufactured by replaying the author's exposed repair as unseen acceptance.

Record baseline/reuse source revisions, task differences, time to owner/native
check, correct completion, unintended edits, human review/interventions, and
maintenance plus evaluation effort. Missing values stay unknown. Public source
links are welcome; private identifiers/transcripts stay local and published rows
use anonymous labels. Do not infer causal uplift from an unmatched before/after.

Before a controlled comparison, freeze a practical benefit threshold appropriate
to the actual workflow and keep native correctness and scope preservation as
requirements. Prefer matched disposable snapshots where possible. Use existing
client adapters; freeze execution dependencies, not reporting-only files. Keep
failed attempts in total effort. Independent review must check that the oracle
rejects invalid real input, not merely a hard-coded wrong answer.

Keep an improvement only if reuse reduces rediscovery or recurring failures and
justifies its upkeep. Otherwise simplify, demote to an optional reference, or
remove it. Fewer Steward calls can be the successful result. Until these later
episodes exist, maintenance payback is unmeasured, not passed or failed.
