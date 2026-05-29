---
name: create-skill
description: Scaffold a new Agent Skill in this marketplace repo with valid SKILL.md, directory layout, and registry entries. Use when adding a skill, creating SKILL.md, or contributing to agent_guild.
license: MIT
metadata:
  author: agent-guild
  version: "1.0.0"
  category: marketplace
---

# Create skill

Add a new installable skill package under `skills/` in the Agent Guild marketplace.

## When to use

- User wants a new skill in this repo
- Contributing to the skills marketplace
- Bootstrapping `SKILL.md` for `npx skills` compatibility

## Workflow

1. **Choose a name** — `kebab-case`, 1–64 chars, matches Agent Skills rules (see `docs/STANDARDS.md`).
2. **Create directory** — `skills/{name}/` (directory name must equal `name` in frontmatter).
3. **Copy template** — from `templates/skill/SKILL.md`; replace placeholders.
4. **Write description** — one block covering *what* and *when* (trigger phrases users say).
5. **Write body** — numbered steps, examples, output format; keep under 500 lines.
6. **Optional folders** — `scripts/`, `references/`, `assets/` as needed.
7. **Register skill**:
   - Add skill id to `skills.sh.json` under the right grouping
   - Add row to root `README.md` skill table
8. **Validate** — run `npm run validate` from repo root; fix all errors.

## Frontmatter template

```yaml
---
name: {same-as-directory}
description: {capability + trigger phrases, 20-1024 chars}
license: MIT
metadata:
  author: agent-guild
  version: "1.0.0"
  category: {marketplace|multi-agent|...}
---
```

## Cursor-only options (optional)

```yaml
paths:
  - "skills/**"
disable-model-invocation: false
```

## Quality checklist

- [ ] `name` matches folder name
- [ ] Description includes user trigger phrases
- [ ] No `README.md` inside skill folder
- [ ] No secrets or absolute local paths
- [ ] `npm run validate` passes
- [ ] Listed in `skills.sh.json` and README

## Install (end users)

```bash
npx skills add arenukvern/agent_guild --skill create-skill
```
