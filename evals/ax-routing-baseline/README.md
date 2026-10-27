# AX routing baseline (Skill Steward guild skills)

**Not live agent evals.** This folder holds a held-out routing prompt set, behavior scenarios, and draft behavioral cases. Pass rates in `results/` come from a **deterministic description-based router** (`run_description_routing.dart`), not from agent sessions. Identical inputs produce identical outputs across repeated runs (no LLM variance).

## Run

From repo root (after `dart pub get` in `packages/steward_cli`):

```bash
# Requires Dart SDK on PATH (CI uses setup-dart).
dart run packages/steward_cli/bin/ax_description_routing.dart \
  --prompts evals/ax-routing-baseline/routing-prompts.yaml \
  --scenarios evals/ax-routing-baseline/behavior-scenarios.yaml \
  --skills-dir skills \
  --output evals/ax-routing-baseline/results/run.json
```

Signals measured by the substitute router:

| Signal | Substitute coverage |
|--------|---------------------|
| Routing accuracy | Top-1 skill vs `expected_skill` on routing prompts + scenarios |
| Missed blockers | Not measured (needs agent trace) |
| Context KB loaded before acting | Not measured |
| Loops past two | Not measured |

Draft cases in `behavioral-eval-cases-draft.yaml` target future agent/LLM judges; they are **not** executed by `pnpm run eval`.
