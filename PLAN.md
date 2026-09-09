# Lokal — Project Plan

> Status: **approved 2026-09-09**; decisions recorded in §11. Every version number below was verified on 2026-09-09 against primary sources (Apple release feed, GitHub release APIs, npm registry, Cloudflare/TanStack/Homebrew/Sparkle docs, and the toolchain installed on this machine).

Lokal is a native macOS menu bar app that shows what is running on localhost: listening ports, the process behind each, the project it belongs to, and well-known services (Postgres, Redis, Vite, ...). Free, MIT, no accounts, no telemetry, no network calls except Sparkle update checks.

- Repo: `github.com/sigurdarson/lokal` (public, default branch `main`)
- Site: `https://lokal.sigurdarson.is` (does not resolve yet)
- Install: `brew install sigurdarson/tap/lokal` or a direct `.dmg`

---

## 1. Verified versions (2026-09-09)

| Component | Verified current stable | Notes | Decision |
|---|---|---|---|
| Xcode | **26.6 (17F113)**, 2026-06-25 | Xcode 27 is at beta 6 (27A5252f, 2026-08-24); not stable. Installed locally: 26.6. | Build with Xcode 26.6. |
| Swift | **6.3.3** (`swift-6.3.3-RELEASE`, 2026-06-30) | Ships in Xcode 26.6. Note: this machine's `xcode-select` points at Command Line Tools carrying Swift 6.4 from the Xcode 27 beta; builds must use `DEVELOPER_DIR=/Applications/Xcode.app` or `sudo xcode-select -s /Applications/Xcode.app`. | Swift 6 language mode, `swift-tools-version: 6.0`... see §4. |
| macOS | **26.6.2 Tahoe** (25G83, 2026-08-17) | macOS 27 "Golden Gate" is at beta 8 (26A5425a, 2026-08-31). Apple's event is today, 2026-09-09; GA expected mid-September. macOS 27 drops Intel. This dev machine runs 27.0 beta. | See §1.1. |
| macOS SDK | 26 (in Xcode 26.6) | | Build against SDK 26. |
| Sparkle | **2.9.6**, 2026-08-17 | 2.10.0-beta.1 exists (2026-09-07); skipped. SPM binary target, `platforms: [.macOS(.v10_13)]`. `generate_appcast --ed-key-file -` reads the EdDSA key from stdin for CI. | Sparkle 2.9.6 via SPM. |
| TanStack Start | **`@tanstack/react-start` 1.168.50** | `@tanstack/react-router` 1.170.33, `@tanstack/router-plugin` 1.168.36. Cloudflare setup: `@cloudflare/vite-plugin` + `tanstackStart()` + `@vitejs/plugin-react` in `vite.config.ts`, `wrangler.jsonc` with `main: "@tanstack/react-start/server-entry"` and `nodejs_compat`. Prerendering via `tanstackStart({ prerender: {...} })`. | See §7. |
| Vite | **8.2.2** | `@vitejs/plugin-react` 6.1.1 | Whatever the TanStack scaffold pins; verify at scaffold time. |
| TypeScript | 7.0.2 (Go-based compiler) | The scaffold may still pin 5.x/6.x. | Use the scaffold's pin; do not force 7. |
| Wrangler | **4.130.0** | `cloudflare/wrangler-action` **v4.0.0** (2026-05-12). `wrangler.jsonc` is the recommended config format. | Wrangler 4, wrangler-action v4. |
| `@cloudflare/vite-plugin` | **1.54.6** | | |
| GitHub Actions macOS | **`macos-26`** image = macOS 26.6.1, Xcode 26.6 default (26.0.1–26.6 installed); `macos-latest` → macos-26 arm64. macos-14 deprecated. Xcode 27 beta not in image. | | Pin `runs-on: macos-26`. |
| Node / pnpm (local) | Node 26.0.0, pnpm 11.1.2, bun 1.4.2, npm 11.12.1 | | pnpm (see open questions). |
| Homebrew | Tap = repo named `homebrew-<tap>` with `Casks/` at root; livecheck `strategy :sparkle`; `auto_updates true`; `zap trash:`. | `sigurdarson/homebrew-tap` **does not exist yet**. | See §8.4. |
| gh CLI (local) | 2.89.0, authenticated as `sigurdarson` | | |

### 1.1 macOS support window

Requirement: current macOS plus one prior major. Today that is **26 + 15**. Within roughly two weeks it becomes **27 + 26**.

Recommendation: set `MACOSX_DEPLOYMENT_TARGET = 15.0` for v0.1/v0.2 and decide at v1.0 whether to raise it to 26.0. Everything planned here (MenuBarExtra `.window`, `@Observable`, `SMAppService`, Swift Testing, `matchedGeometryEffect`) is available on 15. Raising to 26 later is a one-line change; lowering is not. Because macOS 15 and 26 run on Intel, the owner chose **arm64 only** (see §11); Intel Macs are not supported.

