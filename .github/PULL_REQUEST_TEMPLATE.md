<!-- Title must follow Conventional Commits, e.g. "feat(core): detect Bun projects". It becomes the squash commit message. -->

## What

<!-- One or two sentences on what changes. -->

## Why

<!-- Link the issue if there is one. -->

## Checklist

- [ ] `swift test` passes in `app/LokalCore` (if the app changed)
- [ ] `pnpm build` passes in `web/` (if the site changed)
- [ ] Added a line to `CHANGELOG.md` under Unreleased (if user-visible)
- [ ] Animations respect Reduce Motion (if UI changed)
- [ ] No new dependencies, or the PR explains why one is needed
