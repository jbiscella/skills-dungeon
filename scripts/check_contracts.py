#!/usr/bin/env python3
"""Static smoke checks for required skill contracts; not an agent-evaluation suite."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parent.parent
checks = {
    "skills/code/micronaut-stack-hygiene/SKILL.md": ["io.micronaut.test.annotation.MockBean", "micronaut-spring"],
    "skills/code/jvm-fatjar-deploy-verification/SKILL.md": ["positive bootstrap oracle", "UNVERIFIED"],
    "skills/code/aws-deploy-and-iam-diagnostics/SKILL.md": ["live authorization proof", "package bytes"],
    "skills/code/incremental-implementation-workflow/SKILL.md": ["project-designated", "negative controls"],
    "skills/code/learned-operations/SKILL.md": ["Context is not covered by trust"],
    "skills/chat/three-amigos/SKILL.md": ["decision table", "eight sections"],
    "skills/chat/owner-question-review/SKILL.md": ["OWNER REQUIRED", "RESOLVED"],
    "skills/code/scenario-integrity/SKILL.md": ["approved baseline", "observable assertion"],
    "skills/code/independent-verification/SKILL.md": ["unverified hypothesis", "actual"],
}
errors = []
for name, markers in checks.items():
    path = root / name
    if not path.exists():
        errors.append(f"missing skill {name}")
        continue
    body = path.read_text()
    for marker in markers:
        if marker.lower() not in body.lower():
            errors.append(f"{name}: missing contract marker {marker}")
if errors:
    for error in errors:
        print("ERROR:", error)
    sys.exit(1)
print("All nine skill contracts have expected static markers.")