### 1.2 Conventions for a new menu bar app in 2026 (verified)

- `MenuBarExtra` with `.menuBarExtraStyle(.window)` is the recommended starting point; drop to `NSStatusItem` + `NSPanel` only if a hard wall is hit (custom positioning, stay-open behaviour). Lokal starts with `MenuBarExtra(.window)`.
- `LSUIElement = true` (no Dock icon), a `Settings` scene for preferences, `SMAppService.mainApp` for launch at login.
- `@Observable` models, `@MainActor` UI, actors for scanning, Swift 6 strict concurrency.
- **Swift Testing** (`import Testing`) rather than XCTest for new tests.
- `swift format` (bundled in the Xcode 26 toolchain) for formatting/lint, so no SwiftLint/SwiftFormat dependency.
- Hardened runtime + Developer ID + `notarytool` + `stapler`; Sparkle 2 with EdDSA-signed appcast.

---

## 2. Monorepo structure

```
lokal/
├── app/                         macOS app (Xcode project + local Swift package)
│   ├── Lokal.xcodeproj
│   ├── Lokal/                   app target (synchronized folder group)
│   │   ├── LokalApp.swift       @main, MenuBarExtra, Settings scene, Sparkle wiring
│   │   ├── App/                 AppModel, polling controller, settings store
│   │   ├── Views/               Panel, sections, rows, KillButton, Settings
│   │   ├── Support/             LoginItem, EditorLauncher, Updater bridge
│   │   ├── Resources/           Assets.xcassets (icon, symbols)
│   │   └── Lokal.entitlements   hardened runtime only, no sandbox
│   ├── LokalCore/               local SPM package: all non-UI logic + tests
│   │   ├── Package.swift
│   │   ├── Sources/LokalCore/
│   │   │   ├── Sockets/         LibprocSocketSource, ListeningSocket
│   │   │   ├── Processes/       ProcessInspector (name, path, cwd, ppid, argv)
│   │   │   ├── Projects/        ProjectResolver, manifest parsers
│   │   │   ├── Services/        ServiceCatalog, ServiceMatcher, services.json
│   │   │   ├── Docker/          DockerInspector (unix-socket Engine API)
│   │   │   ├── Model/           PortEntry, ProjectGroup, Snapshot
│   │   │   └── Scanner.swift    orchestrates the above into a Snapshot
│   │   └── Tests/LokalCoreTests/
│   ├── ExportOptions.plist      developer-id export
│   └── scripts/                 build-archive.sh, make-dmg.sh, notarize.sh, bump-version.sh
├── web/                         TanStack Start site → Cloudflare Workers
│   ├── src/routes/              __root.tsx, index.tsx, changelog.tsx
│   ├── public/                  appcast.xml, _redirects, screenshot, favicon
│   ├── vite.config.ts
│   ├── wrangler.jsonc
│   └── package.json
├── homebrew/
│   └── Casks/lokal.rb           source of truth; mirrored verbatim to sigurdarson/homebrew-tap
├── .github/
│   ├── workflows/ci.yml         PRs: build + test app, build site, audit cask
│   ├── workflows/web.yml        push to main (paths: web/**, CHANGELOG.md) + workflow_call
│   ├── workflows/release.yml    tag v*: sign, notarize, release, appcast, cask, tap, deploy
│   ├── ISSUE_TEMPLATE/          bug_report.yml, feature_request.yml, config.yml
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── dependabot.yml           github-actions, npm (web), swift (app/LokalCore)
│   └── CODEOWNERS
├── README.md  LICENSE  CHANGELOG.md  CONTRIBUTING.md  CODE_OF_CONDUCT.md  SECURITY.md
├── .gitignore  .editorconfig  .swift-format
└── PLAN.md
```

### 2.1 Xcode project + local SPM package (the "which build system" decision)

**Choice: a committed `Lokal.xcodeproj` for the app target, plus a local Swift package `LokalCore` for all logic.**

Why not pure SPM: SwiftPM cannot produce a signed `.app` bundle with Info.plist, entitlements, an asset catalog, an embedded Sparkle XPC/framework, hardened runtime and a notarizable export without hand-rolled scripts that reimplement what `xcodebuild archive` already does. Sparkle's own docs assume an Xcode app target. Why not XcodeGen/Tuist: they add a generator dependency and a step contributors must run; Xcode 16+ **synchronized folder groups** already keep `project.pbxproj` small and nearly churn-free, which was the main reason people reached for generators.

Why the split: everything testable (socket parsing, project detection, service matching, Docker port mapping) lives in `LokalCore`, so `swift test` runs on CI without a simulator, tests are fast, and the app target is thin. The app target depends on `LokalCore` (local path) and `Sparkle` (SPM, exact `2.9.6`).

