#!/usr/bin/env bash
# Writes MARKETING_VERSION and a derived CURRENT_PROJECT_VERSION into the Xcode project.
# Build number = major * 10000 + minor * 100 + patch, so Sparkle sees a monotonic integer.
# Usage: set-version.sh X.Y.Z
set -euo pipefail

version="${1:?version required (X.Y.Z)}"
if [[ ! "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "Version must be X.Y.Z, got '$version'" >&2
  exit 1
fi
build=$(( ${BASH_REMATCH[1]} * 10000 + ${BASH_REMATCH[2]} * 100 + ${BASH_REMATCH[3]} ))

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project="$root/app/Lokal.xcodeproj/project.pbxproj"

sed -i '' -E "s/(MARKETING_VERSION = )[^;]+;/\1${version};/g" "$project"
sed -i '' -E "s/(CURRENT_PROJECT_VERSION = )[^;]+;/\1${build};/g" "$project"

echo "MARKETING_VERSION=$version CURRENT_PROJECT_VERSION=$build"
