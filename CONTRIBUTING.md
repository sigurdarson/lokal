# Contributing to Lokal

Thanks for helping. This page covers setup, conventions, and the two most common contributions: adding a service definition and improving project detection.

## Setup

- macOS 15 or later on Apple silicon
- Xcode 26.6 or later (the CI image uses Xcode 26.6)
- Node 22+ and pnpm, only if you touch `web/`

```sh
git clone https://github.com/sigurdarson/lokal.git
cd lokal/app/LokalCore && swift test
```

If `swift` or `xcodebuild` complain about the Command Line Tools, run with `DEVELOPER_DIR=/Applications/Xcode.app` or `sudo xcode-select -s /Applications/Xcode.app`.

Open `app/Lokal.xcodeproj` to run the app. Sparkle is fetched by Swift Package Manager on first build.

## Ground rules

- No third-party dependencies in the app other than Sparkle. Open an issue first if you think one is needed.
- Prefer native APIs over shelling out.
- Swift 6 language mode with strict concurrency. No `@unchecked Sendable` outside the C interop layer.
- Reduce Motion must be respected for any animation.
- No network calls. The only permitted outbound traffic is the Sparkle appcast.

## Formatting and tests

```sh
cd app/LokalCore
swift format lint --strict --recursive Sources Tests
swift test
```

Formatting uses the `swift format` bundled with the Xcode toolchain and the `.swift-format` file at the repo root.

## Commits and pull requests

- Pull requests are squash-merged, so the PR title becomes the commit message. Titles must follow [Conventional Commits](https://www.conventionalcommits.org): `feat(core): detect Deno projects`, `fix(app): kill button stuck in confirming state`, `docs: explain TCC prompts`.
- Scopes in use: `core`, `app`, `web`, `release`, `homebrew`, `ci`.
- Add a line under `## [Unreleased]` in `CHANGELOG.md` for anything user-visible.
- Keep PRs focused. Stacked PRs are welcome for larger work.

## Adding a service definition

1. Open `app/LokalCore/Sources/LokalCore/Services/services.json`.
2. Append an object. Required: `id` (lowercase, unique), `name`, `kind`, `icon` (an SF Symbol name), and at least one of `ports`, `processNames`, `commandPatterns`.
3. Optional: `urlTemplate` (default `http://localhost:{port}`), `openInBrowser` (default `true`), and `auxiliary` (default `false`; set it for debug inspectors and other supporting ports so they fold away by default).
4. Run `swift test`. `ServiceCatalogTests` checks the file for duplicate ids, unknown kinds, invalid regexes, and icons that do not resolve.

Prefer `processNames` and `commandPatterns` over bare `ports`. Port-only matches are treated as low-confidence hints.

## Improving project detection

Manifest parsers live in `app/LokalCore/Sources/LokalCore/Projects/`. Each parser is a small function from file contents to an optional name. Add a fixture in `Tests/LokalCoreTests/Fixtures/` and a test case in `ProjectResolverTests`.

## Reporting bugs

Use the bug report template. Include your macOS version, how the process was started, and the output of `lsof -nP -iTCP -sTCP:LISTEN` if the port is missing from Lokal.

## Releasing (maintainers)

1. Make sure `CHANGELOG.md` has entries under `[Unreleased]`.
2. Run `scripts/release.sh X.Y.Z`. It moves the entries under a dated `X.Y.Z` heading, sets the version in the Xcode project, and opens a PR.
3. Squash-merge that PR, then run `scripts/tag-release.sh X.Y.Z`. It tags `main` and pushes the tag.
4. The `Release` workflow archives, signs with Developer ID, notarizes and staples a `.dmg` and a `.zip`, creates the GitHub Release, regenerates the signed Sparkle appcast, opens a second PR that updates `web/public/_redirects`, `web/public/appcast.xml` and `homebrew/Casks/lokal.rb`, and mirrors the cask to `sigurdarson/homebrew-tap`.
5. Squash-merge the assets PR. That deploys the website, which makes the update visible to existing installs and to Homebrew.

Secrets used by the workflow: `APPLE_CERTIFICATE_P12`, `APPLE_CERTIFICATE_PASSWORD`, `APPLE_TEAM_ID`, `APPLE_API_KEY_ID`, `APPLE_API_ISSUER_ID`, `APPLE_API_KEY_P8`, `SPARKLE_PRIVATE_KEY`, `HOMEBREW_TAP_TOKEN`, plus `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` for the site. The repository setting "Allow GitHub Actions to create and approve pull requests" must be on for the assets PR.
