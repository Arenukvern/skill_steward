# Cursor command templates

## update-faq.md

```markdown
Update DESIGN_FAQ and DX_FAQ for changes in this session.

Goals:
- Concise docs — key decisions only, not essays
- DESIGN_FAQ: WHY (2–3 sentences per answer)
- DX_FAQ: HOW (Memory Palace locations + code)
- No duplication between files
- Verify against the actual codebase

Check both FAQs; add, edit, or remove Q&As as needed.
```

## use-faq-diagram.md

```markdown
Read DESIGN_FAQ, DX_FAQ, and the architecture diagram for this area.
Confirm FAQs match reusable modules and boundaries. List gaps or stale Q&As.
```

## update-faq-packages.md

```markdown
Create or update DESIGN_FAQ and DX_FAQ in each listed package.
Parent FAQs: add brief router entries only — do not duplicate package content.
Package FAQs: focus on that package's why/how only.
```
