# Vector Masters — Skill Steward Brand

These are the **canonical source-of-truth SVG files** for the three logo directions.

All other assets (favicons, inline usage, social lockups, monochrome versions) should be derived from these masters.

## Files

| File                        | Direction          | Primary Use Cases                     | Notes |
|-----------------------------|--------------------|---------------------------------------|-------|
| `growth-ring-emblem.svg`    | Growth Ring        | Favicon, avatar, social lockup, small marks | Most distinctive symbol. Uses `currentColor`. |
| `ledger-mark.svg`           | Ledger             | README headers, documentation, long-form | Typographic + rule. Best for text-heavy surfaces. |
| `lattice-gate.svg`          | Lattice Gate       | Secondary / builder emphasis          | More geometric, open frame. |
| `badge-light.svg`           | Badge (Light)      | Status badge for light-mode READMEs    | Warm Paper background with Steward Green outline and text. |
| `badge-dark.svg`            | Badge (Dark)       | Status badge for dark-mode READMEs     | Near-black background with Green outline and Amber text. |
| `badge-solid.svg`           | Badge (Solid)      | Status badge for high visibility       | Solid Steward Green background with Amber text. |

## Technical Rules (from Master Specifications)

- Canonical viewBox: `200 200` for emblem/gate, custom for ledger.
- All marks use `currentColor` so they inherit the text/accent color of their context.
- Stroke alignment optimized for crisp rasterization at small sizes.
- Clear space: minimum 0.5× the height of a capital "S" on all sides.
- Never distort, add effects, or combine multiple motifs on one surface.

## Usage Examples

### Inline in Markdown / HTML (recommended)

```html
<img src="docs/brand/assets/svg/growth-ring-emblem.svg" alt="Skill Steward" width="32" height="32" />
```

Or embed directly for best control:

```html
<svg width="32" height="32" role="img" aria-label="Skill Steward">
  <use href="docs/brand/assets/svg/growth-ring-emblem.svg#growth-ring" />
</svg>
```

### CSS (color inheritance)

```css
.brand-mark {
  color: #1A3C34; /* steward green */
  width: 1.5em;
  height: 1.5em;
}
```

### Dark / Monochrome

The marks work on dark backgrounds when the parent sets `color: white` or similar. For true monochrome exports, the SVGs can be processed with tools like `svgo` + color replacement.

### Repository Status Badges ("Maintained with Skill Steward")

To showcase that a repository or skill package is actively governed and validated with Skill Steward, you can display one of the official badges in your README.

#### Option 1: Brand-Aligned Custom SVGs (Recommended)
These SVGs are hosted in this repository and can be directly linked or embedded.

**Light Mode Pill:**
```markdown
[![maintained with Skill Steward](https://raw.githubusercontent.com/Arenukvern/skill_steward/main/docs/brand/assets/svg/badge-light.svg)](https://github.com/Arenukvern/skill_steward)
```

**Dark Mode Pill:**
```markdown
[![maintained with Skill Steward](https://raw.githubusercontent.com/Arenukvern/skill_steward/main/docs/brand/assets/svg/badge-dark.svg)](https://github.com/Arenukvern/skill_steward)
```

**Solid Green Pill:**
```markdown
[![maintained with Skill Steward](https://raw.githubusercontent.com/Arenukvern/skill_steward/main/docs/brand/assets/svg/badge-solid.svg)](https://github.com/Arenukvern/skill_steward)
```

#### Option 2: Shields.io Dynamic Badge
If you prefer a standard Shields.io badge, you can use the custom-styled Shields.io link encoding the Growth Ring Emblem in base64:

```markdown
[![maintained with Skill Steward](https://img.shields.io/badge/maintained%20with-Skill%20Steward-1A3C34?logo=data:image/svg%2Bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyMDAgMjAwIj48ZyBmaWxsPSJub25lIiBzdHJva2U9IndoaXRlIiBzdHJva2UtbGluZWNhcD0icm91bmQiPjxjaXJjbGUgY3g9IjEwMCIgY3k9IjEwMCIgcj0iODgiIHN0cm9rZS13aWR0aD0iMTIiIHN0cm9rZS1kYXNoYXJyYXk9IjQ4MCA4NSIgc3Ryb2tlLWRhc2hvZmZzZXQ9Ii00MiIvPjxjaXJjbGUgY3g9IjEwMCIgY3k9IjEwMCIgcj0iNjgiIHN0cm9rZS13aWR0aD0iMSIgc3Ryb2tlLWRhc2hhcnJheT0iMzcwIDY1IiBzdHJva2UtZGFzaG9mZnNldD0iLTMyIi8+PGNpcmNsZSBjeD0iMTAwIiBjeT0iMTAwIiByPSI0OCIgc3Ryb2tlLXdpZHRoPSI3IiBzdHJva2UtZGFzaGFycmF5PSIyNjAgNTAiIHN0cm9rZS1kYXNob2Zmc2V0PSItMjMiLz48Y2lyY2xlIGN4PSIxMDAiIGN5PSIxMDAiIHI9IjI4IiBzdHJva2Utd2lkdGg9IjUiIHN0cm9rZS1kYXNoYXJyYXk9IjE1MCAzNSIgc3Ryb2tlLWRhc2hvZmZzZXQ9Ii0xNSIvPjxsaW5lIHgxPSIxMDAiIHkxPSIxMDAiIHgyPSIxNTUuOCIgeTI9IjQ1LjIiIHN0cm9rZS13aWR0aD0iNSIgc3Ryb2tlLWxpbmVjYXA9InNxdWFyZSIvPjwvZz48L3N2Zz4=)](https://github.com/Arenukvern/skill_steward)
```

## Generation Notes

These files were created from the exact geometry and rules defined in:

- [ADR 0012](../../../decisions/0012-adopt-visual-brand-identity-system.md)
- The Brand Identity Design document (extracted per plan hygiene)

The Growth Ring Emblem uses `stroke-dasharray` for clean, minimal gaps around the extraction caret. The caret itself is a radial line with square caps.

## Future Work

- Generate optimized multi-size PNG / ICO favicon sets from these masters.
- Create official "mono" and "reversed" variants if needed.
- Add the Growth Ring Emblem as the official GitHub repository icon (once approved).

Do not edit these files directly without also updating the specifications in the design record.
