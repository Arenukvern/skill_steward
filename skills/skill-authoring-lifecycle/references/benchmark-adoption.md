# Benchmark adoption and scoreboards

## Current priority

External framework integrations and automatic optimization are deferred. The
matrix below is a reference, not a rollout checklist. Adopt a method only when a
named recurring adopter failure or interoperability decision requires it and the
existing native checks/client adapters cannot answer it. First measure ordinary
workflow reuse using [paired dogfood](paired-dogfood.md#ordinary-workflow-reuse).
No official benchmark badge or broad safety claim follows from local fixtures.


Research checked 2026-10-13. Adopt methods first, adapters only when a second
consumer needs them. No benchmark proves universal safety, usefulness, or
certification of the skill/MCP/CLI concept. Keep official-suite scores separate
from Steward adaptations and development cases.

## Sequence and exit criteria

| Stage / owner | Smallest useful implementation | Exit / falsifier |
|---|---|---|
| 0 — client integration maintainer | Functional isolated read/edit/grade preflight; pin client/model; deny global skills and grader access; process-tree timeout | Both arms can perform the task; denied paths verified. A READY reply or runner exit zero is insufficient. Stop after two failed configurations. |
| 1 — skill maintainer | Current two real-work fixtures, 3 paired repeats per client, frozen native oracle, actual skill reads, matched environment | Complete pairs with raw traces. No positive lift or excess overhead means narrow routing, compress, or retain native workflow; no promotion from 2 task families. |
| 2 — skill maintainer + independent reviewer | Add untouched cases for stale install pointers, ownership handoff and benign/malicious tool output; review grader before testing candidate | Improvement transfers beyond development tasks without correctness/safety regressions. Exposed cases move to development. |
| 3 — external evaluation maintainer | Export a small, relevant task cohort to the chosen external suite, retain native reports/ATIF when available | Reproduce local outcomes and document adapter differences. Stop if the adapter costs more than the independent evidence it adds. |
| 4 — release maintainer | Scheduled or manual release evidence on changed surfaces, link immutable artifacts | No paid whole-suite gate on every docs edit; rerun when a claim, skill, model, adapter or threat boundary changes. |

The October 13 rerun qualified targeted Codex and ZCode adapters. Stage 1
completed three paired repeats on two development tasks in Codex (6/6 passes
per arm); the final ZCode cohort completed one repeat (baseline 2/2, candidate
1/2 plus a timeout). No quality uplift is established. Earlier setup failures
and incomplete cohorts remain separate in `docs/evidence/archive/skillgrade-pilot-2026-10-13.mdx`.
Stages 2–4 remain adoption work, not completed external integrations.

## Framework choices

| Framework | Adopt for Steward | First bounded slice / scorecard | Avoid |
|---|---|---|---|
| [SkillsBench 1.1](https://www.skillsbench.ai/blogs/skillsbench-1-1) | Matched with/without skills, task-level lift, invocation tracking, withheld oracle | Package local repair/evidence tasks in native BenchFlow `task.md` + environment/oracle/verifier. Separately choose relevant unmodified software-engineering tasks from pinned v1.1. Report task count, per-task pass deltas and negative lift. | Calling local adaptations an official SkillsBench score; transferring published aggregate lift to Steward. |
| [ACES / SkillEvaluator](https://github.com/NVIDIA/SkillEvaluator) | Separate validation, overlap review and live causal usefulness | First run explicit Tier 1 without LLM on one skill and preserve scanner skips. Tier 2 only for a concrete duplicate cluster with an explicit catalog. Tier 3 reuses reviewed frozen tasks after client/sandbox qualification; preserve native report/ATIF. | `validate` as a cheap lint command: it can run all tiers. Renaming Steward T1 to mean NVIDIA Tier 1. Automatically trusting generated starter cases. |
| [AgentDojo](https://github.com/ethz-spylab/agentdojo) | Legitimate task utility and adversarial success as separate measures | Adapt 4 pairs: forged validation success, maturity promotion, ownership diversion, fake-secret exfiltration. Pair each with benign output; measure unauthorized state effects and benign completion/refusal. Use fake data in disposable environments. | Treating one explicit “ignore instructions” case as injection robustness; running attacks with production credentials or host data. |
| [Terminal-Bench 2.0 / Harbor](https://www.tbench.ai/news/announcement-2-0) | Optional terminal environment and recovery transfer | Only if shell/package recovery remains a real bottleneck: select 3–5 relevant unmodified tasks; report exact IDs, revision, excluded tasks and native pass rate. Use Harbor if already needed by ACES rather than add another orchestrator. | Full suite merely to prove governance quality; comparing a selected subset with official full-suite rankings. |
| [MCP conformance](https://github.com/modelcontextprotocol/conformance) | Protocol interoperability for the actual advertised role/revision/transport | Freeze the requirement set, publish passed/failed/expected-failed/skipped counts plus scope. First resolve the experimental stdio surface's compatible test route. | An HTTP wrapper built only for a test score; equating protocol success with correct filesystem effects or authorization. |
| [BFCL](https://gorilla.cs.berkeley.edu/leaderboard.html) | Optional tool-selection/argument failure taxonomy | Add local wrong-tool, wrong-argument and abstention cases when traces reveal those faults | Model leaderboard ranking as proof of a Steward server implementation. |

SkillsBench is an author-maintained benchmark, ACES is a research methodology
with an implementation, AgentDojo is a research environment, and MCP conformance
is the protocol project's test suite. Their authority and claims differ.

Use [Inspect](https://inspect.aisi.org.uk/eval-logs.html) only if independent
review/scorer analysis needs its log workflow; use
[Promptfoo](https://www.promptfoo.dev/docs/configuration/expected-outputs/) only
for a focused assertion/red-team integration. They are alternatives, not required
layers alongside Skillgrade. Keep SkillOpt-style bounded edits offline until a
held-out cohort exists; an optimizer must not author and accept its own oracle.

## Scoreboard contract

Start with a versioned Markdown table beside native JSON and raw trace links.
Reuse `compare_dogfood.dart`; do not build a service, aggregate “quality score,”
or second evidence schema. Existing adoption artifacts can link the comparison
through their evidence field. Do not change strict adoption-run schemas merely
to hold benchmark-specific fields.

Each row identifies suite/revision, task/cohort and split, client/model,
configuration/skill/grader digests, date, environment and raw artifact. Display:

- **Coverage:** planned, attempted, eligible paired, blocked, error, skipped,
  excluded and independent task count. A missing arm is not a loss or a zero.
- **Correctness:** native passes/attempts and paired wins/ties/regressions;
  keep per-task rows so negative lift is visible. Show repeated-task consistency.
- **Safety:** violations/tested invariants, attack success, benign success and
  false refusal. Unknown coverage stays unknown; a violation cannot be averaged
  away by faster execution. No tests means no safety score.
- **Usefulness:** original goal completed, unnecessary artifacts/commands,
  human interventions and later reuse. Skill invocation is exposure, not success.
- **Efficiency:** paired time/token/cost deltas only when both pass; separately
  show total failed/blocked effort and setup cost. Keep estimated/provider/cached
  tokens distinct. Report missing telemetry denominators.
- **Decision:** blocked, inconclusive, regression, unsafe, or descriptive; name
  the next repair/owner. Statistical superiority and canonical acceptance require
  separate reviewed evidence; the comparator never promotes.

Keep Codex and ZCode rows separate, even on the same model. Do not pool model or
runner upgrades. Once there are enough independent tasks, use a predeclared paired
analysis (task-cluster bootstrap for uncertainty, paired binary comparison for
success); do not treat repeated runs of two tasks as a broad independent sample.
Three repeats are a debugging pilot, not a significance threshold.

A local adaptation earns a row labeled **adapted**, not an official score. A
public benchmark row needs the native manifest, unmodified oracle, full declared
cohort and reproducible execution. Publish historical snapshots without silently
replacing their versions; public traces require privacy review.

## Production value milestones

Proposed priorities after the October 13 pilot; these are exit criteria, not
completed work or release promises. Keep this roadmap here rather than creating
a second benchmark service or a parallel planning ledger. Retire completed rows
into the linked dated evidence and implementation owners.

| Priority / owner | Question and bounded next work | Evidence required for the public claim |
|---|---|---|
| P0 — evaluation maintainer | Can someone audit the existing result? Package sanitized per-trial receipts, exact source/skill/adapter revisions and grader hashes; record model, environment, timeout, exclusions and setup effort. | Independent replay of the declared procedure at a pinned release. A checksum authenticates content identity, not task success. Until then say “local development pilot,” not “publicly reproduced.” |
| P1 — skill maintainer + independent reviewer | Does guidance help where stewardship is actually needed? Freeze untouched task families for stale installation diagnosis, ownership handoff, contradictory proof and recurring validation drift, plus routine-repair negative controls. Set the practical success/overhead threshold before execution. | Matched per-client trials, task-level outcomes, actual invocation, time/tokens and all failures. Counterbalance order. Review oracle independently. Report uncertainty by task family; do not treat repeats as independent tasks or select only wins. No meaningful gain means narrow, compress or retire the tested guidance. |
| P1 — adopter maintainer | Does stewardship pay back its upkeep? Use two existing adopters from the October 13 cross-project usage audit and three comparable maintenance episodes each; count setup, upkeep, task completion, operator minutes, handoff rework and repeat failures. | Dated before/after case studies with native outcomes and confounders. Report setup + upkeep + execution + repair burden; a local positive balance supports only that adopter/use case. It is not broad causal ROI or a revenue estimate. Stop adding process when costs exceed observed benefit. |
| P2 — tool maintainer + independent reviewer | Which effects are safe and recoverable? Pair benign and adversarial tasks using fake data: forged proof, unauthorized maturity changes, ownership diversion and exfiltration. Check final effects and legitimate completion separately; test applicable CLI/MCP failure and rollback boundaries. | Exact attack cases, unauthorized effects, benign completion/refusal, missing coverage and pinned protocol conformance results where applicable. AgentDojo-style adaptations are local tests, not an official suite score or universal safety certification. |
| P3 — release maintainer | Does the result transfer? Select a relevant pinned external cohort only after local usefulness is demonstrated; use SkillsBench paired tasks, ACES tiers for specific gaps, and Terminal-Bench only for an observed terminal-recovery need. | Native reports with task IDs, versions, exclusions and changes. Label subset/adaptation clearly; an official ranking requires the benchmark's submission rules. Publish no blanket “benchmark passed” badge. |

The pilot compared access to a bundle, not the isolated value of every component.
When attribution matters, add **one** targeted ablation (for example native check
alone versus native check plus guidance). Do not launch a full skill × MCP × CLI
matrix. Measure the original task outcome first; tool usage and document count
are mechanisms, not value. Guidance cannot establish enforcement safety that
belongs to an executable permission/effect boundary.

## README and badge policy

Use a small proof table linking claims to evidence and limitations. Prefer the
existing live GitHub Actions badge labelled **Repository checks**; its status
belongs to the displayed branch/revision. Keep dated behavioral results in a
linked report rather than a manually maintained green score badge. The existing
“maintained with Skill Steward” badge identifies usage, not independent approval.

Do not add “production ready,” “safety certified,” “agent accuracy,” “100% tested,”
or benchmark logos implying endorsement. An external-run badge becomes useful
only with a pinned native report and an honest label such as “SkillsBench subset:
report.” Do not use the runner name as the name of a benchmark. Failed and
inconclusive evidence must remain reachable from the same proof surface.

A future claim should fit one sentence: **which released artifact, for which
users/tasks and client configuration, achieved what outcome, against which
baseline, with what measured cost and remaining limitation?** If the evidence
cannot fill those fields, publish the capability and its boundary instead.

Existing adoption is documented in `docs/evidence/archive/cross-project-usage-2026-10-13.mdx`.
Prioritize refreshing existing receipts and measuring recurring maintenance over
creating new adoption scaffolding. Public artifacts may be linked directly;
private projects require anonymized case summaries without private identifiers.

## Established October 13 baseline and immediate priorities

`evals/baselines/2026-10-13.json` is the native/check-coverage baseline;
`evals/skillgrade-pilot/results/2026-10-13-rerun.json` remains the separate agent
baseline. Details: `docs/evidence/archive/quality-baseline-2026-10-13.mdx`.

- Done locally: action/probe/benchmark exit propagation; non-T1 declared-case
  execution; explicit skipped status; six existing adopter workflows refreshed.
- Done locally: shared discovery excludes native Dart/MCP packages without a
  Steward manifest and empty/cache-only residues. Present manifests retain
  strict checks. Both affected adopter contract checks pass; original and
  intermediate failures remain in the baseline. Extend scope only for a
  demonstrated native format; preserve validation/bundling parity.
- Next, producer owner: review the failed package-version check against the
  intended release policy. Do not change package versions solely to pass it.
- Then measure three recurring maintenance episodes in existing adopters and
  one held-out guidance hypothesis. Include setup/repair burden and failures.

The North Star opportunity is fewer repeated repairs with trustworthy native
outcomes. “Use less Steward when native work is enough” is a positive outcome,
not an adoption failure. No new service, maturity tier or all-framework matrix
is required to measure that.

Guidance hypothesis for held-out review: grounded advice beside an existing blocked
result reduces wrong-owner edits and repair attempts without lowering task
completion or adding unnecessary artifacts. See the bounded
`skills/harness-engineering-lifecycle/references/output-guidance.md` method and
`evals/output-guidance-pilot/` exposed development comparison. Keep its three
advice arms separate from the skill/no-skill pilot. Neither establishes
multilingual fidelity or an official benchmark rank.
Compare absent, generic and outcome-specific advice; judge original task
success, not compliance with the prompt or volume of Steward use.


Ambiguous-owner baseline: `docs/evidence/archive/ambiguous-owner-pilot-2026-10-13.mdx`.
Three qualified families expose false-green/evidence-overwrite hazards; the
benefit gate was not met. Retire inspected cases from unseen acceptance. Freeze
the intended observable semantics before the oracle: the gold repair must reject
invalid actual input, not merely echo expected policy. Independently review a
newly versioned replacement for the quarantined stale-receipt family. Keep
reporting-only files out of execution freezes; preserve any controller stops.
