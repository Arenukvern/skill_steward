---
name: vision-alignment-foresight
description: Critically analyze whether a product, repo, skill, plugin, harness, or architecture vision still fits the real application, user intent, implementation, evidence, and likely future direction. Use when asked to assess vision vs application, predict future fit, critique roadmap direction, analyze strategic intent, or decide whether to keep, refine, pivot, or kill a plan.
license: MIT
type: governance
metadata:
  author: skill-steward
  version: "1.0.0"
  category: strategy
---

# Vision Alignment Foresight

Test whether a vision is still worth building, not just whether it sounds coherent.

Use this skill to connect four things that often drift apart: **stated intent**, **real implementation**, **observed evidence**, and **future direction**.

## Trigger Examples

- Should trigger: "Analyze this vision against the app and future agent direction."
- Should trigger: "Does our repo strategy still make sense given current usage and platform changes?"
- Should trigger: "Criticize this roadmap and predict where it will fail."
- Should not trigger: "Write an ADR for this accepted decision." Use `repository-governance-lifecycle`.
- Should not trigger: "Run a broad multi-agent critique only." Use `mixture-of-experts`.

## Workflow

1. **Name the intent.**
   - Restate the human goal in one or two sentences.
   - Separate the durable purpose from the proposed implementation.
   - Mark what is explicit, inferred, and unknown.

2. **Map the application reality.**
   - Read the North Star, ADRs, FAQs, skill docs, config, harness entrypoints, tests, and release notes that define current behavior.
   - Identify the actual user, maintainer, agent, and runtime surfaces.
   - Record any contradiction between docs, code, config, and user behavior.

3. **Collect evidence.**
   - Prefer concrete signals: usage logs, eval results, issue/PR history, support questions, benchmark outcomes, adoption friction, failing tests, repeated manual workflows, and rollback history.
   - If future direction matters, do current research using primary sources where possible.
   - Label every major claim as **observed**, **researched**, **inferred**, or **speculative**.

4. **Run critical lenses.**
   - Product/user lens: who benefits, who pays the complexity cost, what workflow improves?
   - Engineering lens: what must be true in code, tests, data, deploys, and interfaces?
   - Agent experience lens: can another agent discover, execute, verify, and recover without hidden context?
   - Maintenance lens: what will decay, fork, or become impossible to support?
   - Ecosystem/future lens: does the plan align with platform movement, standards, and likely integration paths?
   - Adversarial lens: what evidence would prove the vision wrong?

5. **Forecast with humility.**
   - Use time horizons: **now**, **3-6 months**, **12-24 months**.
   - State confidence and assumptions.
   - Define leading indicators that would increase confidence.
   - Define falsifiers that should trigger a pivot or rollback.

6. **Choose the smallest proof.**
   - Recommend one bounded proof that can validate the vision with real behavior.
   - Prefer dogfood loops, evals, typed harness actions, or repeated repo workflows over prose-only agreement.
   - Do not recommend broad platform work until at least one narrow proof works end to end.

7. **Make learning durable.**
   - If the analysis changes a standing decision, update an ADR or FAQ via `repository-governance-lifecycle`.
   - If it changes a skill, run `skill-authoring-lifecycle` and `skill-eval-improve`.
   - If it changes a repo-local feedback loop, update the local harness contract or unknown-case queue.

## Output Format

Use this shape unless the user requests another format:

```markdown
## Intent
{explicit goal, inferred goal, unknowns}

## Evidence
| Signal | Source | Strength | What it implies |
|--------|--------|----------|-----------------|

## Alignment Verdict
{aligned | partially aligned | misaligned | too early}

## Critical Gaps
- {gap, why it matters, evidence}

## Future Fit
| Horizon | Prediction | Confidence | Assumptions | Falsifier |
|---------|------------|------------|-------------|-----------|

## Recommendation
{keep/refine/pivot/kill} because {reason}.

## Smallest Proof
{one concrete proof loop, owner/surface, success metric, rollback signal}

## Durable Updates
{ADR/FAQ/skill/eval/harness updates needed}
```

## Decision Heuristics

- A vision is healthy when repeated real workflows make it more precise.
- A future claim is weak unless it names time horizon, confidence, and falsifier.
- A skill or plugin vision is weak if it cannot explain when it should **not** trigger.
- A harness vision is weak if it has no deterministic proof loop.
- A governance vision is weak if the only artifact is prose and no agent can act on it.
- A roadmap is suspect when every option is additive and none can be killed.

## Anti-Patterns

| Anti-pattern | Correction |
|--------------|------------|
| "This is the future" with no evidence | Separate research, inference, and speculation |
| Vision equals implementation | Preserve purpose while allowing implementation to change |
| Symptoms with no baseline | Add an eval, benchmark, issue cohort, or usage snapshot |
| Broad rewrite before proof | Pick one narrow proof loop first |
| Agent-only convenience | Check maintainer experience and recovery paths |
| Research as decoration | Tie every source to a decision or falsifier |

## Related Skills

| Task | Skill |
|------|-------|
| Formalize accepted decision | `repository-governance-lifecycle` |
| Multi-lens critique | `mixture-of-experts` |
| Skill package changes | `skill-authoring-lifecycle` |
| Measure skill quality | `skill-eval-improve` |
| Persist research links | `skill-source-citations` |
| Turn proof into harness loop | `mcp-harness-repo-maintainer` |

## Install

```bash
npx skills add arenukvern/skill_steward --skill vision-alignment-foresight
```

## Sources

See [references/sources.md](references/sources.md). When researching, follow `skill-source-citations`.
