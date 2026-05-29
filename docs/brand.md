# Skill Steward Brand Identity

**Status:** Living reference · **Last updated:** 2026-05-29 (see [ADR 0012](decisions/0012-adopt-visual-brand-identity-system.md))

This document is the practical SSOT for the visual and verbal identity. It is intentionally slim and table-driven. Full strategic rationale, Master Specifications (SVG geometry), and review history live in the originating design document and ADR 0012.

## Essence

Quiet, high-craft expression of **long-term stewardship** over the Agent Skills meta-layer. Patient tending of boundaries and legible structure (growth rings + precise extraction) rather than control or hype. The *absence* of visual noise and the presence of care are the signal.

## Palette

| Role              | Light          | Dark           | Usage |
|-------------------|----------------|----------------|-------|
| Paper / bg        | `#F8F5F0`      | `#0D1110`      | Backgrounds, cards |
| Text (primary)    | `#1F2A26`      | `#E8E4D9`      | Body, headings |
| Steward green (primary) | `#1A3C34` | `#4A7C6F`      | Marks, accents, links |
| Amber (accent)    | `#A67C52`      | `#C5A26F`      | Highlights, "value extracted", warnings (sparingly) |
| Error             | `#5C3A3A`      | —              | Errors only |

**Rules**
- Max 3 colors per surface.
- Warm undertones for long reading comfort ("Developer as User").
- All text/background pairs must pass WCAG AA (target AAA for long-form docs).
- Accent never used for body text.

## Marks (Logo Directions)

1. **Ledger Mark** (primary for docs, README, long-form)  
   "Skill Steward" set in a precise humanist sans with a single thin horizontal rule under "Steward" only. Echoes ADR/MADR record-keeping and citation culture.

2. **Growth Ring Emblem** (favicon, avatar, social lockups)  
   3–4 concentric rings with one precise radial extraction caret (55° from vertical). Visualizes plan hygiene ("extract then remove") and accumulated stewardship.

3. **Lattice Gate** (secondary, builder/ethics emphasis)  
   Highly reduced open rectangular frame of fine lines suggesting both the concept-doc-store lattice and ethical boundaries.

**Shared rules:** Vector masters only. Generous clear space (0.5× mark height). Monochrome + color variants. Never distort, add effects, or combine motifs on one surface. See ADR 0012 for "no personal artisan credit in project visuals".

## Motifs & Illustration Style

Use **one** motif per surface:
- Growth ring + caret
- Thin ledger rule
- Lattice thread

Ultra-minimal line icons only. No gradients, no grain (except faint paper texture on hero rasters), no literal trees/hands/robots/agents, static only.

## Hero / Cover Images

The primary hero direction is a metaphorical still-life that encodes all four pillars without literalism.

**Primary (current):** `docs/brand/assets/hero/skill-steward-growth-rings-hero-16x9.jpg`

**Square emblem variant:** `docs/brand/assets/hero/skill-steward-growth-rings-emblem-square.jpg`

### Primary Prompt (recorded for provenance & regeneration)

```
A single cross-section of an ancient cared-for tree trunk at first light, rendered with exquisite fine detail in its growth rings; one precise radial extraction mark where a clean section of knowledge has been removed; delicate threads of a geometric lattice emerge from the cut and dissolve into soft mist beyond; a single bead of warm amber resin catches the low sunlight exactly at the boundary; deep moss greens, warm umber, cool slate, and generous parchment negative space; ultra-minimal cinematic still-life composition with profound breathing room; no figures, no tools, no text; evokes patient multi-generational stewardship, ethical clarity of boundaries, and the quiet high-craft of builders who leave durable structure behind; filmic natural light, subtle texture, restrained emotional depth, square or 16:9.
```

Two alternate prompts exist in ADR 0012 and the originating design document (Ledger + Lattice; Boundary Gate + Grove).

**Hero production rules** (see design document for full checklist):
- Target 1280×640 (or 1200×630) + appropriate crops.
- Post-optimization budgets: <150 KiB wide, <80 KiB for other variants.
- Include provenance (generation date, prompt version, tool) in commit or adjacent `PROVENANCE.md`.
- Always generate mono + dark variants when updating the primary.

## Tone of Voice (Refinements)

Stay extremely close to the existing voice (tables for boundaries/ownership, imperatives for rituals, "forbidden" for anti-patterns, constant citation).

**Avoid:** Marketing hype, "unlock", "powerful", "revolutionary".

**Prefer:** Precise care. "This belongs here / does not belong here" stated plainly as kindness. Credit to prior work and builders.

Example (install surface):
> Install the meta-skills that help teams keep the Agent Skills ecosystem legible: `npx skills add arenukvern/skill_steward`.

## Usage by Surface

- **README / GitHub** — Hero image at top + Ledger or Growth Ring wordmark. Static light-mode primary.
- **docs.page** — `socialPreview` + theme.primary wired in `docs.json`. Logo when vector masters exist.
- **CLI** — ANSI approximations of green/amber from tokens (zero-dependency).
- **Favicon / avatar** — Growth Ring Emblem (optimized PNG + SVG source).
- **Skills & releases** — One motif only, generous whitespace, cite this document on major changes.

## Governance

- All visual changes must cite ADR 0012 and this document.
- Assets live under `docs/brand/assets/` only.
- **Do not** extend `pnpm run validate`, `scripts/validate-skills.mjs`, or the steward CLI for brand assets. Governance is human + docs checklist + `CONTRIBUTING.md`.
- Significant changes require a changeset (ADR 0009) when public-facing.
- Plan hygiene applies: extract learnings into this file or a new ADR, then remove temporary experiments.

## References

- [ADR 0012 — Adopt visual brand identity system](decisions/0012-adopt-visual-brand-identity-system.md)
- Originating design document (full Master Specifications, 5-PR plan, review notes) — extracted per plan hygiene on adoption.
- [NORTH_STAR.md](NORTH_STAR.md)
- [DESIGN_FAQ.md](DESIGN_FAQ.md)
- Maintainer's principles: https://dev.to/arenukvern/my-principles-at-work-credo-182c

---

*This brand exists to surface the rituals, not to decorate them.*
