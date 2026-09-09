#!/usr/bin/env bash
# Imports a Developer ID Application certificate into a throwaway keychain on CI.
# Expects APPLE_CERTIFICATE_P12 (base64 of the .p12) and APPLE_CERTIFICATE_PASSWORD in the environment.
set -euo pipefail

: "${APPLE_CERTIFICATE_P12:?APPLE_CERTIFICATE_P12 is required}"
: "${APPLE_CERTIFICATE_PASSWORD:?APPLE_CERTIFICATE_PASSWORD is required}"

keychain="${RUNNER_TEMP:-/tmp}/lokal-signing.keychain-db"
keychain_password="$(openssl rand -hex 24)"
certificate="${RUNNER_TEMP:-/tmp}/certificate.p12"

trap 'rm -f "$certificate"' EXIT
printf '%s' "$APPLE_CERTIFICATE_P12" | base64 --decode > "$certificate"

security create-keychain -p "$keychain_password" "$keychain"
security set-keychain-settings -lut 3600 "$keychain"
security unlock-keychain -p "$keychain_password" "$keychain"
security import "$certificate" -k "$keychain" -P "$APPLE_CERTIFICATE_PASSWORD" -T /usr/bin/codesign -T /usr/bin/security
security set-key-partition-list -S apple-tool:,apple: -s -k "$keychain_password" "$keychain" > /dev/null
security list-keychains -d user -s "$keychain" login.keychain-db

identity="$(security find-identity -v -p codesigning "$keychain" | grep "Developer ID Application" | head -1 | sed -E 's/.*"(.*)"/\1/')"
if [[ -z "$identity" ]]; then
  echo "No Developer ID Application identity found in the imported certificate" >&2
  exit 1
fi
echo "Imported: $identity"
