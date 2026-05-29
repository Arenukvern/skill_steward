# AGENTS.md

Guidance for AI coding agents working in the **Agent Guild** skills marketplace.

## Repository purpose

This repo publishes **Agent Skills** — portable `SKILL.md` packages installable via:

```bash
npx skills add <owner>/agent_guild
```

Skills must work across Cursor, Claude Code, Codex, and other agents listed in the [skills CLI](https://github.com/vercel-labs/skills#supported-agents).

## Creating a new skill

### Directory structure

```
skills/
  {skill-name}/           # kebab-case; must match `name` in frontmatter
    SKILL.md              # Required (exact filename, case-sensitive)
    scripts/              # Optional: bash, node (.mjs), python
    references/           # Optional: loaded on demand
    assets/               # Optional: templates, static files
```

### Naming

| Item | Rule |
|------|------|
| Skill directory | `kebab-case`, 1–64 chars, `a-z0-9-`, no leading/trailing `-`, no `--` |
| `SKILL.md` | Uppercase, exact name |
| `name` in frontmatter | Must equal directory name |

### SKILL.md frontmatter (required)

```yaml
---
name: my-skill
description: What it does and when to use it. Include trigger phrases users say.
license: MIT
metadata:
  author: agent-guild
  version: "1.0.0"
---
```

**Description** (1–1024 chars): state capabilities *and* activation triggers. Agents only load name + description until the skill is relevant.

**Optional fields** (portable + Cursor):

| Field | Use |
|-------|-----|
| `license` | SPDX or path to LICENSE in skill folder |
| `compatibility` | Env requirements (git, docker, network, product) |
| `metadata` | String map: `author`, `version`, `category`, `tags` |
| `allowed-tools` | Experimental: pre-approved tools |
| `paths` | Cursor: globs — skill scoped to matching files |
| `disable-model-invocation` | `true` = manual `/skill-name` only |

### Body content

- Keep **SKILL.md under 500 lines**; move detail to `references/`.
- Use numbered steps, clear triggers, and examples.
- Reference files with relative paths one level from skill root.
- Prefer `scripts/` over large inline shell blocks (saves context).

### Scripts

- Bash: `#!/usr/bin/env bash` and `set -euo pipefail`
- Node: `#!/usr/bin/env node` and `.mjs` extension
- Log status to **stderr**; machine output to **stdout**
- Document args in SKILL.md

### After adding a skill

1. Run `npm run validate` from repo root.
2. Add the skill id to `skills.sh.json` under the right grouping.
3. Add a row to `README.md` skill table.
4. Do not commit secrets or environment-specific paths.

### End-user install snippet

Every public skill should document:

```bash
npx skills add <owner>/agent_guild --skill {skill-name}
```

## Validation

CI runs `node scripts/validate-skills.mjs`. Fix all errors before merging.

## Agent install paths (reference)

| Agent | Project | Global |
|-------|---------|--------|
| Cursor | `.cursor/skills/` | `~/.cursor/skills/` |
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |
| Codex | `.codex/skills/` | `~/.codex/skills/` |
| Universal | `.agents/skills/` | `~/.agents/skills/` |

The `npx skills` CLI symlinks from `.agents/skills/` into each agent directory.
