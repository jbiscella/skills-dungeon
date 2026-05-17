#!/usr/bin/env bash
#
# validate.sh — validate every skills/<name>/SKILL.md
#
# Checks:
# 1. SKILL.md exists in each skill folder
# 2. Frontmatter has 'name' and 'description' fields
# 3. Description does not contain a literal colon ':' in YAML-ambiguous position
#    (causes packaging validator to choke; see history of micronaut-stack-hygiene
#    initial breakage)
# 4. Description does not contain angle brackets '<' or '>'
#
# Usage:
#   scripts/validate.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_SRC="$TOOLKIT_ROOT/skills"

errors=0

for d in "$SKILLS_SRC"/*/; do
    skill="$(basename "$d")"
    skill_md="$d/SKILL.md"

    echo "Validating: $skill"

    if [ ! -f "$skill_md" ]; then
        echo "  ERROR: SKILL.md missing"
        errors=$((errors + 1))
        continue
    fi

    # Extract frontmatter (between the first two --- lines)
    frontmatter=$(awk '/^---$/{f++; next} f==1' "$skill_md")

    if [ -z "$frontmatter" ]; then
        echo "  ERROR: no frontmatter found (must start with ---)"
        errors=$((errors + 1))
        continue
    fi

    # Check required fields
    if ! echo "$frontmatter" | grep -q '^name:'; then
        echo "  ERROR: frontmatter missing 'name:' field"
        errors=$((errors + 1))
    fi

    if ! echo "$frontmatter" | grep -q '^description:'; then
        echo "  ERROR: frontmatter missing 'description:' field"
        errors=$((errors + 1))
    fi

    # Check description doesn't have problematic chars
    description=$(echo "$frontmatter" | grep '^description:' | sed 's/^description: *//')

    if echo "$description" | grep -q '[<>]'; then
        echo "  WARN: description contains '<' or '>'; may break some parsers"
    fi

    # Colon followed by space inside description is a YAML hazard (treated as
    # nested key:value); single colons preceded by no space are fine.
    if echo "$description" | grep -qE ': '; then
        echo "  WARN: description contains ': '; YAML parser may misinterpret as nested mapping"
        echo "        Consider replacing with ' — ' or ' - '"
    fi

    echo "  OK"
done

echo
if [ "$errors" -gt 0 ]; then
    echo "Validation FAILED with $errors error(s)."
    exit 1
fi

echo "All skills validated successfully."
