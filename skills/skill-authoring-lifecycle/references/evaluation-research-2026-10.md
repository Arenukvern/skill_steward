# Evaluation choices — reviewed October 13, 2026

This is a primary-source snapshot, not a claim that every library released in
October. September/October papers below are preprints; their findings are
bounded to the experiments reported. Library documentation describes advertised
capabilities, not compatibility proven in this repository.

## What recent research changes

| Source and date | Relevant result or method | Steward application |
|---|---|---|
| [SkillsBench 1.1](https://www.skillsbench.ai/blogs/skillsbench-1-1), June 16 | Matched with/without-skill trials and invocation tracking; some tasks regress despite aggregate gains. | Compare each task and client; measure discovery separately from task success. Do not import its leaderboard lift as our expected improvement. |
| [ACES](https://arxiv.org/abs/2608.20614), August 20 | Live paired skill trials measure facets that static scans do not; records normalize agent trajectories. | Keep T1 static gates, add offline task outcomes and costs. Do not combine safety with convenience in a compensating composite score. |
| [Agent Evaluation Reliability](https://arxiv.org/abs/2610.00651), September 30 | Scaffold coverage affects what rankings mean; more tasks cannot remove every source of uncertainty. | Match model, client, tools and permissions within pairs; report clients separately. A Codex result is not Zcode proof. |
| [Measurement-First Auditing](https://arxiv.org/abs/2610.05830), October 5 | Distinguishes exposure channels, validates scorers, and preserves inconclusive matched comparisons. | Hide acceptance artifacts from the actor, freeze grader revisions, test positive/negative controls, and retain unknowns. Do not label any public task definitively uncontaminated. |
| [Executable-Contract Audit](https://arxiv.org/abs/2609.37315), September 29 | Finds cases where tool reports and actual state effects diverge in benchmark environments. | Check resulting files/state and denied side effects, not only successful tool replies. Test the grader against a false-success fixture. |
| [Prompt-Injection Detectors](https://arxiv.org/abs/2610.03448), October 2 | Detector rankings transfer poorly; benign tool outputs reveal false-positive costs. | Use local attacked/benign pairs and record task completion plus unauthorized effects. A refusal alone is not successful safe assistance. |

## Which benchmarks and frameworks to adapt

“Official” means maintained by the named protocol or benchmark authors; it is
not a general safety certification. Adapted tasks are a local derivative suite,
not an official leaderboard result. Pin suite, task and scorer revisions; retain
licenses and provenance. Run unchanged benchmark rules if publishing a benchmark
score, and report any exclusions or expected failures.

| Target claim | Primary framework / benchmark | Adaptation and claim boundary |
|---|---|---|
| Skill improves a real task | SkillsBench paired design; ACES methodology | Start with local stewardship tasks. Native acceptance remains the oracle; measure invocation and costs independently. |
| MCP speaks its declared protocol | [MCP conformance](https://github.com/modelcontextprotocol/conformance) | Run applicable role/version/transport cases at a pinned revision. Report skips and known failures explicitly. Protocol conformance does not prove application authorization or utility. |
| Agent resists malicious tool content while still helping | [AgentDojo](https://github.com/ethz-spylab/agentdojo) | Adapt attack placement to repo docs/tool outputs, use fake secrets and disposable state, and verify unauthorized effects and benign task success separately. Not universal injection resistance. |
| CLI solves terminal work | [Terminal-Bench](https://www.tbench.ai/news/announcement-2-0) task/environment/verifier pattern | Borrow isolated state and outcome grading for local CLI tasks. Broad leaderboard runs are optional external calibration, not a release gate for a small CLI. |
| Tool discovery and argument construction | [BFCL](https://gorilla.cs.berkeley.edu/leaderboard.html) | Optional focused cases for tool selection, irrelevance and arguments. Function-call correctness alone cannot establish effect safety or end-to-end usefulness. |
| Safety risk coverage | [OWASP Agentic Top 10 2026](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/) and [MCP security practices](https://modelcontextprotocol.io/docs/2025-11-25/tutorials/security/security_best_practices) | Use as a threat-to-test checklist, not a numeric benchmark or compliance badge. Select applicable threats; record untested ones. |
| Stewardship concept earns its cost | Local paired dogfood and held-out future tasks | Test decisions, original-goal completion, rework, handoff recovery and maintenance cost. No public benchmark directly proves “evolutionary simplicity.” |

## Library selection: smallest sufficient owner

| Option | Useful capability | Decision for Steward now |
|---|---|---|
| Existing native Dart tests + static evals + offline comparison helper | Cheap repeatable regression checks and descriptive paired summaries | Use now; no provider, judge or scheduler dependency. |
| [skillgrade](https://github.com/mgechev/skillgrade) | Real CLI/ACP/command agents, repeated trials, deterministic graders and reference-solution validation | First optional pilot for a small isolated task suite. Pin a version; validate positive/negative graders before a live run. Local integration not yet qualified. |
| [NVIDIA SkillEvaluator](https://docs.nvidia.com/skills/skillevaluator) | Paired live evaluation, discovery/effectiveness dimensions, reporting | Stronger candidate if multi-client execution/reporting becomes repeated work. Experimental support; select explicit stages instead of an all-tier default. Its tier numbers are unrelated to Steward T1/T2. |
| [Inspect AI](https://inspect.aisi.org.uk/eval-logs.html) | Reusable evaluation logs and scoring infrastructure | Use when an adopter already has Inspect; retain its logs rather than build a duplicate store. |
| [Harbor](https://docs.harborframework.com/) | Sandboxed tasks, agent adapters and trajectory formats | Reuse behind an external runner for isolation/scale; do not add orchestration to Steward. |
| [agent-skill-eval](https://github.com/tardigrde/agent-skill-eval) | Paired CLI runs, preflight, reports and iteration comparison | Alternative small pilot when its adapters match the client. Verify isolation, grader visibility and output semantics before trusting deltas. |
| [Promptfoo](https://www.promptfoo.dev/docs/configuration/expected-outputs/) | Deterministic and model-based output assertions | Useful for prompt/output contracts in adopters already using it; insufficient alone for filesystem effects or session purpose. |
| [SkillOpt](https://github.com/microsoft/SkillOpt) | Bounded text edits with validation gates; offline replay/consolidation | Adopt the method, defer automatic optimization. Separate development, selection validation, and final holdout; no nightly automatic promotion. |

These are alternatives, not a stack to install together. For a first pilot use
one runner, one client/model configuration, a few real failure-derived tasks,
and deterministic graders. Add a second client to test transfer before adding
more tasks on the first merely to make the dashboard larger.

## Current implementation limits

`steward benchmark` runs declared safe actions and checks durability; it does
not launch with/without-skill agent trials. Use it for the action contract.
The portable comparator consumes observations from a chosen runner; it does
not execute tasks, authenticate receipts, or issue acceptance.

Steward's `mcp_command.dart` advertises an experimental surface and protocol
`2024-11-05`. Its transport comments are not a conformance result. Qualify the
actual wire behavior against the claimed revision before making interoperability
claims. Do not add an HTTP wrapper just to obtain a score from an HTTP-oriented
suite; select a compatible test route or report the transport coverage gap.

See [paired dogfood](paired-dogfood.md) for the operational loop and
tool assurance
for local MCP/CLI checks. These remain separate proof dimensions.

For implementation order, bounded cohorts and scoreboard fields, use
[benchmark adoption](benchmark-adoption.md).
