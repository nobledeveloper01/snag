#!/usr/bin/env python3
"""Read `swift test --enable-code-coverage`'s export and gate the domain.

    coverage-report.py <codecov.json>            print the per-file breakdown
    coverage-report.py <codecov.json> --gate 95  exit 1 below the floor

The floor applies to `SnagDomain/Sources/` only. Pure functions with no
ambient state are cheap to cover, so the figure means something there; the
same figure over view code would be theatre.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

GREEN, RED, RESET = "\033[0;32m", "\033[0;31m", "\033[0m"


def main() -> int:
    args = sys.argv[1:]
    path = Path(args[0])
    gate = float(args[args.index("--gate") + 1]) if "--gate" in args else None
    data = json.loads(path.read_text())["data"][0]
    files = [f for f in data["files"] if "/Sources/SnagDomain/" in f["filename"]]
    if not files:
        print(f"{RED}✗{RESET} no domain files in the coverage export — check the path")
        return 1
    covered = sum(f["summary"]["lines"]["covered"] for f in files)
    total = sum(f["summary"]["lines"]["count"] for f in files)
    pct = 100.0 * covered / total if total else 0.0
    for f in sorted(files, key=lambda f: f["summary"]["lines"]["percent"]):
        name = f["filename"].split("/Sources/SnagDomain/")[1]
        print(f"  {f['summary']['lines']['percent']:6.1f}%  {name}")
    if gate is None:
        print(f"\ndomain: {pct:.1f}% of {total} lines")
        return 0
    if pct < gate:
        print(f"{RED}✗{RESET} domain coverage {pct:.1f}% is below the {gate:.0f}% floor")
        return 1
    print(f"{GREEN}✓{RESET} coverage gate passed ({pct:.1f}% ≥ {gate:.0f}%)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
