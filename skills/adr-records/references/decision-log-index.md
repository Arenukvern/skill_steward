# Decision log index pattern

Maintain `docs/decisions/README.mdx` (or the folder’s `README.md`) as the **single index** of all ADRs.

## Table columns

| Column | Purpose |
|--------|---------|
| ADR | Link ` [NNNN](NNNN-slug.md) ` |
| Status | `proposed`, `accepted`, `deprecated`, `superseded` |
| Title | Short title from the ADR heading |
| Date | From frontmatter or file header |

Optional: Tags, Supersedes, Superseded-by

## Example

```markdown
# Architecture Decision Records

We record architecturally significant decisions using [MADR](https://adr.github.io/madr/).
New ADRs: copy [template](adr-template.md) or ask the agent with the `adr-records` skill.

| ADR | Status | Title | Date |
|-----|--------|-------|------|
| [0000](0000-use-markdown-architectural-decision-records.mdx) | accepted | Use Markdown ADRs | 2026-01-15 |
| [0001](0001-use-postgresql.md) | accepted | Use PostgreSQL for persistence | 2026-05-29 |
```

## Bootstrap `0000` ADR

Many repos start with a meta-ADR documenting that the project uses ADRs (see [adr/madr example 0000](https://github.com/adr/madr/blob/develop/template/0000-use-markdown-architectural-decision-records.mdx)).
