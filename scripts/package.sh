#!/usr/bin/env bash
#
# package.sh — rebuild .skill packages from skills/<surface>/<name>/ folders
#
# Skills live under a surface subfolder: skills/code/ for Claude Code skills,
# skills/chat/ for Claude.ai chat skills. Package output stays flat under
# packaged/ — surface is conveyed by documentation, not by archive path.
#
# Each .skill file is a zip with the skill folder at the archive root
# (i.e. <skill>/SKILL.md), per the Anthropic Agent Skills convention. This is
# also the shape Claude.ai requires for Settings > Customize > Skills uploads.
#
# Usage:
#   scripts/package.sh                  # package all skills
#   scripts/package.sh <skill-name>     # package one skill by bare name

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_SRC="$TOOLKIT_ROOT/skills"
PACKAGED_DIR="$TOOLKIT_ROOT/packaged"

mkdir -p "$PACKAGED_DIR"

# Find the surface folder for a given bare skill name. Echoes the surface name
# (e.g. "code", "chat") to stdout, or returns non-zero if not found / ambiguous.
locate_surface() {
    local skill="$1"
    local found=""
    for surface_dir in "$SKILLS_SRC"/*/; do
        local surface
        surface="$(basename "$surface_dir")"
        if [ -d "$surface_dir$skill" ]; then
            if [ -n "$found" ]; then
                echo "ERROR: skill '$skill' exists under multiple surfaces ($found, $surface). Disambiguate." >&2
                return 2
            fi
            found="$surface"
        fi
    done
    if [ -z "$found" ]; then
        echo "ERROR: skill '$skill' not found under any surface in $SKILLS_SRC" >&2
        return 1
    fi
    echo "$found"
}

package_one() {
    local skill="$1"
    local surface
    surface="$(locate_surface "$skill")" || return 1

    local src_parent="$SKILLS_SRC/$surface"
    local src="$src_parent/$skill"
    local out="$PACKAGED_DIR/$skill.skill"

    if [ ! -f "$src/SKILL.md" ]; then
        echo "ERROR: $src/SKILL.md not found; not a valid skill folder" >&2
        return 1
    fi

    rm -f "$out"
    (cd "$src_parent" && zip -r -q "$out" "$skill" -x '*.DS_Store' '*/__pycache__/*' '*/node_modules/*')
    echo "packaged: $out  (from $surface/$skill)"
}

if [ "$#" -eq 0 ]; then
    for surface_dir in "$SKILLS_SRC"/*/; do
        for d in "$surface_dir"*/; do
            [ -d "$d" ] || continue
            package_one "$(basename "$d")"
        done
    done
else
    for skill in "$@"; do
        package_one "$skill"
    done
fi

echo
echo "Done. .skill files are in $PACKAGED_DIR/"
