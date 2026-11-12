#!/usr/bin/env python3
"""Check packaged .skill contents against the skill source, not timestamps."""
from pathlib import Path
from zipfile import ZipFile, BadZipFile
import sys

root = Path(__file__).resolve().parent.parent


def excluded(relative: Path) -> bool:
    """Mirror the exclusions of scripts/package.sh so local junk never fails the check."""
    return (
        relative.name.endswith(".DS_Store")
        or "__pycache__" in relative.parts
        or "node_modules" in relative.parts
    )


skills = {
    p.name: p
    for surface in (root / "skills").iterdir() if surface.is_dir()
    for p in surface.iterdir() if p.is_dir() and (p / "SKILL.md").exists()
}
errors = []
for name, folder in sorted(skills.items()):
    package = root / "packaged" / (name + ".skill")
    if not package.exists():
        errors.append(f"missing {package.name}")
        continue
    expected = {
        f"{name}/{file.relative_to(folder).as_posix()}": file.read_bytes()
        for file in folder.rglob("*")
        if file.is_file() and not excluded(file.relative_to(folder))
    }
    try:
        with ZipFile(package) as archive:
            actual_names = {n for n in archive.namelist() if not n.endswith("/")}
            if actual_names != set(expected):
                errors.append(f"{name}: archive members differ from source")
            for item, content in expected.items():
                if item in actual_names and archive.read(item) != content:
                    errors.append(f"{name}: stale content in {item}")
    except (BadZipFile, OSError) as exc:
        errors.append(f"{name}: unreadable archive: {exc}")
orphans = {p.stem for p in (root / "packaged").glob("*.skill")} - set(skills)
if orphans:
    errors.append(f"orphan packages: {', '.join(sorted(orphans))}")
if errors:
    for error in errors:
        print("ERROR:", error)
    sys.exit(1)
print(f"Package contents match {len(skills)} source skills.")
