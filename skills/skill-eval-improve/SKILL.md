---
name: skill-eval-improve
description: Improves Agent Skills via validate → plugin-eval → prompt evals → bounded SKILL.md edits with held-out gates. Use when tuning one skill's quality or routing—not for bulk repo validate or automated SkillOpt training.
license: MIT
metadata:
  author: skill-steward
  version: "1.0.1"
  category: marketplace
---

# Skill eval & improve

Improve skills **measurably**: baseline → measure → bounded edit → re-validate. Combine **local tooling**, **Codex plugin-eval** (when installed), and **research-backed** loops ([SkillOpt](https://microsoft.github.io/SkillOpt/)).

## When to use

- Skill triggers wrong or never loads (description routing)
- Bloated `SKILL.md`, high token cost, weak outcomes
- After adding a new procedure—need regression checks
- Porting patterns from mcp_flutter / plugin-eval research into Guild skills

## When not to use

- **Bulk repo validation** — e.g. “validate every skill in this repo” → `pnpm run validate` only ([skill-spec-review](../skill-spec-review/SKILL.md) for audit); do not start benchmark or SkillOpt loops.
- **Automated SkillOpt / cluster training** — Guild documents a **manual** bounded-edit loop; no overnight optimizer pipeline.
- **Creating a new skill** — use [create-skill](../create-skill/SKILL.md) first; eval-improve applies after a skill exists.

Cursor scope (optional): activate when editing under `skills/**` or `scripts/validate-skills.mjs`.

## Mixture of experts (evaluation stack)

| Layer | Expert | Tool / method | Cost |
|-------|--------|---------------|------|
| **0 — Gate** | Lint | `pnpm run validate`, `skill-spec-review` | seconds |
| **1 — Static** | Structure | Codex `plugin-eval analyze` (if available) | seconds |
| **2 — Human** | Behavior | 3–5 prompts with/without skill | minutes |
| **3 — Measured** | Usage | `plugin-eval benchmark` + `measurement-plan` | minutes–hours |
| **4 — Evolve** | Text optimization | SkillOpt-style bounded edits + held-out gate | hours |

Use the **cheapest layer that answers the question**. Do not skip layer 0.

## Layer 0 — Guild validator (always)

```bash
pnpm run validate
pnpm run validate:json   # CI / automation
```

Fix all `error:` lines. Treat `warn:` (missing `sources.md`, long SKILL.md) seriously.

## Layer 1 — Codex plugin-eval (local)

When Codex **plugin-eval** is installed (`~/.codex/plugins/.../plugin-eval`):

```bash
# Chat-first router
plugin-eval start skills/<name> --request "Evaluate this skill." --format markdown

# Static report
plugin-eval analyze skills/<name> --format markdown

# Token budget explanation
plugin-eval explain-budget skills/<name> --format markdown

# Starter benchmark config
plugin-eval init-benchmark skills/<name>
plugin-eval benchmark skills/<name> --dry-run
```

Hand off rewrite plans to plugin-eval’s **improve-skill** skill after `analyze --brief-out`.

Details: [references/plugin-eval.md](references/plugin-eval.md).

## Layer 2 — Human prompt suite (required for material edits)

1. Write **3–5 representative user prompts** (should trigger + should not trigger).
2. Run agent **without** skill → record failures.
3. Run **with** skill → record improvements and new failures.
4. Store prompts in `references/evals.md` (not in SKILL.md body).

Split ~60% train (edit against) / 40% held-out (gate acceptance)—mirrors SkillOpt selection gate.

## Layer 3 — SkillOpt-inspired improve loop (research)

[SkillOpt](https://microsoft.github.io/SkillOpt/) treats `SKILL.md` as **trainable text** with a **frozen** agent:

```text
Rollout (tasks + current skill) → Reflect (failures vs successes)
  → Bounded edit (add/delete/replace under budget) → Held-out gate (keep only if better)
```

Guild **manual** adaptation (no GPU cluster required):

| Step | Action |
|------|--------|
| 1 | Baseline: held-out pass rate without skill |
| 2 | With skill: same tasks, log pass rate |
| 3 | Reflect: list 1–3 concrete failure modes |
| 4 | **Bounded edit**: ≤10% line churn or one new section; no wholesale rewrite |
| 5 | Re-run **held-out only**; keep edit only if improved |
| 6 | Record outcome in `references/evals.md` + `sources.md` |

Paper: https://arxiv.org/abs/2605.23904 · Site: https://microsoft.github.io/SkillOpt/

Related: [SkillLens](https://microsoft.github.io/SkillOpt/) (model-generated skills study).

## Layer 4 — Ecosystem benchmarks (2026+)

| Resource | Use |
|----------|-----|
| [SkillsBench](https://arxiv.org/abs/2602.12670) | Inspiration for paired vanilla vs skill-augmented tasks |
| [skillgrade](https://github.com/mgechev/skillgrade) | Regression testing skill quality (mgechev) |
| Claude authoring best practices | Eval-before-write workflow |

## Improve workflow (checklist)

```
- [ ] sources.md cites plugin-eval + SkillOpt if used
- [ ] pnpm run validate
- [ ] plugin-eval analyze (optional)
- [ ] 3+ prompt evals documented in references/evals.md
- [ ] Bounded edit applied; held-out improved
- [ ] skill-spec-review checklist
- [ ] PR mentions eval delta
```

## What to fix first (typical order)

1. `name` / `description` (routing)—must include **what + when**
2. Broken links / missing `references/sources.md`
3. Move bulk to `references/` (SKILL.md &lt; 500 lines)
4. Add error-handling / validation steps agents skip
5. Token cost (description length, always-loaded content)

## Anti-patterns

- Rewriting entire SKILL.md from one failure (destroy working rules)
- Self-editing without held-out prompts (overfit)
- Claims without `references/sources.md` rows
- Evaluating only with static analyze—never running real prompts

## Related skills

| Skill | Role |
|-------|------|
| `skill-source-citations` | Save research links |
| `create-skill` | Scaffold |
| `skill-spec-review` | Pre-merge audit |

## Sources

See [references/sources.md](references/sources.md).

## Install

```bash
npx skills add arenukvern/skill_steward --skill skill-eval-improve
```
