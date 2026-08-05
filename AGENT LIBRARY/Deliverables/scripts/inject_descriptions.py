# -*- coding: utf-8 -*-
"""Inject ccai__Description__c into all Part*.apex seed scripts."""
from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from skill_descriptions import SKILL_DESCRIPTIONS, apex_escape

SCRIPTS = Path(__file__).resolve().parent
PROMPT_NAME_RE = re.compile(
    r"(prompts\.add\(new ccai__AI_Prompt__c\(\s*Name = '([^']+)',)"
    r"(.*?)"
    r"(\)\s*\);)",
    re.DOTALL,
)
DESC_LINE_RE = re.compile(
    r"\s*ccai__Description__c\s*=\s*'(?:[^'\\]|\\.)*'\s*,\r?\n"
)


def inject_file(path: Path) -> int:
    text = path.read_text(encoding="utf-8")
    count = 0

    def replacer(m: re.Match) -> str:
        nonlocal count
        name = m.group(2)
        body = m.group(3)
        if name not in SKILL_DESCRIPTIONS:
            return m.group(0)
        body = DESC_LINE_RE.sub("\n", body)
        desc = apex_escape(SKILL_DESCRIPTIONS[name])
        if "ccai__Status__c = ACTIVE," in body:
            body = body.replace(
                "ccai__Status__c = ACTIVE,",
                f"ccai__Status__c = ACTIVE,\n    ccai__Description__c = '{desc}',",
                1,
            )
        elif "ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE," in body:
            body = body.replace(
                "ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,",
                f"ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,\n    ccai__Description__c = '{desc}',",
                1,
            )
        else:
            return m.group(0)
        count += 1
        return m.group(1) + body + m.group(4)

    new_text = PROMPT_NAME_RE.sub(replacer, text)
    if new_text != text:
        path.write_text(new_text, encoding="utf-8")
    return count


def main() -> None:
    total = 0
    for path in sorted(SCRIPTS.glob("Part*.apex")):
        if path.name == "Part0_DeleteAll.apex":
            continue
        n = inject_file(path)
        total += n
        print(f"{path.name}: {n} descriptions")
    print(f"Total: {total} skill descriptions injected")


if __name__ == "__main__":
    main()
