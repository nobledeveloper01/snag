#!/usr/bin/env bash
#
# The second verifier, proved against the first's bundle. scripts/verify.py
# was written from docs/BUNDLE-FORMAT.md alone; the fixture in
# SnagTests/Fixtures/bundle-v1 was sealed by the app. They must agree —
# and the verifier must fire, so every run also hands it a flipped report,
# a flipped photograph, a bundle with no key, and the same bundle as one
# zipped file.
set -uo pipefail
cd "$(dirname "$0")/.."
RED=$'\033[0;31m'; GRN=$'\033[0;32m'; OFF=$'\033[0m'
FIX=SnagTests/Fixtures/bundle-v1
fail=0
expect() {  # expect <label> <want-prefix> <path>
  got=$(python3 scripts/verify.py "$3" 2>&1)
  case "$got" in
    "$2"*) printf '  %s✓%s %s → %s\n' "$GRN" "$OFF" "$1" "$got";;
    *) printf '  %s✗%s %s → %s (wanted %s)\n' "$RED" "$OFF" "$1" "$got" "$2"; fail=1;;
  esac
}
T=$(mktemp -d)
expect "the app's own bundle" "unaltered" "$FIX"
cp -R "$FIX" "$T/a"; printf '\x01' | dd of="$T/a/report.bin" bs=1 seek=5 conv=notrunc 2>/dev/null
expect "one byte of report.bin flipped" "altered: report signature" "$T/a"
cp -R "$FIX" "$T/b"; p=$(ls "$T/b/photos" | head -1); printf '\x01' | dd of="$T/b/photos/$p" bs=1 seek=100 conv=notrunc 2>/dev/null
expect "one byte of a photograph flipped" "altered: photograph" "$T/b"
cp -R "$FIX" "$T/c"; touch "$T/c/photos/$(printf 'ab%.0s' $(seq 32)).jpg"
expect "a stray photograph" "altered: stray photograph" "$T/c"
cp -R "$FIX" "$T/d"; rm "$T/d/countersign.sig"
expect "a counter-signature with no signature" "altered: counter-signature incomplete" "$T/d"
cp -R "$FIX" "$T/e"; rm "$T/e/key.pub"
expect "no key" "not a bundle" "$T/e"
(cd "$FIX" && python3 -c "
import zipfile,os
with zipfile.ZipFile('$T/f.snagz','w',zipfile.ZIP_DEFLATED) as z:
    for root,_,files in os.walk('.'):
        for f in files: z.write(os.path.join(root,f), os.path.relpath(os.path.join(root,f),'.'))")
expect "the same bundle as one deflated file" "unaltered" "$T/f.snagz"
rm -rf "$T"
if [ "$fail" -eq 0 ]; then
  printf '%s✓%s the Python verifier agrees with the app and fires on every tamper it is handed\n' "$GRN" "$OFF"
else
  printf '%s✗%s the second verifier and the first disagree\n' "$RED" "$OFF"; exit 1
fi
