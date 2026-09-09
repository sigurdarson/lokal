import { createFileRoute } from '@tanstack/react-router'
import styles from '~/components/Changelog.module.css'
import { renderChangelog } from '~/lib/changelog'

export const Route = createFileRoute('/changelog')({
  head: () => ({
    meta: [{ title: 'Lokal changelog' }],
  }),
  component: Changelog,
})

const html = renderChangelog()

function Changelog() {
  return (
    <article className={styles.page}>
      <h1>Changelog</h1>
      <p className={styles.intro}>
        Generated from{' '}
        <a href="https://github.com/sigurdarson/lokal/blob/main/CHANGELOG.md">CHANGELOG.md</a> at build time.
        Lokal follows semantic versioning; updates arrive through the app.
      </p>
      <div className={styles.body} dangerouslySetInnerHTML={{ __html: html }} />
    </article>
  )
}
