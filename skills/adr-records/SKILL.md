---
name: adr-records
description: Writes and maintains Architecture Decision Records (ADRs) per adr.github.io using MADR, Nygard, or Y-Statement formats. Use when creating or updating ADRs, documenting architecture decisions, superseding decisions, or setting up a decision log in a repository.
license: MIT
metadata:
  author: skill-steward
  version: "1.0.0"
  category: documentation
paths:
  - "docs/**"
  - "doc/**"
  - "**/adr/**"
  - "**/decisions/**"
  - "**/architecture/**"
---

# Architecture Decision Records (adr.github.io)

Maintain a **decision log** of architecturally significant choices using formats from [adr.github.io](https://adr.github.io/).

## When to use

- User asks for an ADR, architecture decision record, or decision log
- Recording a significant design choice (stack, integration, security, data model, deployment)
- Updating ADR status (`accepted`, `deprecated`, `superseded`)
- Aligning an existing repo with MADR / Nygard conventions

## Locate or bootstrap the decision log

Search (in order) for an existing log:

| Path | Notes |
|------|--------|
| `docs/decisions/` | MADR default |
| `doc/adr/` | Common alternative |
| `docs/adr/` | Common alternative |
| `architecture/decisions/` | Monorepos |

If none exists, **ask the user** unless they said to create one. Default new log:

```
docs/decisions/
├── README.md          # Index with table of all ADRs
└── NNNN-title-with-dashes.md
```

Add a one-line pointer in the root `README.md` or `CONTRIBUTING.md` if the project documents contributions.

## Numbering and filenames

- **Format**: `NNNN-kebab-case-title.md` (4-digit zero-padded: `0001`, `0002`, …)
- **Title in file**: problem/solution style — e.g. `Use PostgreSQL for persistence` (MADR guidance)
- **Next number**: highest existing `NNNN` + 1; never reuse numbers

Run from repo root when helpful:

```bash
bash scripts/next-adr-number.sh docs/decisions
```

## Default format: MADR (bare)

Use [MADR bare template](references/madr-bare-template.md) unless the repo already uses Nygard or Y-Statements.

Required sections:

1. YAML frontmatter: `status`, `date`, `decision-makers` (and `consulted` / `informed` when known)
2. Context and Problem Statement
3. Considered Options (list all real alternatives)
4. Decision Outcome — `Chosen option: "…", because …`
5. Consequences — Good / Bad / Neutral
6. Pros and Cons of the Options (per option)
7. More Information (links, follow-ups)

### Status lifecycle

| Status | Meaning |
|--------|---------|
| `proposed` | Under discussion; not yet binding |
| `accepted` | Team agrees; implement accordingly |
| `deprecated` | No longer recommended; may still be in production |
| `superseded` | Replaced — **link** to the new ADR (`Superseded by [NNNN](NNNN-title.md)`) |
| `rejected` | Considered and not adopted (optional) |

When superseding: set old ADR to `superseded` and reference the new number; new ADR should mention what it replaces.

## Alternate formats

| Format | When | Reference |
|--------|------|-----------|
| **Nygard** | Minimal log, small teams | [references/nygard-template.md](references/nygard-template.md) |
| **Y-Statement** | One-line decision in an index or changelog | [references/y-statement.md](references/y-statement.md) |

Match the format already used in the repo. Do not mix formats within one decision log without user approval.

## Authoring workflow

1. **Confirm scope** — one decision per ADR; split if multiple unrelated choices.
2. **Gather** — context, drivers, options considered, who decided, date (ISO `YYYY-MM-DD`).
3. **Draft** — fill template; write options you actually evaluated, not only the winner.
4. **Index** — add row to `docs/decisions/README.md` (see [references/decision-log-index.md](references/decision-log-index.md)).
5. **Cross-link** — issues, PRs, diagrams, superseded ADRs.
6. **Review** — consequences must include downsides (trade-offs, not marketing).

## Decision log index (`README.md`)

Keep a table sorted by number (newest at bottom or top — match existing log):

```markdown
# Architecture Decision Records

| ADR | Status | Title | Date |
|-----|--------|-------|------|
| [0001](0001-use-postgresql.md) | accepted | Use PostgreSQL for persistence | 2026-05-29 |
```

## Quality bar

- **Specific**: names technologies and boundaries; links to code/modules when relevant
- **Honest**: lists rejected options and why they lost
- **Traceable**: status, date, supersede links
- **Concise**: prefer short sections; move long analysis to `More Information` or linked docs
- **No secrets**: no credentials, tokens, or private URLs in ADRs

## Output when creating an ADR

Tell the user:

1. File path created or updated
2. ADR number and title
3. Status
4. Whether index/README was updated
5. Suggested follow-up (implementation task, PR link placeholder)

## Install

```bash
npx skills add arenukvern/skill_steward --skill adr-records
```

## Sources

See [references/sources.md](references/sources.md). When researching, follow `skill-source-citations`.
