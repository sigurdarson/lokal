#!/usr/bin/env bash
# Submits a file to Apple's notary service and waits for the verdict.
# Usage: notarize.sh <file.zip|file.dmg>
# Expects APPLE_API_KEY_ID, APPLE_API_ISSUER_ID and APPLE_API_KEY_P8 (contents of the .p8) in the environment.
set -euo pipefail

file="${1:?file required}"
: "${APPLE_API_KEY_ID:?APPLE_API_KEY_ID is required}"
: "${APPLE_API_ISSUER_ID:?APPLE_API_ISSUER_ID is required}"
: "${APPLE_API_KEY_P8:?APPLE_API_KEY_P8 is required}"

key_file="${RUNNER_TEMP:-/tmp}/AuthKey_${APPLE_API_KEY_ID}.p8"
trap 'rm -f "$key_file"' EXIT
printf '%s\n' "$APPLE_API_KEY_P8" > "$key_file"

xcrun notarytool submit "$file" \
  --key "$key_file" \
  --key-id "$APPLE_API_KEY_ID" \
  --issuer "$APPLE_API_ISSUER_ID" \
  --wait \
  --timeout 30m
