#!/usr/bin/env bash
# Prints the CHANGELOG.md section for one version, for use as GitHub Release notes.
# Usage: changelog-notes.sh X.Y.Z
set -euo pipefail

version="${1:?version required}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

awk -v version="$version" '
  /^## \[/ {
    if (found) exit
    if (index($0, "## [" version "]") == 1) { found = 1; next }
  }
  found && !/^\[/ { print }
' "$root/CHANGELOG.md" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'
