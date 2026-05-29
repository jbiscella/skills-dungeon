#!/usr/bin/env bash
#
# install.sh — symlink selected Claude Code skills from this toolkit into a
# project's .claude/skills/ directory.
#
# Skills live under a surface subfolder. This script only installs skills
# under skills/code/ — Claude Code is the only surface with a .claude/skills/
# loader. Claude.ai chat skills (under skills/chat/) are uploaded via the
# Claude.ai UI (Settings > Customize > Skills) and don't fit this flow; see
# INSTALL.md for that pattern.
#
# Usage (run from the consuming project root):
#   .claude/external/skills-dungeon/scripts/install.sh <skill-name> [<skill-name>...]
#
# Example:
#   .claude/external/skills-dungeon/scripts/install.sh \
#     incremental-implementation-workflow \
#     aws-deploy-and-iam-diagnostics
#
# Creates symlinks at .claude/skills/<skill-name> pointing into the toolkit.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_SRC="$TOOLKIT_ROOT/skills/code"

# Determine consumer project root. We assume this script is at
# <project>/.claude/external/skills-dungeon/scripts/install.sh
# so the project root is 4 levels up from the script.
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TARGET_DIR="$PROJECT_ROOT/.claude/skills"

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <skill-name> [<skill-name>...]"
    echo
    echo "Available Claude Code skills:"
    for d in "$SKILLS_SRC"/*/; do
        echo "  - $(basename "$d")"
    done
    echo
    echo "Chat skills under skills/chat/ are installed via the Claude.ai UI."
    echo "See INSTALL.md."
    exit 1
fi

mkdir -p "$TARGET_DIR"

# Compute relative path from TARGET_DIR to each skill source.
# Using realpath --relative-to which is widely available on Linux.
# On macOS without coreutils, fall back to a python one-liner.
relpath() {
    if command -v realpath >/dev/null 2>&1 && realpath --help 2>&1 | grep -q -- '--relative-to'; then
        realpath --relative-to="$1" "$2"
    else
        python3 -c "import os, sys; print(os.path.relpath(sys.argv[2], sys.argv[1]))" "$1" "$2"
    fi
}

for skill in "$@"; do
    src="$SKILLS_SRC/$skill"
    dst="$TARGET_DIR/$skill"

    if [ ! -d "$src" ]; then
        echo "ERROR: Claude Code skill '$skill' not found in $SKILLS_SRC" >&2
        if [ -d "$TOOLKIT_ROOT/skills/chat/$skill" ]; then
            echo "       (Found under skills/chat/ — chat skills are installed via the Claude.ai UI, not this script.)" >&2
        fi
        exit 1
    fi

    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        echo "ERROR: $dst exists and is not a symlink. Refusing to overwrite." >&2
        exit 1
    fi

    rel="$(relpath "$TARGET_DIR" "$src")"
    ln -sfn "$rel" "$dst"
    echo "linked: $dst -> $rel"
done

echo
echo "Done. Claude Code will pick up skills from .claude/skills/ at next session start."
