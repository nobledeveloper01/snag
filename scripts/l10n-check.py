#!/usr/bin/env python3
"""
Fail if any language is missing a string, or carries one the app no longer has.

The app's copy is written once, in English, in Strings.swift, ReportText.swift
and Prompts.swift, and looked up by that English text in the language the
tenant chose. A missing translation falls back to English silently — which
is exactly the kind of quiet failure a gate exists for. So: every English
string must be a key in every table, and every key must still be a string.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCES = [ROOT / "Snag/Speech/Strings.swift", ROOT / "Snag/Report/ReportText.swift", ROOT / "Snag/Speech/Prompts.swift"]
TABLES = sorted((ROOT / "Snag/Speech/Translations").glob("*.swift"))
RED, GRN, OFF = "\033[0;31m", "\033[0;32m", "\033[0m"


def literals(path: Path) -> list[str]:
    text = re.sub(r"//.*", "", path.read_text())
    return re.findall(r'"((?:[^"\\]|\\.)*)"', text)


def main() -> int:
    english = []
    for src in SOURCES:
        for lit in literals(src):
            if lit and lit not in english:
                english.append(lit)
    failures = []
    for table in TABLES:
        keys = re.findall(r'^\s*"((?:[^"\\]|\\.)*)":\s*"', table.read_text(), re.MULTILINE)
        missing = [k for k in english if k not in keys]
        stale = [k for k in keys if k not in english]
        dupes = {k for k in keys if keys.count(k) > 1}
        for k in missing:
            failures.append(f"{table.name} has no translation for: {k[:70]!r}")
        for k in stale:
            failures.append(f"{table.name} translates a string the app no longer has: {k[:70]!r}")
        for k in dupes:
            failures.append(f"{table.name} translates twice: {k[:70]!r}")
    if not TABLES:
        failures.append("no translation tables found")
    for f in failures:
        print(f"{RED}✗{OFF} {f}")
    if failures:
        print(f"\n{RED}language gate failed{OFF} — a missing translation is English shown without a word")
        return 1
    print(f"{GRN}✓{OFF} every one of {len(english)} strings is translated in all {len(TABLES)} languages, and none is stale")
    return 0


if __name__ == "__main__":
    sys.exit(main())
