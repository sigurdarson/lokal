import { cloudflare } from '@cloudflare/vite-plugin'
import { tanstackStart } from '@tanstack/react-start/plugin/vite'
import viteReact from '@vitejs/plugin-react'
import { fileURLToPath } from 'node:url'
import { defineConfig } from 'vite'

const repoRoot = fileURLToPath(new URL('..', import.meta.url))

export default defineConfig({
  resolve: {
    alias: { '~': fileURLToPath(new URL('./src', import.meta.url)) },
  },
  server: {
    // The changelog page imports ../CHANGELOG.md from the repository root.
    fs: { allow: [repoRoot] },
  },
  plugins: [
    cloudflare({ viteEnvironment: { name: 'ssr' } }),
    tanstackStart({
      // Static-first: every page is rendered to HTML at build time and served as an asset.
      // Links are not crawled: /download is a redirect to GitHub and must not be prerendered.
      prerender: { enabled: true, crawlLinks: false, autoSubfolderIndex: false },
    }),
    viteReact(),
  ],
})
