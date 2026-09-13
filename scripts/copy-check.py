#!/usr/bin/env python3
"""Fail if anything the app or the PDF says claims proof.

ADR-0003: the report is evidence, not proof. A signature proves the bytes
have not changed since signing; it proves nothing about when. The tempting
words are one word long, so the gate is a word list over every user-facing
string and the PDF's own text, run without building.

What it reads: `Snag/Speech/Strings.swift`, `Snag/Report/ReportText.swift`,
`Config/Info.plist`, and `docs/APPSTORE.md` if it exists.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GREEN, RED, RESET = "\033[0;32m", "\033[0;31m", "\033[0m"

SOURCES = [
    ROOT / "Snag" / "Speech" / "Strings.swift",
    ROOT / "Snag" / "Report" / "ReportText.swift",
    ROOT / "Config" / "Info.plist",
    ROOT / "docs" / "APPSTORE.md",
]

# Whole words, any inflection that matters.
BANNED = re.compile(r"\b(proof|proofs|prove|proves|proven|certified|certify|notarised|notarized|verified|verify|verifies)\b", re.IGNORECASE)


def strings_in(path: Path) -> list[str]:
    text = path.read_text()
    if path.suffix == ".swift":
        # Strip comments; then every string literal.
        text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
        text = "\n".join(l for l in text.splitlines() if not l.lstrip().startswith("//"))
        return re.findall(r'"((?:[^"\\]|\\.)*)"', text)
    if path.suffix == ".plist":
        return re.findall(r"<string>(.*?)</string>", text, re.DOTALL)
    return [text]


def main() -> int:
    failures: list[str] = []
    counted = 0
    for path in SOURCES:
        if not path.exists():
            continue
        for s in strings_in(path):
            counted += 1
            m = BANNED.search(s)
            if m:
                failures.append(f"{path.relative_to(ROOT)}: '{m.group(0)}' in \"{s[:70]}\"")
    for line in failures:
        print(f"{RED}✗{RESET} {line}")
    if failures:
        print(f"\n{RED}copy gate failed{RESET} — the report is evidence, not proof. ADR-0003.")
        return 1
    print(f"{GREEN}✓{RESET} nothing the app or the PDF says claims proof — {counted} strings checked against the word list")
    return 0


if __name__ == "__main__":
    sys.exit(main())
