# Changelog

All notable changes to Lokal are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Project scaffold, plan, and contribution guidelines.
- `LokalCore`: native listening-socket enumeration via libproc, process inspection (name, path, cwd, argv), project detection from manifests and git roots, a JSON service catalog with 40+ definitions, and Docker/OrbStack container lookup over the local Engine socket.
- Menu bar app: grouped port list, per-row actions (open, copy URL, reveal in Finder, open in editor or terminal), inline kill confirmation with a draining countdown that respects Reduce Motion, refresh on open with two-second polling while visible, optional menu bar count, launch at login, settings window, Sparkle updates.
- Website at lokal.sigurdarson.is: TanStack Start on Cloudflare Workers, fully prerendered, with a changelog page generated from this file, the Sparkle appcast and the `/download` redirect. Deploys from `main`.
- Ports are classified as primary or hidden. Debug inspectors, ephemeral-range sockets, GUI applications and system daemons fold behind a per-group "hidden ports" row, with a setting to always show them.
- Release pipeline: a tag push archives, signs with Developer ID, notarizes and staples a `.dmg` and `.zip`, publishes a GitHub Release, regenerates the signed Sparkle appcast, opens a PR that updates the download redirect and cask, and mirrors the cask to `sigurdarson/homebrew-tap`.

[Unreleased]: https://github.com/sigurdarson/lokal/compare/main...HEAD