### 2.2 Dependencies

- App: **Sparkle 2.9.6** only. No others.
- DMG creation uses `hdiutil` (system), not `create-dmg`. Zip uses `ditto`. Notarization uses `notarytool`. Formatting uses toolchain `swift format`. No Homebrew tools are required on CI for the app.
- Web: React + TanStack Start + Vite + Cloudflare plugin + Wrangler, plus one small markdown renderer (`marked`) for the changelog page. The "no third-party dependencies" rule is read as applying to the app; the website is a normal JS project and its dependencies are listed in `web/package.json`.
- CI: `actions/checkout`, `actions/setup-node`, `pnpm/action-setup`, `cloudflare/wrangler-action@v4`, `softprops/action-gh-release` (or plain `gh release`), `amannn/action-semantic-pull-request` for conventional PR titles.

---

## 3. Architecture

### 3.1 Data flow

```
 panel appears ──► AppModel.startPolling() ──► every 2 s ──► Scanner.snapshot()
                                                               │
     ┌─────────────────────────────────────────────────────────┘
     ▼
 LibprocSocketSource.listeningSockets()           [ListeningSocket{pid, port, family, address}]
     ▼
 ProcessInspector.info(pid)  (cached per pid+start time)   name, path, cwd, ppid, argv
     ▼
 ServiceMatcher.match(process, port)              ServiceMatch? (id, label, icon, confidence)
     ▼
 ProjectResolver.resolve(process)  (cached)       Project? (name, root, manifestKind)
     ▼
 DockerInspector.containers()  (only if a Docker/OrbStack backend owns a port; cached 5 s)
     ▼
 Snapshot{ groups: [ProjectGroup{ project, entries: [PortEntry] }], other: [PortEntry] }
     ▼
 AppModel.snapshot (MainActor, @Observable) ──► PanelView diffing with stable ids (pid:port)
```

- `Scanner` is an `actor`. `AppModel` is `@MainActor @Observable`. `PortEntry`/`Snapshot` are `Sendable` value types. Swift 6 strict concurrency, no `@unchecked Sendable` outside the C-interop layer.
- Polling: refresh immediately on panel `onAppear`, then a `Task` loop with 2 s sleep while visible; cancelled on `onDisappear`. No background polling when closed unless the badge is enabled (then 30 s).
- Caches keyed by `(pid, proc_bsdinfo.pbi_start_tvsec)` so pid reuse cannot serve stale data.

### 3.2 Socket enumeration (native, libproc)

Verified against the public macOS 26 SDK headers (`<libproc.h>`, `<sys/proc_info.h>`): `PROC_PIDLISTFDS`, `PROC_PIDFDSOCKETINFO`, `PROC_PIDVNODEPATHINFO`, `PROX_FDTYPE_SOCKET`, `SOCKINFO_TCP`, `TSI_S_LISTEN`, `in_sockinfo.insi_lport` are all public.

Algorithm:

1. `proc_listpids(PROC_ALL_PIDS)` → all pids.
2. For each pid: `proc_pidinfo(pid, PROC_PIDLISTFDS)` → `[proc_fdinfo]`; keep `proc_fdtype == PROX_FDTYPE_SOCKET`.
3. For each socket fd: `proc_pidfdinfo(pid, fd, PROC_PIDFDSOCKETINFO)` → `socket_fdinfo`; keep `psi.soi_kind == SOCKINFO_TCP` and `psi.soi_proto.pri_tcp.tcpsi_state == TSI_S_LISTEN`.
4. Port = low 16 bits of `insi_lport`, byte-swapped from network order (same as lsof). Family from `soi_family` (AF_INET/AF_INET6); local address from `insi_laddr` (loopback vs any vs specific), kept for a subtle "all interfaces" indicator.
5. Dedupe on `(pid, port)`; dual-stack listeners appear once.
6. Errors: `EPERM` on processes owned by other users (root daemons) is expected and silently skipped. `ESRCH` (process exited mid-scan) skipped.

Cost: one syscall per pid plus one per socket fd; typically 50–150 ms for ~600 processes. Runs off the main thread; results are diffed so the UI does not flicker.

**Why no lsof fallback:** the libproc path is viable and is what lsof itself uses on macOS. lsof would have the same EPERM limitation for other users' processes, so it adds nothing except a shell-out. Not planned.

**Considered and deferred:** `sysctl net.inet.tcp.pcblist_n` returns every TCP PCB system-wide (including other users' listeners) with `so_last_pid` in one call. But its record structs (`xinpcb_n`, `xtcpcb_n`, `xsocket_n`) are behind `#ifdef PRIVATE` in XNU and are **not in the public SDK** (verified: the SDK's `netinet/in_pcb.h` has no `xinpcb*` structs). Using it means hand-copying struct layouts and risking silent breakage on OS updates. Could be a v0.2+ optional "show system listeners" source if wanted; not in scope now.

