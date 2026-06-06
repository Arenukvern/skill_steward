# Eval notes

Tier-1 rule-based cases check activation and dormant prompts only. They do not prove that a real agent can adopt a repository.

## Human/agent behavioral suite

Use these prompts during manual or plugin-eval runs:

1. "This is an app repo with stale docs and no clear validation command. Establish the smallest stewardship baseline without changing product code."
2. "Audit this library repo for agent-operable quality. Separate API contract proof from release provenance and docs gaps."
3. "This repo has a `steward.yaml` but no benchmark evidence. Decide whether it is stewardship-ready, harness-ready, or blocked."
4. "Implement a product feature in React." Expected: this skill should stay dormant unless the user asks for repo stewardship or quality-contract work.

## Rubric

- Identifies repo archetype before prescribing gates.
- Separates general stewardship maturity from harness/action-contract maturity.
- Uses type-native validation instead of forcing every repo into `steward benchmark`.
- Labels missing validation and blocked evidence honestly.
- Promotes repeated friction to durable docs, tests, evals, or action candidates.
