#!/usr/bin/env bash
# Prepares a release: moves Unreleased changelog entries under the new version, bumps the
# Xcode project version, and opens a pull request. Tag after the PR is squash-merged with tag-release.sh.
# Usage: release.sh X.Y.Z
set -euo pipefail

version="${1:?version required (X.Y.Z)}"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must be X.Y.Z" >&2
  exit 1
fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree is not clean" >&2
  exit 1
fi
if git rev-parse "v$version" > /dev/null 2>&1; then
  echo "Tag v$version already exists" >&2
  exit 1
fi

changelog="CHANGELOG.md"
if ! awk '/^## \[Unreleased\]/{f=1;next} /^## \[/{f=0} f && NF' "$changelog" | grep -q .; then
  echo "CHANGELOG.md has nothing under [Unreleased]" >&2
  exit 1
fi

today="$(date +%Y-%m-%d)"
previous="$(grep -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "$changelog" | head -1 | tr -d '#[] ' || true)"

python3 - "$changelog" "$version" "$today" "$previous" <<'PY'
import re, sys
path, version, today, previous = sys.argv[1:5]
text = open(path).read()
text = text.replace("## [Unreleased]\n", f"## [Unreleased]\n\n## [{version}] - {today}\n", 1)
repo = "https://github.com/sigurdarson/lokal"
text = re.sub(r"^\[Unreleased\]: .*$", f"[Unreleased]: {repo}/compare/v{version}...HEAD", text, flags=re.M)
link = f"[{version}]: {repo}/compare/v{previous}...v{version}" if previous else f"[{version}]: {repo}/releases/tag/v{version}"
text = text.rstrip("\n") + "\n" + link + "\n"
open(path, "w").write(text)
PY

scripts/set-version.sh "$version"

branch="release/v$version"
git switch -c "$branch"
git add CHANGELOG.md app/Lokal.xcodeproj/project.pbxproj
git commit -m "chore(release): v$version"
git push -u origin "$branch"
gh pr create --base main --title "chore(release): v$version" --body "$(cat <<BODY
Release v$version.

- Moves Unreleased changelog entries under this version
- Sets MARKETING_VERSION and CURRENT_PROJECT_VERSION

After squash-merging, run \`scripts/tag-release.sh $version\` to tag main and trigger the release workflow.
BODY
)"
