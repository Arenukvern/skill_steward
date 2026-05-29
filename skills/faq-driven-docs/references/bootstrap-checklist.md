# Bootstrap checklist — FAQ-driven docs

## New repository

- [ ] Root `DESIGN_FAQ.md` (charter + top 5–10 why decisions)
- [ ] Root `DX_FAQ.md` (getting started + core how patterns)
- [ ] `.cursor/rules/faq_usage.mdc`
- [ ] `.cursor/commands/update-faq.md`
- [ ] `AGENTS.md` router table (paths to both FAQs)
- [ ] Link article: [FAQ-driven development](https://dev.to/arenukvern/faq-driven-development-or-new-old-way-to-write-docs-rules-prompts-25jl)

## New package in monorepo

- [ ] `{package}/DESIGN_FAQ.md`
- [ ] `{package}/DX_FAQ.md`
- [ ] Optional: package-local `.cursor/rules/faq_usage.mdc` if rules differ
- [ ] Parent DESIGN_FAQ + DX_FAQ: 1–3 router Q&As pointing to child files (no duplicate answers)

## After each meaningful PR

- [ ] Architectural change → DESIGN_FAQ Q&A added/updated
- [ ] API change → DX_FAQ location or Q&A updated
- [ ] Stale Q&A removed or marked deprecated in answer
- [ ] Answers still ≤3 sentences (DESIGN) or valid code (DX)
