# Agent Guild — Skills standards

This document consolidates rules from the open ecosystem so skills in this repo install reliably via `npx skills` and appear on [skills.sh](https://skills.sh).

## Primary references

| Source | URL |
|--------|-----|
| Agent Skills spec | https://agentskills.io/ |
| Specification (full) | https://github.com/agentskills/agentskills/blob/main/docs/specification.mdx |
| Vercel skills CLI | https://github.com/vercel-labs/skills |
| Cursor skills docs | https://cursor.com/docs/skills |
| skills.sh registry | https://skills.sh |

## Skill package structure

```
skill-name/
├── SKILL.md          # Required
├── scripts/          # Optional — executable helpers
├── references/       # Optional — docs loaded on demand
├── assets/           # Optional — templates, images, data
└── LICENSE           # Optional — if not MIT at repo root
```

## SKILL.md

### Frontmatter (YAML between `---` markers)

| Field | Required | Constraints |
|-------|----------|-------------|
| `name` | Yes | 1–64 chars; `a-z`, `0-9`, `-` only; no leading/trailing `-`; no `--`; **must match parent directory** |
| `description` | Yes | 1–1024 chars; what it does **and** when to use it |
| `license` | No | SPDX id or pointer to bundled license file |
| `compatibility` | No | Max 500 chars; env / product requirements |
| `metadata` | No | String key-value map (`author`, `version`, `category`, `tags`) |
| `allowed-tools` | No | Experimental; space-separated tool list |

### Cursor extensions (optional, portable agents ignore)

| Field | Purpose |
|-------|---------|
| `paths` | Glob list — skill only surfaces for matching files |
| `disable-model-invocation` | `true` = user must invoke `/skill-name` manually |

### Claude Code extensions (optional)

| Field | Purpose |
|-------|---------|
| `argument-hint` | Autocomplete hint for `/skill` args |
| `user-invocable` | `false` hides from `/` menu |
| `context` | `fork` runs in isolated subagent |

### Body (Markdown)

- No strict schema; write clear step-by-step instructions.
- Recommended: **&lt; 500 lines** in `SKILL.md`; split long content into `references/`.
- Progressive disclosure: metadata (~100 tokens) → full SKILL.md on activation → files on demand.

## Repository conventions (this marketplace)

1. All installable skills live under **`skills/{name}/`**.
2. One skill per directory; directory name = `name` field.
3. Root **`skills.sh.json`** lists groupings for the skills.sh directory UI.
4. Root **`README.md`** documents install commands and the skill catalog.
5. **`AGENTS.md`** guides AI contributors; keep in sync with this doc.

## Installation (end users)

```bash
# All skills
npx skills add <owner>/agent_guild

# One skill
npx skills add <owner>/agent_guild --skill create-skill

# List without installing
npx skills add <owner>/agent_guild --list

# Agents: cursor, claude-code, codex, windsurf, github-copilot, …
npx skills add <owner>/agent_guild -a cursor -y
```

### Install scopes

| Scope | Flag | Location |
|-------|------|----------|
| Project | (default) | `.agents/skills/` (+ symlinks to agent dirs) |
| Global | `-g` | `~/.agents/skills/` |

## Validation checklist

Before merging:

- [ ] `name` matches directory name and naming rules
- [ ] `description` includes trigger phrases
- [ ] No `README.md` inside skill folder (agents ignore it; use `references/` instead)
- [ ] `npm run validate` passes
- [ ] Skill listed in `skills.sh.json` and root `README.md`
- [ ] No secrets, API keys, or machine-specific absolute paths

## Official validator (optional)

```bash
# Python reference implementation from agentskills/agentskills
uv tool install skills-ref
skills-ref validate ./skills/my-skill
```

This repo ships `scripts/validate-skills.mjs` for CI without Python.
