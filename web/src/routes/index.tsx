import { createFileRoute } from '@tanstack/react-router'
import { Button } from '~/components/Button'
import { CopyButton } from '~/components/CopyButton'
import { MenuBarClock } from '~/components/MenuBarClock'
import styles from '~/components/Home.module.css'

export const Route = createFileRoute('/')({
  component: Home,
})

const brew = 'brew install sigurdarson/tap/lokal'

function Home() {
  return (
    <>
      <section className={styles.hero}>
        <p className={styles.eyebrow}>Free and open source · macOS menu bar</p>
        <h1 className={styles.title}>See what is running on localhost.</h1>
        <p className={styles.lede}>
          Lokal lists every port your machine is listening on, the process behind it, and the project it belongs to.
          Open it, copy the URL, jump to the code, or kill it. All from the menu bar.
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

      <section className={styles.section} id="what-it-does">
        <h2 className={styles.sectionTitle}>What it does</h2>
        <div className={styles.features}>
          <Feature title="Every listening port">
            Native process inspection through libproc. No <code>lsof</code>, no shell, no polling in the background
            unless you ask for the menu bar count.
          </Feature>
          <Feature title="Grouped by project">
            Lokal resolves the working directory to the nearest manifest and git root, so <code>node</code> on 5173
            becomes <em>shop / web</em>.
          </Feature>
          <Feature title="Knows your services">
            Postgres, MySQL, Redis, Mongo, Vite, Next.js, Rails, Django, Docker and OrbStack containers, and more.
            Definitions live in one JSON file that anyone can extend.
          </Feature>
          <Feature title="Actions that matter">
            Open in browser, copy URL, reveal in Finder, open in your editor or terminal, and kill the process with an
            inline confirmation instead of a dialog.
          </Feature>
          <Feature title="Stays out of the way">
            A single menu bar icon. Scans when you open it, sleeps when you close it. Launch at login is a toggle.
          </Feature>
          <Feature title="Honest software">
            MIT licensed. The only network request is the update check, and you can turn that off.
          </Feature>
        </div>
      </section>

      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>Install</h2>
        <ol className={styles.steps}>
          <li>
            <span>
              <strong>Install</strong> with <code>{brew}</code>, or download the <a href="/download">.dmg</a> and
              drag Lokal to Applications.
            </span>
          </li>
          <li>
            <span>
              <strong>Open Lokal.</strong> It lives in the menu bar; there is no Dock icon.
            </span>
          </li>
          <li>
            <span>
              <strong>Start something.</strong> A dev server, a database, a container. It shows up within a couple of
              seconds while the panel is open.
            </span>
          </li>
        </ol>
      </section>
    </>
  )
}

function Feature({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className={styles.feature}>
      <h3>{title}</h3>
      <p>{children}</p>
    </div>
  )
}

/** The top-right corner of a Mac screen, zoomed in: the menu bar with Lokal active, and the panel hanging from it. */
function Showcase() {
  return (
    <div className={styles.showcase}>
      <div className={styles.screen} role="img" aria-label="Illustration of the Lokal panel open from the macOS menu bar">
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
      </div>
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

/** A static rendition of the panel, so the page works without a screenshot. */
function MockPanel() {
  return (
    <div className={styles.panel}>
      <div className={styles.panelHeader}>
        <span className={styles.panelTitle}>Lokal</span>
        <span className={styles.panelCount}>5 ports · 12 hidden</span>
        <span className={styles.panelRefresh} aria-hidden="true">
          <RefreshGlyph />
        </span>
      </div>
      <div className={styles.group}>shop</div>
      <Row label="Vite" chip="web" detail="node · 48211" port="5173" />
      <Row label="Rails" chip="api" detail="puma · 48090" port="3000" confirm />
      <div className={styles.more}>2 hidden ports</div>
      <div className={styles.group}>Containers</div>
      <Row label="shop-db" detail="postgres:16" port="5433" />
      <div className={styles.group}>Services</div>
      <Row label="Postgres" detail="postgres · 812" port="5432" />
      <Row label="Redis" detail="redis-server · 815" port="6379" />
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

function RefreshGlyph() {
  return (
    <svg width="14" height="14" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M13.5 8a5.5 5.5 0 1 1-1.6-3.9" />
      <path d="M13.5 2.5v3h-3" />
    </svg>
  )
}

function Row({
  label,
  chip,
  detail,
  port,
  confirm,
}: {
  label: string
  chip?: string
  detail: string
  port: string
  confirm?: boolean
}) {
  return (
    <div className={styles.row}>
      <div className={styles.rowText}>
        <div className={styles.rowLabel}>
          {label}
          {chip ? <span className={styles.chip}>{chip}</span> : null}
        </div>
        <div className={styles.rowDetail}>
          <span className={styles.port}>{port}</span> · {detail}
        </div>
      </div>
      {confirm ? (
        <div className={styles.killConfirm}>
          <b>Kill</b>
          <i>×</i>
        </div>
      ) : (
        <div className={styles.kill} />
      )}
    </div>
  )
}
