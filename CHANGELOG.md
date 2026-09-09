# Changelog

All notable changes to Lokal are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-09-09

### Added

- Project scaffold, plan, and contribution guidelines.
- `LokalCore`: native listening-socket enumeration via libproc, process inspection (name, path, cwd, argv), project detection from manifests and git roots, a JSON service catalog with 40+ definitions, and Docker/OrbStack container lookup over the local Engine socket.
- Menu bar app: ports grouped by project, with open and kill on every row and copy URL, reveal in Finder, open in editor or terminal in the context menu. Kill asks for confirmation inline, morphing in place and respecting Reduce Motion. Groups fold and remember it. Refresh on open with two-second polling while visible, optional menu bar count, launch at login, settings window, Sparkle updates.
- Website at lokal.sigurdarson.is: TanStack Start on Cloudflare Workers, fully prerendered, with a changelog page generated from this file, the Sparkle appcast and the `/download` redirect. Deploys from `main`.
- Ports are classified as primary or hidden. Debug inspectors, ephemeral-range sockets, GUI applications and system daemons are left out by default; a setting shows them.
- Signed and notarized builds, distributed as a `.dmg` and through `brew install sigurdarson/tap/lokal`, with automatic updates via Sparkle.

[Unreleased]: https://github.com/sigurdarson/lokal/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/sigurdarson/lokal/releases/tag/v0.1.0
