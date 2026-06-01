---
name: create-skill
description: Scaffold a new Agent Skill in this marketplace repo with valid SKILL.md, directory layout, and registry entries. Use when adding a skill, creating SKILL.md, or contributing to skill_steward.
license: MIT
metadata:
  author: skill-steward
  version: "1.0.0"
  category: marketplace
---

# Create skill

Add a new installable skill package under `skills/` in the Skill Steward marketplace.

## When to use

- User wants a new skill in this repo
- Contributing to the skills marketplace
- Bootstrapping `SKILL.md` for `npx skills` compatibility

## Workflow

1. **Choose a name** — `kebab-case`, 1–64 chars, matches Agent Skills rules (see `docs/STANDARDS.mdx`).
2. **Create directory** — `skills/{name}/` (directory name must equal `name` in frontmatter).
3. **Copy template** — from `templates/skill/SKILL.md`; replace placeholders.
4. **Write description** — one block covering *what* and *when* (trigger phrases users say).
5. **Cite sources** — create `references/sources.md` from `templates/skill/references/sources.md`; add rows for every spec/repo/paper used ([skill-source-citations](../skill-source-citations/SKILL.md)).
6. **Write body** — numbered steps, examples, output format; keep under 500 lines.
7. **Evals** — Tier 1 skills (see [STANDARDS](../../docs/STANDARDS.mdx)): `references/evals.md` + ≥2 `evals/cases/*.yaml` ([eval-case-schema](../skill-eval-improve/references/eval-case-schema.md)). Others: optional `evals.md`.
8. **Optional** — `scripts/`, `assets/`.
9. **Register skill**:
   - Add skill id to `skills.sh.json` under the right grouping (see [skills.sh customization docs](https://www.skills.sh/docs/customize) for schemas and layout options)
   - Add row to root `README.md` skill table
10. **Validate** — `pnpm run validate`; Tier 1 also `pnpm run eval`.

## Frontmatter template

```yaml
---
name: {same-as-directory}
description: {capability + trigger phrases, 20-1024 chars}
license: MIT
metadata:
  author: skill-steward
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
- [ ] `pnpm run validate` passes
- [ ] Listed in `skills.sh.json` and README
- [ ] `references/sources.md` present with URLs used
- [ ] Optional: `references/evals.md` if behavior-critical

## Related skills

| Task | Skill |
|------|-------|
| Marketplace / private distribution | `plugin-marketplace-setup` |
| MCP/harness repo maintenance | `mcp-harness-repo-maintainer` |
| Citations / sources.md | `skill-source-citations` |
| Eval & improve loop | `skill-eval-improve` |
| Spec audit before PR | `skill-spec-review` |

## Install (end users)

```bash
npx skills add arenukvern/skill_steward --skill create-skill
```

## Sources

See [references/sources.md](references/sources.md). When researching, follow `skill-source-citations`.
