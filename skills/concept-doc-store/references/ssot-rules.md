# Single source of truth — anti-duplication

## The failure mode

Docs that **re-explain code** drift immediately. Agents read stale prose instead of examples.

## Rules

1. **Behavior** lives in code, `example/`, `test_app/`, tests — docs **link** only.
2. **Decisions** live in ADRs (or DESIGN_FAQ) — one compressed answer per decision.
3. **Usage patterns** live in DX_FAQ, guides, or skills — short snippets OK if they are the canonical pattern; otherwise link to `examples/`.
4. **Navigation** lives in router — no technical content in `docs_map`.
5. **Machine state** lives in YAML trackers — prose plans reference tracker, not vice versa.
6. **Historical plans** go to `archive/` with “do not execute” banner.

## Link patterns

```markdown
**Authoritative source:** `packages/foo/lib/bar.dart`

See working usage: `examples/baz_demo.dart`

Run verification: `make check-foo`
```

## When prose is allowed

- Trade-offs and rejected alternatives (ADR, DESIGN_FAQ Q&A)
- Box-and-arrow architecture (no method bodies)
- Agent role boundaries (who may edit plans vs code)
- Operational checklists (regression, release) that are not expressible as code

## Review question

Before merging doc changes ask:

> Could a reader get this by opening one file or running one example?

If yes → replace with a link.
