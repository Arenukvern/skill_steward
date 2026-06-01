# Bootstrap checklist — concept doc store

## Minimal (any repo)

- [ ] `docs/start_here/docs_map.md` or `docs_map.mdx` — Quick Router table
- [ ] `docs/NORTH_STAR.mdx` or `docs/start_here/why_*.mdx` — charter
- [ ] `docs/decisions/` + index — ADR 0000 meta + strategic ADRs
- [ ] `AGENTS.md` — table: question → doc path
- [ ] Root `README.md` — links to router and charter, not full architecture

## Agent-heavy repo

- [ ] `docs/ai_agents/overview.mdx` — three-layer or role model
- [ ] `docs/ai_agents/execution_playbook.mdx` — verify/install gates
- [ ] Skills for repeatable procedures (not architecture)

## Monorepo with packages

- [ ] Per-package `DESIGN_FAQ` + `DX_FAQ` (faq-driven-docs skill)
- [ ] Parent router rows pointing to child FAQs — no duplicate answers

## Long-running agent program

- [ ] `docs/superpowers/specs/` — design SSOT
- [ ] `docs/superpowers/tracker/*.yaml` — phase state
- [ ] `docs/superpowers/WHATS_NEXT.md` — forward index only
- [ ] `docs/superpowers/plans/archive/` — historical, non-executable
- [ ] `docs/superpowers/closure/` — gate evidence template

## After bootstrap

- [ ] ADR documents this doc model (Skill Steward: ADR 0003)
- [ ] CONTRIBUTING mentions which layer to update per change type
