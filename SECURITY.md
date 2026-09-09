# Security policy

Lokal inspects local processes and can terminate them, so bugs here matter.

## Supported versions

Only the latest release receives fixes.

## Reporting a vulnerability

Please do not open a public issue. Use [GitHub private vulnerability reporting](https://github.com/sigurdarson/lokal/security/advisories/new) for this repository. You should get a first response within a week.

Include steps to reproduce, the Lokal and macOS versions, and what you believe the impact is.

## Scope

In scope: anything that lets Lokal read data it should not, kill a process it should not, execute code, or be tricked into fetching updates from somewhere other than the signed appcast.

Out of scope: the inherent fact that Lokal can see and kill processes owned by the current user. That is its purpose.
