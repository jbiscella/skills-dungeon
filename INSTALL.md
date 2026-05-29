# Installation

Most of the time you want **one skill**, not the whole repo. The install path depends on the surface:

- **Claude.ai chat skills** (`skills/chat/`) — uploaded via the Claude.ai UI. There's only one pattern; see Pattern 0.
- **Claude Code skills** (`skills/code/`) — loaded from `.claude/skills/` in a project. Four patterns below, in order of recommendation.

## A note on git submodules

`git submodule` cannot mount a subdirectory of a repository — a submodule is
always a *whole* repo at one path. So there is no way to "submodule just
`skills/code/incremental-implementation-workflow`" while every skill lives in this
one repo. What you can do:

- **Upload** a single `.skill` package (Pattern 0 for chat, Pattern 2 for Code).
- **Copy** a single skill folder in (Pattern 1) — simplest for Code, no git link.
- **Submodule the whole repo + `sparse-checkout`** so only the skill you want
  is materialized on disk (Pattern 3) — if you want `git pull` updates.

Claude Code loads skills only as **direct children of `.claude/skills/`**
(`.claude/skills/<skill>/SKILL.md`). A skill nested any deeper is not loaded.
That is why the Code submodule patterns still need a symlink. (Loader
behavior verified as of 2026-05-29 — Claude Code is under active
development; if you see a skill in a nested path being loaded, re-check
the docs before relying on it.)

---

## Pattern 0 — Claude.ai chat skill upload (the only chat pattern)

Claude.ai chat skills live in `skills/chat/` and are installed exclusively
through the Claude.ai UI. There is no filesystem loader — the runtime is the
hosted Claude.ai service.

Steps (verified as of 2026-05-29; the Claude.ai Skills UI is recent and the
menu path may shift — when in doubt, search the
[Claude help center](https://support.claude.com/) for "skills"):

1. Open Claude.ai (web or desktop) → **Settings → Customize → Skills**.
2. Click **+ Create skill** and upload the corresponding `.skill` from
   `packaged/` — e.g. `packaged/three-amigos.skill`.
3. Toggle the new skill on.

The `.skill` archive must contain the skill folder at its root
(`three-amigos/SKILL.md`), which is what `scripts/package.sh` produces by
design.

Plan support (verified as of 2026-05-29; Anthropic adjusts plan-feature
matrices periodically): Free, Pro, and Max plans can upload personal skills
directly. Team and Enterprise require the org admin to enable Skills at the
organization level first; individual members then upload their own under
**Settings → Customize → Skills**.

To update later, re-upload a newer `.skill`. The UI replaces the prior
version.

---

## Pattern 1 — copy a single Claude Code skill (recommended for one skill)

No git relationship, nothing to maintain. You re-copy when you want an update.

```bash
# From a clone or download of skills-dungeon, in the consuming project root:
cp -r /path/to/skills-dungeon/skills/code/incremental-implementation-workflow \
  .claude/skills/incremental-implementation-workflow
```

Or pull just that folder straight from GitHub without a full clone:

```bash
git clone --filter=blob:none --no-checkout \
  https://github.com/<owner>/skills-dungeon /tmp/skills-dungeon
cd /tmp/skills-dungeon
git sparse-checkout set --no-cone skills/code/incremental-implementation-workflow
git checkout main
cp -r skills/code/incremental-implementation-workflow \
  /path/to/your/project/.claude/skills/
```

Trade-off: no automatic update path.

## Pattern 2 — single `.skill` upload to Claude Code (no git relationship)

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
  skills/code/incremental-implementation-workflow scripts

# Expose it as a direct child of .claude/skills/
.claude/external/skills-dungeon/scripts/install.sh incremental-implementation-workflow
```

`install.sh` creates:

```
.claude/skills/incremental-implementation-workflow -> ../external/skills-dungeon/skills/code/incremental-implementation-workflow
```

To update later:

```bash
cd .claude/external/skills-dungeon && git pull
# The symlink already points at the updated content; nothing else to do.
```

Pin to a specific commit with normal submodule pinning
(`git -C .claude/external/skills-dungeon checkout <sha>`, then `git add` the
gitlink in the parent repo).

`install.sh` only installs Claude Code skills (from `skills/code/`). It is
not a path for chat skills — use Pattern 0 for those.

## Pattern 4 — submodule + selective symlink (several Claude Code skills, with updates)

Same as Pattern 3 but for adopting **multiple** Code skills with one
centralized, updatable copy. Skip `sparse-checkout` (or list every skill you
want) and pass all of them to `install.sh`:

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
| Claude.ai chat skill (any) | 0 (Settings → Customize → Skills) |
| One Code skill, simplest possible, no updates | 1 (copy) |
| One Code skill, one-off via the Claude Code UI | 2 (.skill upload) |
| One Code skill, want `git pull` updates | 3 (submodule + sparse-checkout) |
| Several Code skills, centralized updatable copy | 4 (submodule + symlink) |
