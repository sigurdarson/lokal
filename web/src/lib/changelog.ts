import { marked } from 'marked'
import changelogMarkdown from '../../../CHANGELOG.md?raw'

/**
 * CHANGELOG.md, rendered to HTML. This runs at build time because every page is prerendered.
 * The first heading is dropped: the page supplies its own.
 */
export function renderChangelog(): string {
  const withoutTitle = changelogMarkdown.replace(/^# .*\n+/, '')
  return marked.parse(withoutTitle, { async: false, gfm: true })
}
