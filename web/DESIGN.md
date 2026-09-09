# Website design rules

These rules apply to everything under `web/`. `pnpm check:styles` enforces them and runs as part of `pnpm build`, so a violation fails CI.

## Colour

- **Only the gray scale exists.** `--gray-50` to `--gray-950`, defined once in `src/styles/tokens.css` as achromatic OKLCH. No other colour may be introduced without changing this document.
- **OKLCH only.** No hex, `rgb()`, `hsl()`, named colours, or any other colour function anywhere in `web/`.
- **Components never use primitives or literals.** Component CSS references semantic tokens (`var(--text-aa)`), never `var(--gray-600)` and never `oklch(...)`. `tokens.css` is the only file allowed to contain `oklch(`.
- **Photographs are content, not colour.** The showcase wallpaper (`public/wallpaper-*.webp`) is the one image on the site. Everything drawn over it still uses the gray tokens.
- **Alpha is the only permitted derivation.** Overlays and shadows may use `color-mix(in oklch, var(--token) N%, transparent)` or an alpha channel on a primitive inside `tokens.css`. No lightening, darkening, or mixing two colours.

## Token naming

Semantic tokens are named `--<role>-<tier>` where the tier states the WCAG 2.2 contrast the token guarantees against **every surface of its theme** (`--surface-page`, `--surface-raised`, `--surface-sunken`). The checker computes the worst case and fails the build if a token is below its tier.

| Token shape | Guarantee | Use for |
|---|---|---|
| `--text-*-aaa` | ≥ 7:1 | Body text, headings, anything read at length |
| `--text-*-aa` | ≥ 4.5:1 | Captions, secondary labels, metadata |
| `--nontext-*-aa` | ≥ 3:1 (WCAG 1.4.11) | Icons, focus rings, borders that convey meaning |
| `--*-decorative` | none | Hairlines and separators that carry no information |

The tier is always the last segment of the name, so it reads at the point of use. Non-colour tokens (`--font-size-*`, `--space-*`) never share a prefix with colour roles.

Text on the inverse surface (`--text-on-inverse-aaa`) is certified against `--surface-inverse` only.

Current assignments and their worst-case ratios:

| Token | Light | Dark |
|---|---|---|
| `--surface-page` / `-raised` / `-sunken` | gray-50 / 100 / 200 | gray-950 / 900 / 800 |
| `--surface-inverse` | gray-900 | gray-50 |
| `--text-aaa` | gray-900, 14.2:1 | gray-50, 14.5:1 |
| `--text-muted-aaa` | gray-700, 8.3:1 | gray-300, 10.2:1 |
| `--text-aa` | gray-600, 6.2:1 | gray-400, 5.8:1 |
| `--text-on-inverse-aaa` | gray-50, 17.2:1 | gray-900, 17.2:1 |
| `--nontext-aa` | gray-500, 3.8:1 | gray-500, 3.2:1 |
| `--border-decorative` | gray-200 | gray-800 |

`--text-aa` exceeds AAA on most surfaces in light mode. That is fine: the suffix is a floor, not a target. `gray-500` on `gray-100` measures 4.34:1, which is why light-mode `-aa` text is `gray-600` and `gray-500` is reserved for `--nontext-aa`.

## Units

- **rem for everything**: sizes, spacing, radii, breakpoints, border widths (`--border-width` is `0.0625rem`), blur radii, shadows. The checker rejects any `px` value in `web/src`.
- Unitless values are fine where CSS expects them: line-height, font-weight, opacity, z-index, flex.
- `em` is acceptable for values that should scale with the local font size, such as letter-spacing, underline offset, and `max-width` on prose (`--measure`).
- Prefer the scale tokens (`--space-*`, `--font-size-*`, `--radius-*`) over ad-hoc rem values. Ad-hoc values are allowed when a token would be a lie, for example optical alignment inside the mock panel.

## Text

- `text-wrap: pretty` is set on `body` and inherits everywhere; headings use `text-wrap: balance`. Do not override either in components.

## Themes

- Light and dark are expressed entirely in `tokens.css` under `prefers-color-scheme`. Component CSS never branches on colour scheme.
- Every surface in a theme must keep every text token at its tier. Add a new surface only after running the checker.

## Motion

- Use `--duration-fast` and `--ease-standard`. `global.css` disables animation and transitions under `prefers-reduced-motion: reduce`; do not override that.

## Adding a token

1. Add it to both themes in `tokens.css` with a tier suffix.
2. Run `pnpm check:styles`. Fix the mapping until every surface passes.
3. Add the row to the table above.
