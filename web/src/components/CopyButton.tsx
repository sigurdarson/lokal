import { useState } from 'react'
import styles from './Home.module.css'

export function CopyButton({ text }: { text: string }) {
  const [copied, setCopied] = useState(false)
  return (
    <button
      type="button"
      className={styles.copy}
      aria-label="Copy to clipboard"
      onClick={async () => {
        try {
          await navigator.clipboard.writeText(text)
          setCopied(true)
          setTimeout(() => setCopied(false), 1500)
        } catch {
          // Clipboard unavailable (insecure context); the text is selectable anyway.
        }
      }}
    >
      {copied ? 'Copied' : 'Copy'}
    </button>
  )
}
