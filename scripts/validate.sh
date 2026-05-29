#!/usr/bin/env bash
#
# validate.sh — validate every skills/<surface>/<name>/SKILL.md and the
# surrounding repo invariants (packaged archives, install script source,
# documentation links).
#
# Skills live under a surface subfolder: skills/code/ for Claude Code
# skills, skills/chat/ for Claude.ai chat skills. The validator walks both.
#
# Per-skill checks (delegated to scripts/check_skill.py, which uses a real
# YAML parser):
# 1. SKILL.md exists in each skill folder
# 2. Frontmatter parses as YAML and contains non-empty 'name' and 'description'
# 3. Description does not contain a literal colon ':' in YAML-ambiguous position
# 4. Description does not contain angle brackets '<' or '>'
# 5. Body contains a '## Minimum protocol' heading near the top — every
#    SKILL.md in this repo carries the same minimum operational contract,
#    so absence of the heading is treated as drift, not style.
#
# Repo-wide checks:
# 5. Every skill folder has a matching packaged/<name>.skill, and every
#    packaged/<name>.skill has a matching skill folder (no orphans).
# 6. No packaged/<name>.skill is older than any file inside its source
#    skill folder (stale package detection).
# 7. install.sh's SKILLS_SRC path resolves to skills/code/.
# 8. Every relative markdown link in README.md, INSTALL.md, and per-skill
#    READMEs points to an existing file or directory in the repo.
#
# Usage:
#   scripts/validate.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_SRC="$TOOLKIT_ROOT/skills"
PACKAGED_DIR="$TOOLKIT_ROOT/packaged"

errors=0
warnings=0

# ----- Per-skill frontmatter validation ---------------------------------------

# Collect skill names while we walk, for the cross-check against packaged/.
declare -a known_skills=()

for surface_dir in "$SKILLS_SRC"/*/; do
    surface="$(basename "$surface_dir")"
    for d in "$surface_dir"*/; do
        [ -d "$d" ] || continue
        skill="$(basename "$d")"
        skill_md="$d/SKILL.md"
        known_skills+=("$skill")

        echo "Validating: $surface/$skill"

        if [ ! -f "$skill_md" ]; then
            echo "  ERROR: SKILL.md missing"
            errors=$((errors + 1))
            continue
        fi

        # Delegate frontmatter parsing to scripts/check_skill.py so we use a
        # real YAML parser. The script prints WARN/ERROR lines; we tally them.
        out="$(python3 "$SCRIPT_DIR/check_skill.py" --check-body "$skill_md" 2>&1)" || true
        rc=$?
        if [ -n "$out" ]; then
            echo "$out" | sed 's/^/  /'
            warnings=$((warnings + $(echo "$out" | grep -c '^WARN:' || true)))
        fi
        if [ "$rc" -eq 2 ]; then
            errors=$((errors + 1))
            continue
        fi
        if [ "$rc" -ne 0 ]; then
            errors=$((errors + $(echo "$out" | grep -c '^ERROR:' || true)))
            continue
        fi

        echo "  OK"
    done
done

# ----- Package correspondence -------------------------------------------------

echo
echo "Checking packaged/ correspondence..."

for skill in "${known_skills[@]}"; do
    pkg="$PACKAGED_DIR/$skill.skill"
    if [ ! -f "$pkg" ]; then
        echo "  ERROR: source skill '$skill' has no matching packaged/$skill.skill"
        errors=$((errors + 1))
    fi
done

if [ -d "$PACKAGED_DIR" ]; then
    for pkg in "$PACKAGED_DIR"/*.skill; do
        [ -f "$pkg" ] || continue
        name="$(basename "$pkg" .skill)"
        found=0
        for s in "${known_skills[@]}"; do
            if [ "$s" = "$name" ]; then
                found=1
                break
            fi
        done
        if [ "$found" -eq 0 ]; then
            echo "  ERROR: orphan package $pkg (no skill folder named '$name')"
            errors=$((errors + 1))
        fi
    done
fi

# ----- Package staleness ------------------------------------------------------

echo
echo "Checking packaged/ freshness..."

# A package is stale if any file inside its source folder is newer than the
# package itself. find ... -newer prints offending files; we just need a flag.
for skill in "${known_skills[@]}"; do
    pkg="$PACKAGED_DIR/$skill.skill"
    [ -f "$pkg" ] || continue

    src=""
    for surface_dir in "$SKILLS_SRC"/*/; do
        if [ -d "$surface_dir$skill" ]; then
            src="$surface_dir$skill"
            break
        fi
    done
    [ -n "$src" ] || continue

    newer="$(find "$src" -type f -newer "$pkg" -print -quit 2>/dev/null || true)"
    if [ -n "$newer" ]; then
        echo "  WARN: packaged/$skill.skill is older than source ($newer); run scripts/package.sh $skill"
        warnings=$((warnings + 1))
    fi
done

# ----- install.sh source path -------------------------------------------------

echo
echo "Checking scripts/install.sh source path..."

install_src="$(grep -E '^SKILLS_SRC=' "$SCRIPT_DIR/install.sh" | head -n 1 | sed 's/^SKILLS_SRC=//; s/"//g')"
install_src_resolved="${install_src/\$TOOLKIT_ROOT/$TOOLKIT_ROOT}"

if [ ! -d "$install_src_resolved" ]; then
    echo "  ERROR: install.sh SKILLS_SRC resolves to '$install_src_resolved' which does not exist"
    errors=$((errors + 1))
else
    echo "  OK ($install_src_resolved)"
fi

# ----- Markdown link resolution -----------------------------------------------

echo
echo "Checking relative markdown links..."

# Files we audit. Per-skill READMEs are listed dynamically.
declare -a doc_files=("$TOOLKIT_ROOT/README.md" "$TOOLKIT_ROOT/INSTALL.md" "$TOOLKIT_ROOT/CHANGELOG.md")
while IFS= read -r f; do
    doc_files+=("$f")
done < <(find "$SKILLS_SRC" -name README.md -type f)

# Extract [text](target) where target is not http(s):, mailto:, or #anchor only.
link_re='\[[^]]*\]\(([^)]+)\)'

for f in "${doc_files[@]}"; do
    [ -f "$f" ] || continue
    f_dir="$(dirname "$f")"
    # awk is more reliable than bash's regex for repeated matches per line.
    while IFS= read -r target; do
        # Trim a trailing #anchor or ?query fragment.
        path="${target%%#*}"
        path="${path%%\?*}"
        [ -n "$path" ] || continue
        # Skip absolute URLs and protocol schemes.
        case "$path" in
            http://*|https://*|mailto:*|tel:*|data:*) continue ;;
        esac
        # Resolve relative to the doc.
        if [ "${path:0:1}" = "/" ]; then
            resolved="$TOOLKIT_ROOT$path"
        else
            resolved="$f_dir/$path"
        fi
        # Strip /./ and /trailing-slash for the existence check.
        resolved="${resolved%/}"
        if [ ! -e "$resolved" ]; then
            echo "  ERROR: ${f#$TOOLKIT_ROOT/} → '$target' does not resolve ($resolved)"
            errors=$((errors + 1))
        fi
    done < <(grep -oE "$link_re" "$f" | sed -E 's/.*\(([^)]+)\)/\1/')
done

# ----- Summary ----------------------------------------------------------------

echo
if [ "$errors" -gt 0 ]; then
    echo "Validation FAILED with $errors error(s) and $warnings warning(s)."
    exit 1
fi

if [ "$warnings" -gt 0 ]; then
    echo "Validation OK with $warnings warning(s)."
else
    echo "All checks passed."
fi
