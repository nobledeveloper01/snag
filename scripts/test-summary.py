#!/usr/bin/env python3
"""Print what the app's test run did, and fail if it did nothing.

`xcodebuild test -quiet` prints almost nothing on success, which is a green
gate with no evidence in the log. This reads the newest result bundle and says
how many tests ran — and exits 1 on zero, because a suite that executed no
tests is the definition of a gate passing for the wrong reason.
"""

import json
import subprocess
import sys
from pathlib import Path

GREEN, RED, RESET = "\033[0;32m", "\033[0;31m", "\033[0m"


def main() -> int:
    derived = Path(sys.argv[1])
    bundles = sorted((derived / "Logs" / "Test").glob("*.xcresult"), key=lambda p: p.stat().st_mtime)
    if not bundles:
        print(f"{RED}✗{RESET} no result bundle under {derived} — did xcodebuild test run?")
        return 1
    out = subprocess.run(["xcrun", "xcresulttool", "get", "test-results", "summary", "--path", str(bundles[-1])],
                         capture_output=True, text=True, check=True).stdout
    d = json.loads(out)
    total, passed, failed = d.get("totalTestCount", 0), d.get("passedTests", 0), d.get("failedTests", 0)
    skipped = d.get("skippedTests", 0)
    if total == 0 or passed == 0:
        print(f"{RED}✗{RESET} the app suite executed 0 tests")
        return 1
    if failed:
        print(f"{RED}✗{RESET} app suite: {failed} of {total} failed")
        return 1
    # A skip is named, not hidden: the device tests skip on a simulator, and
    # R2 does not move on a skip.
    note = f", {skipped} skipped (a device test waiting on a handset, or a fixture writer waiting to be asked)" if skipped else ""
    print(f"{GREEN}✓{RESET} app suite: {passed} of {total} passed on the simulator, including the accessibility audit{note}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
