import { createFileRoute } from '@tanstack/react-router'
import styles from '~/components/Changelog.module.css'
import { formatDate, parseChangelog, renderInline } from '~/lib/changelog'

export const Route = createFileRoute('/changelog')({
  head: () => ({
    meta: [{ title: 'Lokal changelog' }],
  }),
  component: Changelog,
})

const releases = parseChangelog().filter((release) => release.sections.some((section) => section.items.length > 0))

function Changelog() {
  return (
    <article className={styles.page}>
      <header className={styles.intro}>
        <p className={styles.eyebrowLabel}>Changelog</p>
        <h1 className={styles.title}>What changed, release by release.</h1>
        <p className={styles.lede}>
          Lokal follows semantic versioning and updates itself through Sparkle. This page is generated from{' '}
          <a href="https://github.com/sigurdarson/lokal/blob/main/CHANGELOG.md">CHANGELOG.md</a> at build time.
        </p>
      </header>

      <div className={styles.releases}>
        {releases.map((release) => (
          <section key={release.version} className={styles.release} aria-labelledby={`release-${release.version}`}>
            <div className={styles.releaseHeader}>
              <h2 id={`release-${release.version}`} className={styles.version}>
                {release.version === 'Unreleased' ? 'Unreleased' : `Version ${release.version}`}
              </h2>
              <div className={styles.releaseMeta}>
                {release.date ? <time dateTime={release.date}>{formatDate(release.date)}</time> : <span>In progress</span>}
                {release.url ? <a href={release.url}>View on GitHub</a> : null}
              </div>
            </div>
            {release.sections.map((section) => (
              <div key={section.title} className={styles.section}>
                <h3 className={styles.sectionTitle}>{section.title}</h3>
                <ul className={styles.items}>
                  {section.items.map((item) => (
                    <li key={item} dangerouslySetInnerHTML={{ __html: renderInline(item) }} />
                  ))}
                </ul>
              </div>
            ))}
          </section>
        ))}
      </div>
    </article>
  )
}
