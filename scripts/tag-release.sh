#!/usr/bin/env bash
# Tags the merged release commit on main and pushes the tag, which triggers .github/workflows/release.yml.
# Usage: tag-release.sh X.Y.Z
set -euo pipefail

version="${1:?version required (X.Y.Z)}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

git fetch origin main
git switch main
git pull --ff-only origin main

project_version="$(grep -m1 -oE 'MARKETING_VERSION = [^;]+' app/Lokal.xcodeproj/project.pbxproj | awk '{print $3}')"
if [[ "$project_version" != "$version" ]]; then
  echo "main has MARKETING_VERSION=$project_version, expected $version. Merge the release PR first." >&2
  exit 1
fi
if ! grep -q "^## \[$version\]" CHANGELOG.md; then
  echo "CHANGELOG.md has no section for $version" >&2
  exit 1
fi

git tag -a "v$version" -m "Lokal $version"
git push origin "v$version"
echo "Pushed v$version. Follow the release at https://github.com/sigurdarson/lokal/actions/workflows/release.yml"
