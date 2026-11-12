#!/usr/bin/env python3
"""Static smoke checks for skill contracts. Not an agent-evaluation suite.

Checks that (1) every skill on disk has contract markers defined here and every
entry here maps to a skill on disk, (2) each marker phrase appears in its
SKILL.md, and (3) tests/behavior-cases.md has at least one case per skill and
no case for a missing skill. A recorded result per case is expected under
"Last run" in that file; a missing result is only a warning.

Presence of a phrase does not prove the behavior. Behavioral evidence lives in
tests/behavior-cases.md.
"""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parent.parent

# Markers are keyed by skill name, so moving a skill between surfaces needs no edit.
MARKERS = {
    "micronaut-stack-hygiene": ["io.micronaut.test.annotation.MockBean", "micronaut-spring"],
    "jvm-fatjar-deploy-verification": ["positive bootstrap oracle", "UNVERIFIED"],
    "aws-deploy-and-iam-diagnostics": ["live authorization proof", "package bytes"],
    "incremental-implementation-workflow": ["project-designated", "negative controls"],
    "learned-operations": ["Context is not covered by trust"],
    "three-amigos": ["decision table", "eight sections"],
    "owner-question-review": ["OWNER REQUIRED", "RESOLVED"],
    "scenario-integrity": ["approved baseline", "observable assertion"],
    "independent-verification": ["unverified hypothesis", "actual"],
}

skills = {
    p.name: p
    for surface in (root / "skills").iterdir() if surface.is_dir()
    for p in surface.iterdir() if p.is_dir() and (p / "SKILL.md").exists()
}

errors = []
warnings = []

for name in sorted(skills):
    if name not in MARKERS:
        errors.append(f"skill '{name}' has no contract markers; add it to MARKERS in scripts/check_contracts.py")
for name in sorted(MARKERS):
    if name not in skills:
        errors.append(f"contract markers defined for '{name}' but no such skill exists")

for name, markers in MARKERS.items():
    if name not in skills:
        continue
    body = (skills[name] / "SKILL.md").read_text().lower()
    for marker in markers:
        if marker.lower() not in body:
            errors.append(f"{name}: missing contract marker '{marker}'")

# Behavior-case coverage.
cases_file = root / "tests" / "behavior-cases.md"
if not cases_file.exists():
    errors.append("tests/behavior-cases.md is missing")
else:
    text = cases_file.read_text()
    sections = {s.split("\n", 1)[0].strip(): s for s in re.split(r"\n(?=## )", text)}
    cases_section = next((v for k, v in sections.items() if k.startswith("## Cases")), "")
    results_section = next((v for k, v in sections.items() if k.startswith("## Last run")), "")
    case_rows = re.findall(r"^\|\s*(B\d+)\s*\|\s*([a-z0-9-]+)\s*\|", cases_section, flags=re.M)
    result_ids = set(re.findall(r"^\|\s*(B\d+)\s*\|", results_section, flags=re.M))
    covered = {skill for _, skill in case_rows}
    for name in sorted(skills):
        if name not in covered:
            errors.append(f"tests/behavior-cases.md has no case for skill '{name}'")
    for case_id, skill in case_rows:
        if skill not in skills:
            errors.append(f"tests/behavior-cases.md case {case_id} names unknown skill '{skill}'")
        if case_id not in result_ids:
            warnings.append(f"behavior case {case_id} has no recorded result under 'Last run'")

for warning in warnings:
    print("WARN:", warning)
if errors:
    for error in errors:
        print("ERROR:", error)
    sys.exit(1)
print(f"All {len(skills)} skill contracts have expected static markers; every skill has behavior cases.")
