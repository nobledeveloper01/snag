#!/usr/bin/env python3
"""Fail if a document quotes a figure the code does not produce.

"Three tiers", "four gates", nine room names. Read from the Swift enums and
the ledger's rows, compared with the sentences that quote them, anchored on
words either side so a reworded sentence fails loudly.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GREEN, RED, RESET = "\033[0;32m", "\033[0;31m", "\033[0m"
WORDS = {w: i for i, w in enumerate("zero one two three four five six seven eight nine ten eleven twelve".split())}


def enum_cases(name: str) -> int:
    src = re.sub(r"//.*", "", (ROOT / "SnagDomain/Sources/SnagDomain/Model.swift").read_text())
    body = src[src.index(f"enum {name}"):]
    body = body[:body.index("\n}")]
    n = 0
    for line in re.findall(r"^\s*case ([^\n]+)", body, re.MULTILINE):
        n += sum(1 for c in line.split(",") if re.match(r"^\s*\w+", c))
    return n


def number(w: str) -> int:
    return int(w) if w.isdigit() else WORDS[w.lower()]


def main() -> int:
    tiers = enum_cases("Tier")
    ledger = (ROOT / "docs/RELEASE-GATES.md").read_text()
    blocking = ledger[ledger.index("## Blocks v1.0"):ledger.index("## Cleared")]
    gates = len(re.findall(r"^\| R\d+ \|", blocking, re.MULTILINE))
    # The README's numbers line: tests, languages, ADRs, screenshots — counted, not typed.
    domain_tests = sum(len(re.findall(r"@Test\(", f.read_text())) for f in (ROOT / "SnagDomain/Tests").rglob("*.swift"))
    unit_tests = sum(len(re.findall(r"func test", f.read_text())) for f in (ROOT / "SnagTests").glob("*.swift"))
    ui_tests = sum(len(re.findall(r"func test", f.read_text())) for f in (ROOT / "SnagUITests").glob("*.swift"))
    strings = len(re.findall(r'^\s*"((?:[^"\\]|\\.)*)":\s*"', (ROOT / "Snag/Speech/Translations/Pidgin.swift").read_text(), re.MULTILINE))
    # `case english = "en", pidgin = "pcm", ...` — one enum, every case with a code.
    languages = len(re.findall(r'\w+ = "[a-z]{2,3}"', (ROOT / "Snag/Speech/L10n.swift").read_text()))
    adrs = len(list((ROOT / "docs/adr").glob("[0-9]*.md")))
    shots = len(list((ROOT / "docs/screenshots").glob("*.png")))
    claims = [
        ("README.md", r"## (\w+) tiers", tiers),
        ("README.md", r"(\w+) gates, in \[`docs/RELEASE-GATES.md`", gates),
        ("docs/ROADMAP.md", r"the (\w+) tiers a number can come from", tiers),
        ("README.md", r"\*\*The numbers\.\*\* (\d+) domain tests", domain_tests),
        ("README.md", r"· (\d+) app unit tests", unit_tests),
        ("README.md", r"· (\d+) UI tests", ui_tests),
        ("README.md", r"· (\d+) strings in (?:\w+) languages", strings),
        ("README.md", r"strings in (\w+) languages", languages),
        ("README.md", r"· (\d+) ADRs", adrs),
        ("README.md", r"· (\d+) release gates", gates),
        ("README.md", r"· (\d+) screenshots", shots),
    ]
    failures, checked = [], 0
    for rel, pattern, expected in claims:
        m = re.search(pattern, (ROOT / rel).read_text())
        if not m:
            failures.append(f"{rel}: the sentence matching /{pattern}/ is gone — reword the gate or the document")
            continue
        checked += 1
        if number(m.group(1)) != expected:
            failures.append(f"{rel} says {m.group(1)} where the code has {expected}: /{pattern}/")
    ids = re.findall(r"^\| (R\d+) \|", ledger, re.MULTILINE)
    if len(ids) != len(set(ids)):
        failures.append("RELEASE-GATES.md numbers a gate twice")
    for line in failures:
        print(f"{RED}✗{RESET} {line}")
    if failures:
        return 1
    print(f"{GREEN}✓{RESET} the documents count what the code has: {tiers} tiers, {gates} gates still blocking v1.0 — {checked} figures checked")
    return 0


if __name__ == "__main__":
    sys.exit(main())
