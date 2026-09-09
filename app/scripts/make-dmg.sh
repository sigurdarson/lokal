#!/usr/bin/env bash
# Builds a compressed disk image containing the app and an Applications symlink.
# Usage: make-dmg.sh <path/to/Lokal.app> <output.dmg>
set -euo pipefail

app="${1:?app path required}"
output="${2:?output dmg path required}"
volume_name="$(/usr/libexec/PlistBuddy -c "Print :CFBundleName" "$app/Contents/Info.plist")"

staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT

cp -R "$app" "$staging/"
ln -s /Applications "$staging/Applications"

rm -f "$output"
hdiutil create \
  -volname "$volume_name" \
  -srcfolder "$staging" \
  -fs HFS+ \
  -format UDZO \
  -imagekey zlib-level=9 \
  -ov \
  "$output" > /dev/null

echo "Created $output ($(du -h "$output" | cut -f1))"
