import { createFileRoute } from '@tanstack/react-router'
import { Button } from '~/components/Button'
import { CopyButton } from '~/components/CopyButton'
import { MenuBarClock } from '~/components/MenuBarClock'
import { useEffect, useState } from 'react'
import styles from '~/components/Home.module.css'

export const Route = createFileRoute('/')({
  component: Home,
})

const brew = 'brew install sigurdarson/tap/lokal'

function Home() {
  return (
    <>
      <section className={styles.hero}>
        <h1 className={styles.title}>See what is running on localhost.</h1>
        <p className={styles.lede}>
          Lokal lists every port your machine is listening on, the process behind it, and the project it belongs to.
          Open it, copy the URL, jump to the code, or kill it.
        </p>
        <div className={styles.actions}>
          <Button render={<a href="/download" />}>Download for macOS</Button>
          <div className={styles.brew}>
            <span>$</span>
            <code>{brew}</code>
            <CopyButton text={brew} />
          </div>
        </div>
        <p className={styles.requirements}>macOS 15 or later on Apple silicon. Signed and notarized. No account, no telemetry.</p>
      </section>

      <Showcase />

      <section className={styles.outcomes} id="what-it-does">
        <div className={styles.outcomesIntro}>
          <p className={styles.eyebrowLabel}>What it does</p>
          <h2 className={styles.outcomesTitle}>Everything listening, with the context you actually need.</h2>
          <p className={styles.outcomesLede}>
            Dev servers, databases, containers and the odd forgotten process pile up over a day. Lokal shows what is
            listening, which project each port belongs to, and puts the actions you would otherwise open a terminal
            for one click away.
          </p>
        </div>
        <div className={styles.outcomesGrid}>
          <Feature title="Grouped by project">
            Each port resolves to its manifest and git root, so <code>node</code> on 5173 reads as <em>shop / web</em>.
          </Feature>
          <Feature title="Knows your services">
            Postgres, Redis, Vite, Rails, Docker containers and more, from one JSON file anyone can extend.
          </Feature>
          <Feature title="Actions without a terminal">
            Open, copy the URL, reveal in Finder, open in your editor, or kill with an inline confirmation.
          </Feature>
          <Feature title="Quiet by default">
            Inspectors, internal sockets and apps like Spotify fold away. No background polling, no telemetry.
          </Feature>
        </div>
      </section>

    </>
  )
}

function Feature({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className={styles.outcome}>
      <h3 className={styles.outcomeTitle}>{title}</h3>
      <p className={styles.outcomeBody}>{children}</p>
    </div>
  )
}

/** The top-right corner of a Mac screen, zoomed in: the menu bar with Lokal active, and the panel hanging from it. */
function Showcase() {
  return (
    <div className={styles.showcase}>
      <section className={styles.screen} aria-label="Interactive preview of the Lokal panel open from the macOS menu bar">
        <div className={styles.menubar}>
          <div className={styles.menubarLeft}>
            <span className={styles.menubarApp}>Finder</span>
            <span>File</span>
            <span>Edit</span>
            <span>View</span>
            <span>Go</span>
            <span>Window</span>
            <span>Help</span>
          </div>
          <div className={styles.menubarRight}>
            <span className={styles.statusItemActive}>
              <LokalGlyph />
            </span>
            <span>
              <WifiGlyph />
            </span>
            <span>
              <BatteryGlyph />
            </span>
            <MenuBarClock className={styles.clock} />
          </div>
        </div>
        <div className={styles.desktop}>
          <MockPanel />
        </div>
      </section>
    </div>
  )
}

function LokalGlyph() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" aria-hidden="true">
      <path d="M12 10.5C11.1716 10.5 10.5 11.1716 10.5 12C10.5 12.8284 11.1716 13.5 12 13.5C12.8284 13.5 13.5 12.8284 13.5 12C13.5 11.1716 12.8284 10.5 12 10.5ZM12 10.5V2" />
      <circle cx="12" cy="12" r="10" />
      <path d="M15 8C19.0571 8.52165 22 10.0733 22 11.9063C22 14.1672 17.5228 16 12 16C6.47715 16 2 14.1672 2 11.9063C2 10.0733 4.94289 8.52165 9 8" />
    </svg>
  )
}

function WifiGlyph() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" aria-hidden="true">
      <path d="M1.5 6.2a10 10 0 0 1 13 0M4 8.8a6.2 6.2 0 0 1 8 0M6.4 11.4a2.6 2.6 0 0 1 3.2 0" />
      <circle cx="8" cy="13.4" r="0.9" fill="currentColor" stroke="none" />
    </svg>
  )
}

function BatteryGlyph() {
  return (
    <svg width="22" height="12" viewBox="0 0 22 12" fill="none" stroke="currentColor" strokeWidth="1.2" aria-hidden="true">
      <rect x="0.6" y="0.6" width="17.8" height="10.8" rx="2.4" />
      <rect x="2.2" y="2.2" width="11.5" height="7.6" rx="1.2" fill="currentColor" stroke="none" />
      <path d="M19.6 4v4a1.6 1.6 0 0 0 0-4z" fill="currentColor" stroke="none" />
    </svg>
  )
}

type MockEntry = {
  id: string
  group: string
  label: string
  chip?: string
  detail: string
  port: string
}

