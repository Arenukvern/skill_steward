# faq_usage.mdc template

Save as `.cursor/rules/faq_usage.mdc`:

```markdown
---
alwaysApply: true
---

# FAQ Documentation Usage Guide

**Q: What is DESIGN_FAQ.md for?**
A: Explains WHY design decisions were made. Use when changing architecture, internals, or performance trade-offs.

**Q: What is DX_FAQ.md for?**
A: Explains HOW to use the API. Use when writing application code or learning usage patterns.

**Q: What format should DX_FAQ.md use?**
A: Memory Palace — spatial locations (emoji + name) with embedded code patterns. Optimized for agent recall.

**Q: When should I reference DESIGN_FAQ.md?**
A: Architectural rationale, trade-offs, flush/order, storage model, package boundaries.

**Q: When should I reference DX_FAQ.md?**
A: Queries, schedules, public API examples, integration steps.

**Q: Can I use both FAQs together?**
A: Yes. DESIGN explains why types exist; DX shows how to use them. No duplication.

**Q: Which FAQ should I update?**
A: DESIGN on architectural changes. DX on public API or developer workflow changes.
```

Customize section names for your domain (plugins, services, etc.).
