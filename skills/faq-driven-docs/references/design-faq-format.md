# DESIGN_FAQ format

**Purpose:** Shortest useful **why** for maintainers and AI agents.

## Template

```markdown
# Design Decisions FAQ

Quick reference for architectural choices and rationale. Focus: **Why**, not how to use the API.

## {Section name}

**Q: {Specific question about a decision}?**
A: {What was decided}. {Primary trade-off or constraint}. {Performance or maintenance implication if any}.
```

## Good vs weak

| Weak | Strong |
|------|--------|
| "We use archetypes." | "Archetype storage optimizes iteration (hot path) over mutation (cold path); migration cost is acceptable for 60fps loops." |
| Long comparison essay | 2–3 sentences: decision + trade-off + context |

## Package-level header

When the file documents a sub-package:

```markdown
# Design Decisions FAQ - {Package Name}

Focus: **Why** this package exists. See `{parent}/DESIGN_FAQ.md` for core architecture.
```

## Status block (optional)

Use when branch/baseline matters:

```markdown
## Status
- Status: `accepted baseline`
- Branch: `main`
```
