import { Link } from '@tanstack/react-router'
import type { ReactNode } from 'react'
import styles from './Layout.module.css'

export function Header() {
  return (
    <header className={styles.header}>
      <div className={styles.headerInner}>
        <Link to="/" className={styles.brand}>
          <img src="/favicon.svg" alt="" width={26} height={26} />
          Lokal
        </Link>
        <nav className={styles.nav} aria-label="Primary">
          <Link to="/changelog">Changelog</Link>
          <a href="https://github.com/sigurdarson/lokal">GitHub</a>
        </nav>
      </div>
    </header>
  )
}

export function Main({ children }: { children: ReactNode }) {
  return <main className={styles.main}>{children}</main>
}

export function Footer() {
  return (
    <footer className={styles.footer}>
      <span>MIT licensed. No accounts, no telemetry.</span>
      <a href="https://github.com/sigurdarson/lokal">Source</a>
      <a href="https://github.com/sigurdarson/lokal/issues">Issues</a>
      <a href="https://github.com/sigurdarson/lokal/security/policy">Security</a>
      <span>Made by G. Sigurdarson</span>
    </footer>
  )
}