const mockEntries: MockEntry[] = [
  { id: 'lokal-web', group: 'lokal', label: 'Vite', chip: 'web', detail: 'node · 62114', port: '5173' },
  { id: 'lokal-preview', group: 'lokal', label: 'Wrangler', chip: 'web', detail: 'workerd · 62201', port: '4179' },
  { id: 'store-web', group: 'storefront', label: 'Next.js', chip: 'web', detail: 'next-server · 40312', port: '3000' },
  { id: 'store-api', group: 'storefront', label: 'Rails', chip: 'api', detail: 'puma · 40388', port: '3001' },
  { id: 'store-db', group: 'Containers', label: 'storefront-db', detail: 'postgres:16', port: '5433' },
  { id: 'store-redis', group: 'Containers', label: 'storefront-redis', detail: 'redis:7', port: '6380' },
  { id: 'postgres', group: 'Services', label: 'Postgres', detail: 'postgres · 812', port: '5432' },
  { id: 'ollama', group: 'Services', label: 'Ollama', detail: 'ollama · 1190', port: '11434' },
]

const groups = ['lokal', 'storefront', 'Containers', 'Services']

/** A working miniature of the panel. Kill asks for confirmation, removes the row, and everything comes back later. */
function MockPanel() {
  const [confirming, setConfirming] = useState<string | null>(null)
  const [killed, setKilled] = useState<string[]>([])

  useEffect(() => {
    if (confirming === null) return
    const timer = setTimeout(() => setConfirming(null), 4000)
    return () => clearTimeout(timer)
  }, [confirming])

  useEffect(() => {
    if (killed.length === 0) return
    const timer = setTimeout(() => setKilled([]), 6000)
    return () => clearTimeout(timer)
  }, [killed])

  const visible = mockEntries.filter((entry) => !killed.includes(entry.id))

  return (
    <div className={styles.panel}>
      <div className={styles.panelHeader}>
        <span className={styles.panelTitle}>Lokal</span>
        <span className={styles.panelCount}>
          {visible.length} {visible.length === 1 ? 'port' : 'ports'}
        </span>
        <span className={styles.panelRefresh} aria-hidden="true">
          <RefreshGlyph />
        </span>
      </div>
      {groups.map((group) => {
        const entries = visible.filter((entry) => entry.group === group)
        if (entries.length === 0) return null
        return (
          <div key={group}>
            <div className={styles.group}>{group}</div>
            {entries.map((entry) => (
              <Row
                key={entry.id}
                entry={entry}
                confirming={confirming === entry.id}
                onRequestKill={() => setConfirming(entry.id)}
                onCancel={() => setConfirming(null)}
                onConfirm={() => {
                  setConfirming(null)
                  setKilled((current) => [...current, entry.id])
                }}
              />
            ))}
          </div>
        )
      })}
      <div className={styles.panelFooter}>
        <Button variant="secondary" size="compact" render={<span />}>
          Settings
        </Button>
        <Button variant="secondary" size="compact" render={<span />}>
          Quit
        </Button>
      </div>
    </div>
  )
}

function Row({
  entry,
  confirming,
  onRequestKill,
  onCancel,
  onConfirm,
}: {
  entry: MockEntry
  confirming: boolean
  onRequestKill: () => void
  onCancel: () => void
  onConfirm: () => void
}) {
  return (
    <div className={styles.row}>
      <div className={styles.rowText}>
        <div className={styles.rowLabel}>
          {entry.label}
          {entry.chip ? <span className={styles.chip}>{entry.chip}</span> : null}
        </div>
        <div className={styles.rowDetail}>
          <span className={styles.port}>{entry.port}</span> · {entry.detail}
        </div>
      </div>
      {confirming ? (
        <div className={styles.killConfirm}>
          <button type="button" className={styles.killConfirmAction} onClick={onConfirm}>
            Kill
          </button>
          <button type="button" className={styles.killConfirmCancel} onClick={onCancel} aria-label="Cancel">
            <CloseGlyph />
          </button>
        </div>
      ) : (
        <div className={styles.rowActions}>
          <a
            className={styles.iconButton}
            href={`http://localhost:${entry.port}`}
            target="_blank"
            rel="noreferrer"
            aria-label={`Open localhost:${entry.port} in a new tab`}
            onClick={(event) => event.preventDefault()}
          >
            <OpenGlyph />
          </a>
          <button
            type="button"
            className={`${styles.iconButton} ${styles.killButton}`}
            onClick={onRequestKill}
            aria-label={`Kill ${entry.label}`}
          >
            <CloseGlyph />
          </button>
        </div>
      )}
    </div>
  )
}

function RefreshGlyph() {
  return (
    <svg width="14" height="14" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M13.5 8a5.5 5.5 0 1 1-1.6-3.9" />
      <path d="M13.5 2.5v3h-3" />
    </svg>
  )
}

function OpenGlyph() {
  return (
    <svg width="14" height="14" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M6 3.5H4.5A1.5 1.5 0 0 0 3 5v6.5A1.5 1.5 0 0 0 4.5 13H11a1.5 1.5 0 0 0 1.5-1.5V10" />
      <path d="M9.5 2.5H13.5V6.5M13.5 2.5L8 8" />
    </svg>
  )
}

function CloseGlyph() {
  return (
    <svg width="14" height="14" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" aria-hidden="true">
      <path d="M4 4l8 8M12 4l-8 8" />
    </svg>
  )
}
