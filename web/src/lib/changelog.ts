import { marked } from 'marked'
import changelogMarkdown from '../../../CHANGELOG.md?raw'

// External links inside entries open in a new tab, like every other external link on the site.
marked.use({
  renderer: {
    link({ href, title, tokens }) {
      const text = this.parser.parseInline(tokens)
      const external = /^https?:\/\//.test(href) && !href.startsWith('https://lokal.sigurdarson.is')
      const attributes = [`href="${href}"`, title ? `title="${title}"` : '', external ? 'target="_blank" rel="noreferrer"' : '']
      return `<a ${attributes.filter(Boolean).join(' ')}>${text}</a>`
    },
  },
})

export type ReleaseSection = { title: string; items: string[] }
export type Release = { version: string; date?: string; url?: string; sections: ReleaseSection[] }

/**
 * Parses the Keep a Changelog file into releases. Runs at build time because the pages are prerendered.
 * Items keep inline markdown (links, code) and are rendered to HTML with marked.
 */
export function parseChangelog(markdown: string = changelogMarkdown): Release[] {
  const references = new Map<string, string>()
  for (const match of markdown.matchAll(/^\[([^\]]+)\]:\s*(\S+)\s*$/gm)) {
    references.set(match[1], match[2])
  }

  const releases: Release[] = []
  let release: Release | null = null
  let section: ReleaseSection | null = null

  for (const raw of markdown.split('\n')) {
    const line = raw.replace(/\s+$/, '')
    const heading = /^## \[([^\]]+)\](?:\s*-\s*(\d{4}-\d{2}-\d{2}))?/.exec(line)
    if (heading) {
      release = { version: heading[1], date: heading[2], url: references.get(heading[1]), sections: [] }
      releases.push(release)
      section = null
      continue
    }
    if (!release) continue
    const sub = /^### (.+)/.exec(line)
    if (sub) {
      section = { title: sub[1].trim(), items: [] }
      release.sections.push(section)
      continue
    }
    if (!section) continue
    const item = /^- (.+)/.exec(line)
    if (item) {
      section.items.push(item[1])
    } else if (/^\s+\S/.test(line) && section.items.length > 0) {
      section.items[section.items.length - 1] += ' ' + line.trim()
    }
  }
  return releases
}

export function renderInline(markdown: string): string {
  return marked.parseInline(markdown, { async: false, gfm: true })
}

export function formatDate(iso: string): string {
  const [year, month, day] = iso.split('-').map(Number)
  return new Intl.DateTimeFormat('en-GB', { day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC' }).format(
    new Date(Date.UTC(year, month - 1, day)),
  )
}
