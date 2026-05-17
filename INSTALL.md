# Installation

Most of the time you want **one skill**, not the whole repo. Start here.

## A note on git submodules

`git submodule` cannot mount a subdirectory of a repository — a submodule is
always a *whole* repo at one path. So there is no way to "submodule just
`skills/incremental-implementation-workflow`" while every skill lives in this
one repo. What you can do:

- **Copy** a single skill folder in (Pattern 1) — simplest, no git link.
- **Upload** a single `.skill` package (Pattern 2) — simplest for the Claude UI.
- **Submodule the whole repo + `sparse-checkout`** so only the skill you want
  is materialized on disk (Pattern 3) — if you want `git pull` updates.

Claude Code loads skills only as **direct children of `.claude/skills/`**
(`.claude/skills/<skill>/SKILL.md`). A skill nested any deeper is not loaded.
That is why the submodule patterns still need a symlink.

---

## Pattern 1 — copy a single skill (recommended for one skill)

No git relationship, nothing to maintain. You re-copy when you want an update.

```bash
# From a clone or download of skills-dungeon, in the consuming project root:
cp -r /path/to/skills-dungeon/skills/incremental-implementation-workflow \
  .claude/skills/incremental-implementation-workflow
```

Or pull just that folder straight from GitHub without a full clone:

```bash
git clone --filter=blob:none --no-checkout \
  https://github.com/<owner>/skills-dungeon /tmp/skills-dungeon
cd /tmp/skills-dungeon
git sparse-checkout set --no-cone skills/incremental-implementation-workflow
git checkout main
cp -r skills/incremental-implementation-workflow \
  /path/to/your/project/.claude/skills/
```

Trade-off: no automatic update path.

## Pattern 2 — single `.skill` upload (no git relationship)

Best for one-off use through the Claude Code skill installation flow.

```bash
curl -fsSL https://raw.githubusercontent.com/<owner>/skills-dungeon/main/packaged/incremental-implementation-workflow.skill \
  -o /tmp/incremental-implementation-workflow.skill

# Upload via the Claude Code UI, or unzip directly:
unzip /tmp/incremental-implementation-workflow.skill -d .claude/skills/
```

Trade-off: no version pinning, no automatic update path.

## Pattern 3 — submodule + sparse-checkout (one skill, with updates)

Use this when you want `git pull` updates for a single skill. The submodule is
still the whole repo, but `sparse-checkout` keeps only the one skill folder on
disk; a symlink then exposes it where Claude Code expects it.

```bash
# In the consuming project root
git submodule add https://github.com/<owner>/skills-dungeon .claude/external/skills-dungeon

# Materialize only the skill you want
git -C .claude/external/skills-dungeon sparse-checkout set --cone \
  skills/incremental-implementation-workflow scripts

# Expose it as a direct child of .claude/skills/
.claude/external/skills-dungeon/scripts/install.sh incremental-implementation-workflow
```

`install.sh` creates:

```
.claude/skills/incremental-implementation-workflow -> ../external/skills-dungeon/skills/incremental-implementation-workflow
```

To update later:

```bash
cd .claude/external/skills-dungeon && git pull
# The symlink already points at the updated content; nothing else to do.
```

Pin to a specific commit with normal submodule pinning
(`git -C .claude/external/skills-dungeon checkout <sha>`, then `git add` the
gitlink in the parent repo).

## Pattern 4 — submodule + selective symlink (several skills, with updates)

Same as Pattern 3 but for adopting **multiple** skills with one centralized,
updatable copy. Skip `sparse-checkout` (or list every skill you want) and pass
all of them to `install.sh`:

```bash
git submodule add https://github.com/<owner>/skills-dungeon .claude/external/skills-dungeon

.claude/external/skills-dungeon/scripts/install.sh \
  incremental-implementation-workflow \
  aws-deploy-and-iam-diagnostics
```

To vendor the content inside your own repo instead of using a submodule
(no `git submodule update --init` for collaborators), use `git subtree`:

```bash
git subtree add --prefix=.claude/external/skills-dungeon \
  https://github.com/<owner>/skills-dungeon main --squash
.claude/external/skills-dungeon/scripts/install.sh incremental-implementation-workflow
```

## Decision matrix

| Need | Pattern |
|---|---|
| One skill, simplest possible, no updates | 1 (copy) |
| One skill, one-off via the Claude Code UI | 2 (.skill upload) |
| One skill, want `git pull` updates | 3 (submodule + sparse-checkout) |
| Several skills, centralized updatable copy | 4 (submodule + symlink) |
