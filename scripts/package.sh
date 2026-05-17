#!/usr/bin/env bash
#
# package.sh — rebuild .skill packages from skills/<name>/ folders into packaged/
#
# Usage:
#   scripts/package.sh                  # package all skills
#   scripts/package.sh <skill-name>     # package one skill
#
# Each .skill file is a zip of the skill folder (containing SKILL.md and any
# bundled resources), per the Anthropic Agent Skills convention.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_SRC="$TOOLKIT_ROOT/skills"
PACKAGED_DIR="$TOOLKIT_ROOT/packaged"

mkdir -p "$PACKAGED_DIR"

package_one() {
    local skill="$1"
    local src="$SKILLS_SRC/$skill"
    local out="$PACKAGED_DIR/$skill.skill"

    if [ ! -d "$src" ]; then
        echo "ERROR: skill '$skill' not found in $SKILLS_SRC" >&2
        return 1
    fi

    if [ ! -f "$src/SKILL.md" ]; then
        echo "ERROR: $src/SKILL.md not found; not a valid skill folder" >&2
        return 1
    fi

    rm -f "$out"
    (cd "$SKILLS_SRC" && zip -r -q "$out" "$skill" -x '*.DS_Store' '*/__pycache__/*' '*/node_modules/*')
    echo "packaged: $out"
}

if [ "$#" -eq 0 ]; then
    for d in "$SKILLS_SRC"/*/; do
        package_one "$(basename "$d")"
    done
else
    for skill in "$@"; do
        package_one "$skill"
    done
fi

echo
echo "Done. .skill files are in $PACKAGED_DIR/"