UDP listeners: out of scope for v0.1 (TCP only). Trivial to add later via `SOCKINFO_IN`.

### 3.3 Process inspection (native)

- `proc_name` / `proc_pidpath` → display name and executable path.
- `proc_pidinfo(PROC_PIDVNODEPATHINFO)` → `pvi_cdir.vip_path` = working directory.
- `proc_pidinfo(PROC_PIDTBSDINFO)` → `pbi_ppid`, `pbi_start_tvsec`, `pbi_uid`.
- `sysctl(KERN_PROCARGS2)` → argv (public API). Used to label generic runtimes (`node` running `next dev`, `python -m http.server`, `ruby bin/rails s`) and to feed `commandPatterns` in service matching. Read once per pid, cached.

### 3.4 Docker / OrbStack awareness (cheap, native)

Trigger only when a listening socket is owned by a known backend process (`com.docker.backend`, `com.docker.vpnkit`, `OrbStack Helper`, `orbstack`). Then:

1. Find the first existing socket among `~/.orbstack/run/docker.sock`, `~/.docker/run/docker.sock`, `/var/run/docker.sock`.
2. Open it with Network.framework (`NWConnection` to `NWEndpoint.unix(path:)`) and send a minimal HTTP/1.1 `GET /containers/json` (about 60 lines of code; no HTTP library, no URLSession-over-unix hack, no `docker` CLI shell-out).
3. Map `Ports[].PublicPort` → container name and image. Cache 5 s.

This is a local unix socket, not a network call, so it does not violate the "no network except Sparkle" rule. If the socket is missing or the request fails, the row still shows the backend process name.

### 3.5 Kill

`kill(pid, SIGTERM)`; rescan after 1 s; if the port is still listening after 2 s and "Force kill" is enabled (default on), `SIGKILL`. Only same-user processes are visible, so `EPERM` is rare; shown inline if it happens. Killing a Docker backend port kills the container's host proxy, not the container; for Docker rows the action is instead "Stop container" via `POST /containers/{id}/stop` on the same socket (v0.2).

### 3.6 App layer

