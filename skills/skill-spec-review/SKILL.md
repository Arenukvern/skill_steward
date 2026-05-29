---
name: skill-spec-review
description: Audit SKILL.md and skill directories for Agent Skills spec, Cursor extensions, and npx skills compatibility. Use when reviewing a skill, validating frontmatter, or checking marketplace readiness.
license: MIT
metadata:
  author: agent-guild
  version: "1.0.0"
  category: marketplace
paths:
  - "skills/**/SKILL.md"
  - "**/SKILL.md"
---

# Skill spec review

Review a skill package before merge or publish to skills.sh.

## When to use

- "Review this skill"
- "Is this SKILL.md valid?"
- PR touches `skills/*/SKILL.md`
- Preparing a repo for `npx skills add`

## Review checklist

### Structure

- [ ] Directory name is `kebab-case` and matches `name` in frontmatter
- [ ] File is exactly `SKILL.md` (case-sensitive)
- [ ] No `README.md` inside the skill folder (use `references/`)

### Frontmatter (required)

- [ ] `name`: 1–64 chars, `[a-z0-9-]`, no leading/trailing `-`, no `--`
- [ ] `description`: 1–1024 chars, states capability **and** when to activate

### Frontmatter (recommended)

- [ ] `license` set if not repo MIT
- [ ] `metadata.version` and `metadata.author`
- [ ] `compatibility` if skill needs git, network, docker, or a specific product

### Body

- [ ] Clear numbered workflow
- [ ] Under ~500 lines (or split to `references/`)
- [ ] Relative file links one level deep
- [ ] Install command documented: `npx skills add <owner>/<repo> --skill <name>`

### Scripts (if present)

- [ ] Shebang present (`bash` or `node`)
- [ ] `set -euo pipefail` for bash
- [ ] stderr for logs, stdout for machine-readable output

### Registry (this repo)

- [ ] Skill id in `skills.sh.json`
- [ ] Row in root `README.md` table
- [ ] `npm run validate` passes

## Output format

Report as:

```
## Summary
{pass | needs changes}

## Errors (blocking)
- ...

## Warnings
- ...

## Suggestions
- ...
```

## References

- Repo standards: `docs/STANDARDS.md`
- Open spec: https://agentskills.io/

## Install

```bash
npx skills add <owner>/agent_guild --skill skill-spec-review
```
