#!/usr/bin/env bash
# Points the website download redirect and the Homebrew cask at a released version.
# Usage: update-release-pointers.sh X.Y.Z <sha256 of Lokal-X.Y.Z.dmg>
set -euo pipefail

version="${1:?version required}"
sha256="${2:?dmg sha256 required}"
if [[ ! "$sha256" =~ ^[0-9a-f]{64}$ ]]; then
  echo "sha256 must be 64 lowercase hex characters" >&2
  exit 1
fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dmg_url="https://github.com/sigurdarson/lokal/releases/download/v${version}/Lokal-${version}.dmg"

cat > "$root/web/public/_redirects" <<REDIRECTS
# Rewritten by the release workflow. Do not edit by hand.
/download ${dmg_url} 302
REDIRECTS

cask="$root/homebrew/Casks/lokal.rb"
sed -i '' -E "s/^(  version )\"[^\"]+\"/\1\"${version}\"/" "$cask"
sed -i '' -E "s/^(  sha256 )\"[^\"]+\"/\1\"${sha256}\"/" "$cask"

echo "Updated web/public/_redirects and homebrew/Casks/lokal.rb for v${version}"
