import { useEffect, useState } from 'react'

/** Formats like the macOS menu bar clock, in the visitor's locale: "Tue 9 Sep 14:32". */
function format(date: Date): string {
  const day = new Intl.DateTimeFormat(undefined, { weekday: 'short', day: 'numeric', month: 'short' }).format(date)
  const time = new Intl.DateTimeFormat(undefined, { hour: 'numeric', minute: '2-digit' }).format(date)
  return `${day} ${time}`
}

/**
 * The visitor's current time, ticking on the minute. The prerendered HTML carries a fixed
 * placeholder so the server and first client render agree; the real time replaces it after mount.
 */
export function MenuBarClock({ className }: { className?: string }) {
  const [now, setNow] = useState<Date | null>(null)

  useEffect(() => {
    let timer: ReturnType<typeof setTimeout>
    const tick = () => {
      const current = new Date()
      setNow(current)
      const untilNextMinute = 60_000 - (current.getSeconds() * 1000 + current.getMilliseconds())
      timer = setTimeout(tick, untilNextMinute)
    }
    tick()
    return () => clearTimeout(timer)
  }, [])

  return (
    <time className={className} dateTime={now?.toISOString()}>
      {now ? format(now) : 'Tue 9 Sep 14:32'}
    </time>
  )
}
