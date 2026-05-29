#!/usr/bin/env python3
"""
check_skill.py — validate a single SKILL.md file against schema rules.

Replaces the grep-based frontmatter checks in validate.sh with a real YAML
parser. Detects hazards that line-oriented matching misses: multi-line
descriptions, quoted values, unexpected indentation, non-string scalars.

Checks performed:
  1. File starts with a '---' frontmatter delimiter.
  2. Frontmatter is closed with a matching '---'.
  3. Frontmatter parses as a YAML mapping.
  4. 'name' and 'description' fields exist and are non-empty strings.
  5. Description does not contain '<' or '>' (warning — some parsers reject).
  6. Description does not contain ': ' (warning — YAML mapping ambiguity).
  7. With --check-body: body contains a '## Minimum protocol' heading near
     the top (first 60 lines of body).

Output:
  - Warnings printed as 'WARN: ...'
  - Errors printed as 'ERROR: ...'

Exit codes:
  0 — no errors (warnings allowed)
  1 — at least one error
  2 — PyYAML missing from the environment
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print(
        "ERROR: PyYAML required. Install via `pip install pyyaml` or "
        "`apt-get install python3-yaml`.",
        file=sys.stderr,
    )
    sys.exit(2)


def parse_frontmatter(text: str) -> tuple[str | None, str | None, str | None]:
    """Return (frontmatter_text, body_text, error_message)."""
    if not (text.startswith("---\n") or text.startswith("---\r\n")):
        return None, None, "file does not start with '---' frontmatter delimiter"

    lines = text.split("\n")
    end = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end = i
            break

    if end is None:
        return None, None, "frontmatter not closed with '---'"

    fm = "\n".join(lines[1:end])
    body = "\n".join(lines[end + 1:])
    return fm, body, None


def validate(path: Path, check_body: bool) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []

    try:
        text = path.read_text(encoding="utf-8")
    except OSError as e:
        errors.append(f"cannot read file: {e}")
        return errors, warnings

    fm, body, err = parse_frontmatter(text)
    if err:
        errors.append(err)
        return errors, warnings

    try:
        data = yaml.safe_load(fm or "")
    except yaml.YAMLError as e:
        errors.append(f"frontmatter is not valid YAML: {e}")
        return errors, warnings

    if not isinstance(data, dict):
        type_name = type(data).__name__
        errors.append(f"frontmatter must parse to a mapping, got {type_name}")
        return errors, warnings

    name = data.get("name")
    description = data.get("description")

    if not isinstance(name, str) or not name.strip():
        errors.append("frontmatter missing or empty 'name' (must be a non-empty string)")
    if not isinstance(description, str) or not description.strip():
        errors.append("frontmatter missing or empty 'description' (must be a non-empty string)")

    if isinstance(description, str):
        if any(c in description for c in "<>"):
            warnings.append("description contains '<' or '>'; may break some parsers")
        if ": " in description:
            warnings.append(
                "description contains ': '; YAML parser may misinterpret as nested mapping"
            )

    if check_body and body is not None:
        head = "\n".join(body.split("\n")[:60])
        if not re.search(r"^##\s+Minimum protocol\b", head, flags=re.MULTILINE):
            errors.append(
                "body missing '## Minimum protocol' heading near the top "
                "(first 60 body lines)"
            )

    return errors, warnings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    parser.add_argument("path", type=Path, help="Path to a SKILL.md file")
    parser.add_argument(
        "--check-body",
        action="store_true",
        help="Also require '## Minimum protocol' heading near the top of the body",
    )
    args = parser.parse_args()

    errors, warnings = validate(args.path, args.check_body)
    for w in warnings:
        print(f"WARN: {w}")
    for e in errors:
        print(f"ERROR: {e}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
