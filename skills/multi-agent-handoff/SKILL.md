---
name: multi-agent-handoff
description: Plan and document handoffs between specialized AI agents (foreman, workers, reviewers). Use for multi-agent workflows, subagent delegation, baton passes, or guild-style agent coordination.
license: MIT
type: governance
metadata:
  author: skill-steward
  version: "1.0.0"
  category: multi-agent
---

# Multi-agent handoff

Structure work so multiple agents can execute sequentially without losing context.

## When to use

- Splitting a large task across explorer, implementer, and reviewer agents
- Foreman/worker or parent/subagent patterns
- Need a written baton between chat sessions or tools

## Handoff document template

Create or update `HANDOFF.md` (or a section in the task issue) with:

```markdown
## Goal
{one sentence outcome}

## Done
- {completed items}

## Next
1. {ordered steps for the receiving agent}

## Constraints
- {tech stack, style, files not to touch}

## Verification
- {commands or checks that must pass}

## Validation status
- {commands run}
- {commands skipped or blocked, with reason}
- {blocked JSON explained with `steward blocked explain --input <path> --json`, when available}
- {schema/output drift checked with `steward schema check-outputs --json`, when machine-readable output is part of the handoff}
- {claims not proven because validation was skipped or blocked}

## Partial results
- {missing, partial, superseded, or timed-out agents/lenses}

## Context links
- {paths, PRs, prior decisions}

## Artifact capture
- {ADR, FAQ, skill, evidence note, test, validator, generator, or check that should absorb durable learning}
```

## Workflow

1. **Decompose** — break the goal into independent slices where possible.
2. **Assign roles** — e.g. Explore (read-only), Implement (write), Review (read-only critique).
3. **Write baton** — fill the template; keep "Next" to ≤7 concrete steps.
4. **Execute one slice** — receiving agent does only "Next"; updates "Done".
5. **Record proof** — update validation status before claiming completion. Skipped checks and blocked generators are non-proof, not quiet success.
6. **Capture durable learning** — if a finding changes future behavior, route it to an ADR, FAQ, skill, evidence note, validator, generator, test, or check.
7. **Re-handoff** — pass updated `HANDOFF.md` to the next agent or subagent.
8. **Close** — delete or archive handoff file when goal is verified.

## Anti-patterns

- Vague "continue working on X" without file paths or acceptance criteria
- Handoffs longer than one screen (split into `references/` or issues)
- Duplicate conflicting instructions across parent and child agents
- Subagents that repeat the parent plan instead of looking for contradiction, stale assumptions, missing evidence, or smaller deletable designs
- Final handoffs that sound complete while validation is skipped, blocked, or only manually inferred

## Subagent hints (Codex / Cursor / Zed)

- Use read-only agents for exploration and review
- Pass the handoff block verbatim in the subagent prompt
- Prefer `disable-model-invocation: true` on skills that must run only when invoked
- For parallel work, keep agent scopes non-overlapping and declare write ownership before implementation.
- Useful reviewer roles include `Repo Truth Verifier`, `Boundary Leak Reviewer`, `Evidence Ladder Reviewer`, `Doc Collapse Reviewer`, `Harness QA Reviewer`, and `Stale External Assumption Reviewer`.
- Codex custom agents live in `.codex/agents/*.toml` or `~/.codex/agents/*.toml`; define `name`, `description`, and `developer_instructions`, and spawn subagents only when the user explicitly asks for subagent delegation.
- Cursor custom subagents live in `.cursor/agents/*.md` or `~/.cursor/agents/*.md`; each run has isolated context, and background/parallel execution is useful for independent slices.
- Zed parallel work uses separate agent threads or worktrees; use skills for repeatable single-context procedures and threads for independent concurrent work.

## Install

```bash
npx skills add arenukvern/skill_steward --skill multi-agent-handoff
```

## Sources

See [references/sources.md](references/sources.md). When researching, follow `skill-source-citations`.