- `LokalApp`: `MenuBarExtra("Lokal", systemImage: ...) { PanelView() }.menuBarExtraStyle(.window)`, `Settings { SettingsView() }`, `SPUStandardUpdaterController` created in `init` (Sparkle's documented SwiftUI pattern), "Check for Updates…" in the panel footer and in the app menu.
- `AppModel`: snapshot, polling lifecycle, selection/confirm state, settings (`@AppStorage`-backed store), badge count.
- `PanelView`: header (title, count, refresh), grouped list (project sections, then "Services", then "Other"), footer (Settings, Check for Updates, Quit). Fixed width ~360 pt, height clamps to content with a max, `ScrollView` inside.
- `PortRow`: icon, label (service or command), `:port`, process name + pid, project chip, trailing actions (open, copy, reveal, editor, kill) revealed on hover with keyboard equivalents.
- `EditorLauncher`: detects installed editors by bundle id (VS Code, Cursor, Zed, Xcode, JetBrains Toolbox apps, Sublime, Nova); settings picker; `NSWorkspace.open(_:withApplicationAt:)`.
- `LoginItem`: `SMAppService.mainApp.register()/unregister()`, reflects `status`.
- Badge: `MenuBarExtra` label shows a count when enabled; enables 30 s background polling only in that case.

---

## 4. Project detection algorithm

Input: a process (pid, cwd, argv, ppid). Output: `Project { name, root, manifest }` or nil.

1. **Candidate directories, in order**
   1. Process cwd, if it is not `/` and is under the user's home.
   2. Parent chain (up to 3 hops) cwd, same filter. Covers `node` spawned by `pnpm dev`, `turbo`, `foreman`, `overmind`, IDE run configs.
   3. Script path from argv (e.g. `/Users/x/proj/node_modules/.bin/vite`, `/Users/x/proj/.venv/bin/python`): strip everything from `/node_modules/`, `/.venv/`, `/venv/`, `/target/`, `/.build/` onward → candidate.
2. **Walk up** from the candidate to `$HOME` (exclusive) or `/`. At each level look for, in priority order:

   | Manifest | Name source |
   |---|---|
   | `package.json` | `name` (strip `@scope/`); skip if `"private": true` and name missing |
   | `Package.swift` | regex `name:\s*"([^"]+)"` inside `Package(` |
   | `Cargo.toml` | `[package] name` (workspace root: `[workspace]` → dir name) |
   | `pyproject.toml` | `[project] name`, else `[tool.poetry] name` |
   | `go.mod` | last path component of `module` |
   | `Gemfile` / `*.gemspec` | gemspec `name`, else dir name |
   | `composer.json` | `name` after `/` |
   | `mix.exs` | `app: :name` |
   | `deno.json(c)` | `name` |
   | `pubspec.yaml` | `name` |
   | `settings.gradle(.kts)` | `rootProject.name` |
   | `CMakeLists.txt` | `project(Name` |
   | `*.xcodeproj` / `*.xcworkspace` | bundle name |
   | `.git` (dir or file for worktrees) | marks the repository root; name = dir name |

   Two things are recorded: the **nearest manifest** (gives the display name) and the **nearest `.git`** (gives the grouping root). In a monorepo, `apps/web/package.json` names the entry "web" and `.git` two levels up groups it under "lokal", displayed as **lokal / web**. If no manifest is found, the git root's directory name is used; if no git root either, the cwd's last path component.
3. **Normalisation**: manifest name equal to the directory name collapses to one label; names are trimmed to 40 chars; scope prefixes are dropped.
4. **Parsing** uses `JSONSerialization` for JSON and small regexes for TOML/Swift/Gradle/go.mod. No TOML/YAML library. Files over 512 KB are skipped.
5. **Caching**: results keyed by `(pid, start time)`; directory → project results also cached by path with a 60 s TTL, because many processes share a root.
6. **Privacy note**: reading a cwd under `~/Desktop`, `~/Documents` or `~/Downloads` triggers a one-time macOS TCC prompt for that folder. Accepted; documented in README. The app never reads anything other than manifest files and `.git` presence.

Tests: fixture directory trees built in a temp dir per test (monorepo, worktree `.git` file, scoped package name, private package without name, Cargo workspace, nested Python venv, no manifest at all), plus argv-strip cases.

---

## 5. Service definition format

`app/LokalCore/Sources/LokalCore/Services/services.json` (bundled as a package resource, loaded once, validated by a test):

```jsonc
{
  "$schema": "./services.schema.json",
  "services": [
    {
      "id": "postgres",
      "name": "Postgres",
      "kind": "database",             // database | cache | queue | search | dev-server | web | tool | other
      "icon": "cylinder.split.1x2",   // SF Symbol name
      "ports": [5432],
      "processNames": ["postgres", "postgres_real"],
      "commandPatterns": [],          // regexes matched against the full argv string
      "urlTemplate": "postgres://localhost:{port}",   // used by Copy URL; default http://localhost:{port}
      "openInBrowser": false          // default true
    },
    {
      "id": "vite",
      "name": "Vite",
      "kind": "dev-server",
      "icon": "bolt.fill",
      "ports": [5173, 4173],
      "commandPatterns": ["(^|/)vite(\\.js)?(\\s|$)"]
    }
  ]
}
```

Initial catalog (~25): Postgres, MySQL/MariaDB, Redis/Valkey, MongoDB, SQLite-web?, Elasticsearch/OpenSearch, Meilisearch, RabbitMQ, Kafka, NATS, Memcached, Minio, Mailpit/MailHog, Vite, Next.js, Nuxt, Remix/React Router, Astro, SvelteKit, Rails, Django, Flask/FastAPI (uvicorn), Phoenix, Go (generic), Storybook, Expo/Metro, Docker Desktop, OrbStack, Ollama, LM Studio, Supabase CLI, Prisma Studio, Jupyter, Tailscale, Syncthing, generic http servers on 8080/8000.

Matching precedence (highest first), returning a confidence used for the label:

1. `processNames` exact match on `proc_name` or executable basename → **high**.
2. `commandPatterns` match on argv → **high**.
3. `ports` match → **medium** if the process is a generic runtime (`node`, `python`, `ruby`, `java`, `bun`, `deno`), else **low** (a Rust binary on 3000 is not "Next.js"). Low-confidence port matches only influence the icon, not the label.

Contributors add a service by appending one object; a unit test asserts unique ids, valid `kind`, compilable regexes, and that every `icon` resolves via `NSImage(systemSymbolName:)`. The README documents this.

---

## 6. Kill interaction design

**Chosen: inline morph-to-confirm.** Hold-to-kill was rejected because it depends on timing (bad with Reduce Motion, VoiceOver and Switch Control), is undiscoverable, and cannot be driven from the keyboard.

State machine per row: `idle → confirming(deadline) → killing → gone | failed(reason)`.

- **Idle**: trailing `xmark.circle` button (visible on hover/focus, always visible for VoiceOver).
- **Tap** → the button's capsule background expands in place (`matchedGeometryEffect(id: "kill-\(entry.id)")`) into a two-segment capsule: **Kill** (destructive tint, default action, Return) and a small **✕ cancel** (Escape). Spring: `.spring(duration: 0.35, bounce: 0.25)`. The row does not shift height.
- A hairline progress bar under the capsule drains over **4 s**; when it hits zero the capsule reverts to idle. Any pointer movement over the capsule pauses the timer.
- **Confirm** → capsule becomes a spinner, `SIGTERM`, rescan; the row collapses with a spring when the port disappears; escalates to `SIGKILL` after 2 s if enabled.
- **Failure** → capsule shows `exclamationmark.triangle` + short reason for 3 s, then reverts.
- **Option-click** on the idle button skips confirmation (documented in the tooltip).
- **Reduce Motion** (`@Environment(\.accessibilityReduceMotion)`): all spring/geometry transitions are replaced with `.opacity` crossfades at 0.15 s; the progress drain becomes a static countdown label; row removal is a fade, not a collapse.
- Accessibility: the capsule is a container with two labelled buttons; state changes are announced ("Confirm kill node, port 3000").

Only one row can be in `confirming` at a time; starting another cancels the first.

---

## 7. Website (TanStack Start on Cloudflare Workers)

Scaffold with `npm create cloudflare@latest -- web --framework=tanstack-start` (the officially supported path since October 2025), then trim. Verified config:

```ts
// web/vite.config.ts
import { defineConfig } from 'vite'
import { tanstackStart } from '@tanstack/react-start/plugin/vite'
import { cloudflare } from '@cloudflare/vite-plugin'
import viteReact from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [
    cloudflare({ viteEnvironment: { name: 'ssr' } }),
    tanstackStart({ prerender: { enabled: true, crawlLinks: true, autoSubfolderIndex: true } }),
    viteReact(),
  ],
})
```

```jsonc
// web/wrangler.jsonc
{
  "$schema": "node_modules/wrangler/config-schema.json",
  "name": "lokal-web",
  "compatibility_date": "2026-09-09",
  "compatibility_flags": ["nodejs_compat"],
  "main": "@tanstack/react-start/server-entry",
  "routes": [{ "pattern": "lokal.sigurdarson.is", "custom_domain": true }],
  "observability": { "enabled": false }
}
```

- **Static-first**: every route is prerendered at build time into static assets. The Worker only exists as the SSR fallback the framework needs; no KV, D1, auth, or bindings.
- **Pages**: `/` (hero, screenshot, install via Homebrew and `/download`, feature list, GitHub link) and `/changelog` (renders the root `CHANGELOG.md`, imported with Vite `?raw` and rendered with `marked` at build time).
- **`/appcast.xml`**: committed static file at `web/public/appcast.xml`, written by the release workflow.
- **`/download`**: one line in `web/public/_redirects` (`/download https://github.com/sigurdarson/lokal/releases/download/vX.Y.Z/Lokal-X.Y.Z.dmg`, 302 by default), rewritten by the release workflow. Verified: Workers static assets honour `_redirects`; rules run in the asset layer before the Worker, which is the default (`run_worker_first` off).
- Styling: vanilla CSS with light/dark via `prefers-color-scheme`, system font stack. No Tailwind unless you want it.
- **Deploy**: `.github/workflows/web.yml` on push to `main` (paths `web/**`, `CHANGELOG.md`) and on `workflow_call` from the release workflow. Steps: pnpm install, `pnpm build`, `cloudflare/wrangler-action@v4` with `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` secrets. PRs run `pnpm build` only.
- Requirement: the `sigurdarson.is` zone must be on Cloudflare DNS for `custom_domain` routes. If it is not, the alternative is a `workers.dev` URL plus a CNAME, which loses the custom-domain automation.

---

## 8. Release pipeline

### 8.1 Versioning

- Semantic versioning; tags `vX.Y.Z`. `MARKETING_VERSION` = `X.Y.Z`. `CURRENT_PROJECT_VERSION` (`CFBundleVersion`, what Sparkle compares) = `X*10000 + Y*100 + Z` (0.1.0 → 100), deterministic and monotonic. Prereleases (`v0.2.0-beta.1`) go to a Sparkle `beta` channel (v1.0 scope).
- `CHANGELOG.md` in Keep a Changelog format, maintained by hand under `## [Unreleased]`; `scripts/release.sh X.Y.Z` moves it to a dated section, bumps the version in the project, commits `chore(release): vX.Y.Z`, and tags. Release notes for GitHub are extracted from that section.
- Conventional commits enforced on PR titles (squash merge) with `amannn/action-semantic-pull-request`.

### 8.2 `release.yml` (on tag `v*`, `runs-on: macos-26`)

1. Checkout; `DEVELOPER_DIR=/Applications/Xcode_26.6.app`.
2. Import the Developer ID Application certificate (`APPLE_CERTIFICATE_P12` base64 + `APPLE_CERTIFICATE_PASSWORD`) into a temporary keychain.
3. Verify the tag matches the project version.
4. `xcodebuild archive` (scheme `Lokal`, Release, universal, hardened runtime, `ENABLE_APP_SANDBOX=NO`), then `xcodebuild -exportArchive` with `ExportOptions.plist` (`method: developer-id`, `teamID: $APPLE_TEAM_ID`).
5. Package: `Lokal-X.Y.Z.zip` via `ditto -c -k --keepParent`; `Lokal-X.Y.Z.dmg` via `hdiutil` (app + Applications symlink), then `codesign` the DMG.
6. Notarize both with `xcrun notarytool submit --wait` using an App Store Connect API key (`APPLE_API_KEY_ID`, `APPLE_API_ISSUER_ID`, `APPLE_API_KEY_P8`), then `xcrun stapler staple` the app inside the zip (re-zip) and the DMG.
7. Appcast: download the matching Sparkle 2.9.6 tools; copy the current `web/public/appcast.xml` into the archives dir so history is preserved; run
   `echo "$SPARKLE_PRIVATE_KEY" | generate_appcast --ed-key-file - --download-url-prefix "https://github.com/sigurdarson/lokal/releases/download/vX.Y.Z/" --link https://lokal.sigurdarson.is --maximum-versions 5 -o web/public/appcast.xml ./archives`.
8. GitHub Release with the DMG, the zip and the changelog section as body.
9. Update `web/public/_redirects` and `homebrew/Casks/lokal.rb` (version, sha256 of the DMG); open a PR `chore(release): publish vX.Y.Z assets` against `main` (squash-merged by the owner). The site deploys when that PR merges, via `web.yml` on push to `main`.
10. (No direct deploy step: merging the asset PR triggers `web.yml`. Note that pushes made with `GITHUB_TOKEN` do **not** trigger workflows, which is another reason the asset change goes through a PR merged by a human.)
11. Mirror the cask to the tap (§8.4).

Secrets (placeholders now): `APPLE_CERTIFICATE_P12`, `APPLE_CERTIFICATE_PASSWORD`, `APPLE_TEAM_ID`, `APPLE_API_KEY_ID`, `APPLE_API_ISSUER_ID`, `APPLE_API_KEY_P8`, `SPARKLE_PRIVATE_KEY`, `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, `HOMEBREW_TAP_TOKEN`.

### 8.3 `ci.yml` (every PR and push to main)

- `app` on `macos-26`: `swift format lint --strict`, `swift test` in `app/LokalCore`, `xcodebuild build` of the app with `CODE_SIGNING_ALLOWED=NO`, `xcodebuild test` for any app-target tests.
- `web` on `ubuntu-latest`: pnpm install, `pnpm build` (includes `tsc --noEmit`).
- `homebrew` on `ubuntu-latest`: `brew style homebrew/Casks/lokal.rb`.
- `pr-title`: conventional commit check.

### 8.4 Homebrew tap mirror

Homebrew requires a tap to be a repository named `homebrew-<name>` with `Casks/` at its root, so the cask cannot live only in this monorepo. Design:

- Source of truth: `homebrew/Casks/lokal.rb` here. The directory layout mirrors the tap exactly so the mirror step is a file copy.
- Tap: `github.com/sigurdarson/homebrew-tap`, public, created once by hand (empty, with a README saying it is generated from `sigurdarson/lokal` and never edited manually). The release workflow clones it with `HOMEBREW_TAP_TOKEN` (fine-grained PAT, contents: read/write on that one repo), copies `homebrew/Casks/lokal.rb` to `Casks/lokal.rb`, commits `lokal X.Y.Z`, pushes.
- Users: `brew install sigurdarson/tap/lokal` (Homebrew expands `sigurdarson/tap` to `sigurdarson/homebrew-tap`).

```ruby
cask "lokal" do
  version "0.1.0"
  sha256 "<sha256 of the dmg>"

  url "https://github.com/sigurdarson/lokal/releases/download/v#{version}/Lokal-#{version}.dmg"
  name "Lokal"
  desc "Menu bar app that shows what is running on localhost"
  homepage "https://lokal.sigurdarson.is/"

  livecheck do
    url "https://lokal.sigurdarson.is/appcast.xml"
    strategy :sparkle, &:short_version
  end

  auto_updates true
  depends_on macos: ">= :sequoia"

  app "Lokal.app"

  zap trash: [
    "~/Library/Application Support/Lokal",
    "~/Library/Caches/is.sigurdarson.lokal",
    "~/Library/Preferences/is.sigurdarson.lokal.plist",
  ]
end
```

---

## 9. Repo hygiene (first commit)

- `README.md`: what it is, screenshot placeholder, install (Homebrew, direct download), how project detection works, how to add a service definition, monorepo map, building locally (`DEVELOPER_DIR` note), privacy statement (no network except Sparkle; local unix socket for Docker).
- `LICENSE` (MIT), `CONTRIBUTING.md` (setup, conventional commits, `swift format`, tests, adding services), `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1), `SECURITY.md` (private reporting via GitHub security advisories), `.gitignore` (Xcode, SPM, node, wrangler), `.editorconfig`, `.swift-format`, issue templates (bug, feature, config with link to discussions), PR template, `dependabot.yml`, `CODEOWNERS`.
- `CHANGELOG.md` with `[Unreleased]`.

