#!/usr/bin/env bash
#
# Fail if the app could talk to a network.
#
# The product statement says nothing leaves the device, and the App Store
# privacy label will say "Data Not Collected". Both are claims; this is what
# makes them checkable. It greps the app and domain sources for the things a
# network path is made of. A URL in a comment counts, deliberately: a comment
# is where a URL waits to be uncommented.
set -uo pipefail
cd "$(dirname "$0")/.."
RED=$'\033[0;31m'; GRN=$'\033[0;32m'; OFF=$'\033[0m'

hits=$(grep -rnE 'URLSession|https?://|import Network|NWConnection|CFStream|NSURLConnection' \
         --include='*.swift' Snag SnagShared SnagWidgets SnagDomain/Sources 2>/dev/null || true)
if [ -n "$hits" ]; then
  printf '%s✗%s the app has a network path, and the product says it does not:\n%s\n' "$RED" "$OFF" "$hits"
  exit 1
fi
# CloudKit is the one exception, and only in Snag/Cloud: the tenant's own
# iCloud, private database, opt-in — ADR-0005. Anywhere else it is a leak.
leak=$(grep -rln 'import CloudKit' --include='*.swift' Snag SnagShared SnagWidgets SnagDomain/Sources 2>/dev/null | grep -v '^Snag/Cloud/' || true)
if [ -n "$leak" ]; then
  printf '%s✗%s CloudKit imported outside Snag/Cloud:\n%s\n' "$RED" "$OFF" "$leak"
  exit 1
fi
n=$(find Snag SnagShared SnagWidgets SnagDomain/Sources -name '*.swift' | wc -l | tr -d ' ')
printf '%s✓%s no network path in %s source files — nothing leaves the device but through the share sheet, or to the tenant'"'"'s own iCloud from Snag/Cloud\n' "$GRN" "$OFF" "$n"
