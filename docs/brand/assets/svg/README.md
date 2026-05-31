# Vector Masters — Skill Steward Brand

These are the **canonical source-of-truth SVG files** for the three logo directions.

All other assets (favicons, inline usage, social lockups, monochrome versions) should be derived from these masters.

## Files

| File                        | Direction          | Primary Use Cases                     | Notes |
|-----------------------------|--------------------|---------------------------------------|-------|
| `growth-ring-emblem.svg`    | Growth Ring        | Favicon, avatar, social lockup, small marks | Most distinctive symbol. Uses `currentColor`. |
| `ledger-mark.svg`           | Ledger             | README headers, documentation, long-form | Typographic + rule. Best for text-heavy surfaces. |
| `lattice-gate.svg`          | Lattice Gate       | Secondary / builder emphasis          | More geometric, open frame. |

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