---

## 10. Roadmap

### v0.1 — minimum useful (local builds, no signing)
- `LokalCore`: libproc socket source, process inspector (name, path, cwd, ppid, argv), project resolver, service catalog + matcher, snapshot/grouping. Swift Testing suites for port parsing (fixtures built from real `socket_fdinfo` byte layouts), service matching, project detection.
- App: MenuBarExtra panel with grouped rows, refresh on open + 2 s polling, actions (open in browser, copy URL, reveal in Finder, open in editor, kill with inline confirm + Reduce Motion), Settings (launch at login, editor, force-kill toggle), Sparkle wired to the feed URL (no releases yet).
- Repo hygiene, `ci.yml`, website scaffold with landing + changelog, `web.yml`, cask file, `release.yml` written but exercised only with dry-run/placeholder secrets.

### v0.2 — polish
- Docker/OrbStack container names and "Stop container"; argv-based labels for generic runtimes; low-confidence port hints.
- Badge count with opt-in background polling; keyboard navigation; filter field; empty/error/EPERM states; "all interfaces" indicator.
- App icon, real screenshot, landing page copy; performance pass (caching, diffing); accessibility audit (VoiceOver, Reduce Motion, Increase Contrast).
- Decide deployment target for 1.0 (15 vs 26) once macOS 27 is GA.

