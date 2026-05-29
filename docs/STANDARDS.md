# Skill Steward — Skills standards

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
├── references/       # Optional — docs loaded on demand
│   └── sources.md    # Required in skill_steward — curated URLs + changelog
├── scripts/          # Optional — executable helpers
├── assets/           # Optional — templates, images, data
└── LICENSE           # Optional — if not MIT at repo root
```

### Citations (skill_steward)

Every skill must include **`references/sources.md`** listing URLs for specs, papers, and reference repos used. Update when research changes. Skill: `skill-source-citations`.

### Eval tiers ([ADR 0011](decisions/0011-tiered-skill-evals-and-rule-based-ci.md))

| Tier | Skills | Required |
|------|--------|----------|
| **1 — Behavioral** | `north-star-governance`, `harness-engineering-culture`, `mcp-harness-repo-maintainer`, `create-skill` | `references/evals.md` + ≥2 files in `evals/cases/*.yaml`; `pnpm run eval` passes |
| **2 — Structural** | All other skills under `skills/` | `pnpm run validate`; optional `evals.md` when behavior-critical |

Case schema: [eval-case-schema.md](../skills/skill-eval-improve/references/eval-case-schema.md). Skill: `skill-eval-improve`.

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
npx skills add arenukvern/skill_steward

# One skill
npx skills add arenukvern/skill_steward --skill create-skill

# List without installing
npx skills add arenukvern/skill_steward --list

# Agents: cursor, claude-code, codex, windsurf, github-copilot, …
npx skills add arenukvern/skill_steward -a cursor -y
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
- [ ] `pnpm run validate` passes
- [ ] **Tier 1 only:** `pnpm run eval` passes; `evals/cases/` updated if routing/description changed
- [ ] Skill listed in `skills.sh.json` and root `README.md`
- [ ] No secrets, API keys, or machine-specific absolute paths

## Official validator (optional)

```bash
# Python reference implementation from agentskills/agentskills
uv tool install skills-ref
skills-ref validate ./skills/my-skill
```

This repo ships `scripts/validate-skills.mjs` and `scripts/eval-skill.mjs` (Tier 1 rule-based cases) for CI without Python.

```bash
pnpm run validate    # all skills — structure
pnpm run eval        # Tier 1 — evals/cases/*.yaml rules only
pnpm run eval:json   # machine-readable output
```
