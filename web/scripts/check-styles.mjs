#!/usr/bin/env node
// Enforces web/DESIGN.md:
//  1. Every semantic colour token meets the WCAG tier in its name on every surface of its theme.
//  2. Only tokens.css defines colours; CSS and TSX use tokens, CSS never uses px.
//     TSX may carry oklch() only where CSS cannot reach (theme-color meta), never other colour syntaxes.
import { readFileSync, readdirSync, statSync } from 'node:fs'
import { join, relative } from 'node:path'

const root = new URL('..', import.meta.url).pathname
const tokensPath = join(root, 'src/styles/tokens.css')
const tokensCss = readFileSync(tokensPath, 'utf8')

/** Tier is the trailing suffix. `nontext-` roles use the WCAG 1.4.11 non-text minimum for `-aa`. */
function tierFor(token) {
  if (token.endsWith('-aaa')) return { name: 'aaa', minimum: 7 }
  if (token.endsWith('-aa')) return token.startsWith('nontext-') ? { name: 'aa (non-text)', minimum: 3 } : { name: 'aa', minimum: 4.5 }
  return null
}
const failures = []

// ---- 1. Contrast ---------------------------------------------------------------------------

/** Relative luminance of an achromatic OKLCH colour is L³. Chromatic colours are not allowed. */
function luminance(oklch) {
  const match = /oklch\(\s*([\d.]+)\s+([\d.]+)\s+([\d.]+)/.exec(oklch)
  if (!match) throw new Error(`Not an oklch() literal: ${oklch}`)
  if (Number(match[2]) !== 0) throw new Error(`Chroma must be 0 (grays only): ${oklch}`)
  return Number(match[1]) ** 3
}

function contrast(a, b) {
  const [hi, lo] = a > b ? [a, b] : [b, a]
  return (hi + 0.05) / (lo + 0.05)
}

/** Splits the light `:root` block from the dark override and reads `--name: value;` pairs. */
function parseThemes(css) {
  const blocks = [...css.matchAll(/:root\s*\{([^}]*)\}/g)].map((m) => m[1])
  const read = (block) =>
    Object.fromEntries([...block.matchAll(/--([\w-]+)\s*:\s*([^;]+);/g)].map((m) => [m[1], m[2].trim()]))
  const light = read(blocks[0])
  const dark = { ...light, ...read(blocks[1] ?? '') }
  return { light, dark }
}

function resolve(theme, value) {
  if (/color-mix\(/.test(value)) throw new Error(`Cannot measure a translucent value: ${value}`)
  const ref = /var\(--([\w-]+)\)/.exec(value)
  return ref ? resolve(theme, theme[ref[1]]) : value
}

const themes = parseThemes(tokensCss)
const primitives = Object.keys(themes.light).filter((k) => k.startsWith('gray-'))
const rows = []

for (const [themeName, theme] of Object.entries(themes)) {
  // Decorative surfaces are translucent washes over a real surface; they do not set a background of their own.
  const surfaces = Object.keys(theme).filter(
    (k) => k.startsWith('surface-') && k !== 'surface-inverse' && !k.endsWith('-decorative'),
  )
  const foregrounds = Object.keys(theme).filter((k) => k.startsWith('text-') || k.startsWith('nontext-'))
  for (const token of foregrounds) {
    const tier = tierFor(token)
    if (!tier) {
      failures.push(`${themeName}: --${token} has no tier suffix (-aaa or -aa)`)
      continue
    }
    const against = token.includes('on-inverse') ? ['surface-inverse'] : surfaces
    const fg = luminance(resolve(theme, theme[token]))
    let worst = Infinity
    let worstSurface = ''
    for (const surface of against) {
      const ratio = contrast(fg, luminance(resolve(theme, theme[surface])))
      if (ratio < worst) [worst, worstSurface] = [ratio, surface]
    }
    rows.push({ theme: themeName, token, worst: worst.toFixed(2), surface: worstSurface, minimum: tier.minimum })
    if (worst < tier.minimum) {
      failures.push(`${themeName}: --${token} is ${worst.toFixed(2)}:1 on --${worstSurface}, needs ${tier.minimum}:1`)
    }
  }
}

// ---- 2. Lint component CSS -----------------------------------------------------------------

function walk(dir) {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name)
    return statSync(path).isDirectory() ? walk(path) : /\.(css|tsx?)$/.test(path) ? [path] : []
  })
}

const colourLiteral = /#[0-9a-f]{3,8}\b|\b(rgb|rgba|hsl|hsla|lab|lch|hwb)\(|\b(white|black|red|blue|gray|grey)\b(?!-)/i
for (const file of walk(join(root, 'src'))) {
  const rel = relative(root, file)
  const isCss = file.endsWith('.css')
  const source = readFileSync(file, 'utf8')
  source.split('\n').forEach((line, index) => {
    const where = `${rel}:${index + 1}`
    const code = line.replace(/\/\*.*?\*\//g, '').replace(/\/\/.*$/, '')
    if (colourLiteral.test(code)) failures.push(`${where}: colour literal, use a token (${code.trim()})`)
    if (!isCss) return
    if (/\b\d*\.?\d+px\b/.test(code)) failures.push(`${where}: px value, use rem (${code.trim()})`)
    if (file !== tokensPath && /oklch\(/.test(code)) failures.push(`${where}: oklch() outside tokens.css (${code.trim()})`)
    if (file !== tokensPath && /var\(--gray-\d+\)/.test(code)) failures.push(`${where}: primitive used directly, use a semantic token`)
  })
}

// ---- Report -------------------------------------------------------------------------------

console.log(`Primitives: ${primitives.length} grays. Contrast, worst surface per token:`)
for (const r of rows) {
  const ok = Number(r.worst) >= r.minimum ? 'ok ' : 'LOW'
  console.log(`  ${ok} ${r.theme.padEnd(5)} --${r.token.padEnd(20)} ${String(r.worst).padStart(6)}:1 on --${r.surface} (min ${r.minimum})`)
}
if (failures.length) {
  console.error(`\n${failures.length} problem(s):`)
  for (const f of failures) console.error(`  - ${f}`)
  process.exit(1)
}
console.log('\nStyles check passed.')