### v1.0 — distribution
- Signing, notarization, DMG/zip, GitHub Release, appcast, `_redirects`, cask + tap mirror, website deploy: all from one tag push. First public release; verify Sparkle update from 1.0.0 to 1.0.1 and `brew install`/`brew upgrade` end-to-end.
- Sparkle beta channel, `SECURITY.md` contact live, README screenshot.

---

## 11. Decisions (confirmed 2026-09-09)

| Topic | Decision |
|---|---|
| macOS support | Deployment target **15.0** (covers 15 + 26 today). Bump to 26.0 at v1.0 once macOS 27 is GA. |
| Architecture | **arm64 only**. No Intel builds. |
| Bundle id | `is.sigurdarson.lokal` |
| Copyright | `G. Sigurdarson` |
| Web package manager | **pnpm** |
| Cloudflare | `sigurdarson.is` zone is on the owner's account; owner adds `CLOUDFLARE_API_TOKEN` / `CLOUDFLARE_ACCOUNT_ID` secrets. |
| Tap | `sigurdarson/homebrew-tap` created by the agent; never edited by hand. |
| Release commits | Release workflow opens a **PR** for the asset commit (appcast, `_redirects`, cask). All PRs are **squash-merged**. Site deploys on merge to `main`. |
| Kill interaction | Inline morph-to-confirm as in §6. |
| Editors | VS Code → Cursor → Zed → Xcode → JetBrains → system default, plus **Open in Terminal**. |
| Signing | Owner has an Apple Developer account; certificate and notarization setup is guided at v1.0. |
| Sparkle keys | Generated by the agent; private key handed to the owner and stored as `SPARKLE_PRIVATE_KEY`. |
| Listening scope | Show TCP listeners on loopback **and** all-interface binds (that is how most dev servers bind). UDP excluded. |
| Website styling | **CSS modules**, no Tailwind. |
| Delivery | Several **stacked PRs** (each based on the previous), squash-merged in order. |
| Privacy prompts | Accept macOS one-time folder-access prompts when a project lives in Desktop/Documents/Downloads. |
| Menu bar icon | SF Symbol `network.slash` as placeholder until a custom icon exists. |

### 11.1 Stacked PR sequence for v0.1

1. `chore: repository scaffold` — PLAN, README, LICENSE, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, CHANGELOG, editor/format config, templates, dependabot, CODEOWNERS.
2. `feat(core): LokalCore package` — sockets, processes, projects, services, Docker, tests, `ci.yml` app job.
3. `feat(app): menu bar app` — Xcode project, panel UI, kill interaction, settings, launch at login, Sparkle wiring.
4. `feat(web): website` — TanStack Start on Cloudflare Workers, landing + changelog, `web.yml`.
5. `feat(release): release pipeline and cask` — `release.yml`, DMG/notarization scripts, cask, tap mirror.
