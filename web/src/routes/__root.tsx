import { createRootRoute, HeadContent, Outlet, Scripts } from '@tanstack/react-router'
import { Footer, Header, Main } from '~/components/Layout'
import globalCss from '~/styles/global.css?url'

export const siteURL = 'https://lokal.sigurdarson.is'
export const siteName = 'Lokal'
const title = 'Lokal: see what is running on localhost'
const description =
  'A free, open source macOS menu bar app that lists your localhost ports, the process behind each one, and the project it belongs to. Open, copy, reveal or kill any of them.'

/** Shared Open Graph and Twitter tags. Routes override title, description and canonical. */
export function socialMeta(pageTitle: string, pageDescription: string, path: string) {
  const url = siteURL + path
  return {
    meta: [
      { title: pageTitle },
      { name: 'description', content: pageDescription },
      { property: 'og:site_name', content: siteName },
      { property: 'og:type', content: 'website' },
      { property: 'og:title', content: pageTitle },
      { property: 'og:description', content: pageDescription },
      { property: 'og:url', content: url },
      { property: 'og:image', content: siteURL + '/og.png' },
      { property: 'og:image:width', content: '1200' },
      { property: 'og:image:height', content: '630' },
      { property: 'og:image:alt', content: 'The Lokal mark and the words: see what is running on localhost.' },
      { property: 'og:locale', content: 'en' },
      { name: 'twitter:card', content: 'summary_large_image' },
      { name: 'twitter:title', content: pageTitle },
      { name: 'twitter:description', content: pageDescription },
      { name: 'twitter:image', content: siteURL + '/og.png' },
    ],
    links: [{ rel: 'canonical', href: url }],
  }
}

export const Route = createRootRoute({
  head: () => ({
    meta: [
      { charSet: 'utf-8' },
      { name: 'viewport', content: 'width=device-width, initial-scale=1' },
      { name: 'application-name', content: siteName },
      { name: 'author', content: 'G. Sigurdarson' },
      { name: 'robots', content: 'index, follow' },
      // Fallbacks; each route sets its own title, description, social tags and canonical.
      { title },
      { name: 'description', content: description },
      // --gray-50 and --gray-950 from src/styles/tokens.css
      { name: 'theme-color', content: 'oklch(0.985 0 0)', media: '(prefers-color-scheme: light)' },
      { name: 'theme-color', content: 'oklch(0.145 0 0)', media: '(prefers-color-scheme: dark)' },
    ],
    links: [
      { rel: 'stylesheet', href: globalCss },
      { rel: 'icon', type: 'image/svg+xml', href: '/favicon.svg' },
      { rel: 'alternate', type: 'application/rss+xml', title: 'Lokal updates (Sparkle appcast)', href: '/appcast.xml' },
      { rel: 'alternate', type: 'text/plain', title: 'llms.txt', href: '/llms.txt' },
    ],
  }),
  shellComponent: RootDocument,
  component: () => (
    <>
      <Header />
      <Main>
        <Outlet />
      </Main>
      <Footer />
    </>
  ),
  notFoundComponent: () => (
    <section style={{ padding: '80px 0' }}>
      <h1>Not found</h1>
      <p>That page does not exist. Try the front page.</p>
    </section>
  ),
})

function RootDocument({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <HeadContent />
      </head>
      <body>
        {children}
        <Scripts />
      </body>
    </html>
  )
}
