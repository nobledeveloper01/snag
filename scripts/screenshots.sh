#!/usr/bin/env bash
#
# Retake the README's screenshots: run ScreenshotTests on the headless
# simulator, pull the attachments out of the result bundle, and shrink them
# the way scripts/screenshot.sh does. `make screenshots`.
set -euo pipefail
cd "$(dirname "$0")/.."
SIM="${SIM:-$(xcrun simctl list devices | grep 'Snag Tests' | grep -oE '[0-9A-F-]{36}' | head -1)}"
[ -n "$SIM" ] || { echo "no 'Snag Tests' simulator"; exit 64; }
rm -rf .build/Shots; mkdir -p .build/Shots docs/screenshots
# Dark, the appearance the app is designed in first.
xcrun simctl boot "$SIM" >/dev/null 2>&1 || true
xcrun simctl ui "$SIM" appearance dark >/dev/null 2>&1 || true
TEST_RUNNER_SNAG_SCREENSHOTS=1 xcodebuild test -project Snag.xcodeproj -scheme Snag \
  -destination "platform=iOS Simulator,id=$SIM" -derivedDataPath .build/DerivedData \
  -resultBundlePath .build/Shots/shots.xcresult -only-testing:SnagUITests/ScreenshotTests -quiet 2>&1 | grep -E 'error|failed' || true
xcrun simctl shutdown "$SIM" >/dev/null 2>&1 || true
xcrun xcresulttool export attachments --path .build/Shots/shots.xcresult --output-path .build/Shots/out >/dev/null
python3 - <<'PY'
import json, pathlib
from PIL import Image
out = pathlib.Path('.build/Shots/out')
manifest = json.loads((out / 'manifest.json').read_text())
n = 0
for test in manifest:
    for a in test.get('attachments', []):
        name = a.get('suggestedHumanReadableName') or a['exportedFileName']
        stem = name.split('_')[0].replace('.png', '')
        if not stem[:2].isdigit():
            continue
        im = Image.open(out / a['exportedFileName']).convert('RGB')
        im = im.resize((540, int(im.height * 540 / im.width)), Image.LANCZOS).quantize(256)
        im.save(f'docs/screenshots/{stem}.png', optimize=True)
        n += 1
print(f'{n} screenshots written to docs/screenshots/')
PY
ls -la docs/screenshots
