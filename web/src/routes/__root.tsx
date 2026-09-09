import { createRootRoute, HeadContent, Outlet, Scripts } from '@tanstack/react-router'
import { Footer, Header, Main } from '~/components/Layout'
import globalCss from '~/styles/global.css?url'

const title = 'Lokal — see what is running on localhost'
const description =
  'A free, open source macOS menu bar app that lists your localhost ports, the process behind each one, and the project it belongs to.'

export const Route = createRootRoute({
  head: () => ({
    meta: [
      { charSet: 'utf-8' },
      { name: 'viewport', content: 'width=device-width, initial-scale=1' },
      { title },
      { name: 'description', content: description },
      { property: 'og:title', content: title },
      { property: 'og:description', content: description },
      { property: 'og:type', content: 'website' },
      { property: 'og:url', content: 'https://lokal.sigurdarson.is/' },
      // --gray-50 and --gray-950 from src/styles/tokens.css
      { name: 'theme-color', content: 'oklch(0.985 0 0)', media: '(prefers-color-scheme: light)' },
      { name: 'theme-color', content: 'oklch(0.145 0 0)', media: '(prefers-color-scheme: dark)' },
    ],
    links: [
      { rel: 'stylesheet', href: globalCss },
      { rel: 'icon', type: 'image/svg+xml', href: '/favicon.svg' },
      { rel: 'alternate', type: 'application/rss+xml', title: 'Lokal updates (Sparkle appcast)', href: '/appcast.xml' },
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
