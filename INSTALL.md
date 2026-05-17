# Installation patterns

Four ways to consume skills-dungeon in another project. Listed in order of recommendation.

## Pattern 1 — git submodule + selective symlink (recommended)

Best for projects that want centralized updates and selective skill adoption per project.

```bash
# In the consuming project root
git submodule add https://github.com/<owner>/skills-dungeon .claude/external/skills-dungeon

# Install just the skills you want
.claude/external/skills-dungeon/scripts/install.sh \
  incremental-implementation-workflow \
  aws-deploy-and-iam-diagnostics
```

The script creates symlinks:

```
.claude/skills/incremental-implementation-workflow -> ../external/skills-dungeon/skills/incremental-implementation-workflow
.claude/skills/aws-deploy-and-iam-diagnostics      -> ../external/skills-dungeon/skills/aws-deploy-and-iam-diagnostics
```

The symlink is required because Claude Code loads skills only as direct children of `.claude/skills/`. A nested submodule path (`.claude/skills/external/...`) is not loaded.

To update later:

```bash
cd .claude/external/skills-dungeon
git pull
# Symlinks already point at the updated content; no further action needed
```

To pin to a specific commit, use the usual submodule pinning (`git -C .claude/external/skills-dungeon checkout <sha>` then `git add` the gitlink in the parent repo).

## Pattern 2 — git subtree

Best for projects that prefer to vendor the skills-dungeon content inside their own repo (no submodule indirection, no separate clone step for collaborators).

```bash
git subtree add --prefix=.claude/external/skills-dungeon \
  https://github.com/<owner>/skills-dungeon main --squash

# Same symlink step as Pattern 1
.claude/external/skills-dungeon/scripts/install.sh \
  incremental-implementation-workflow
```

To update later:

```bash
git subtree pull --prefix=.claude/external/skills-dungeon \
  https://github.com/<owner>/skills-dungeon main --squash
```

Trade-off: easier for collaborators (no `git submodule update --init`), but contributing changes back to upstream is more involved.

## Pattern 3 — sparse checkout (clone only what you need)

Best for projects on bandwidth- or storage-constrained CI environments where the full skills-dungeon is overkill.

```bash
git clone --filter=blob:none --no-checkout \
  https://github.com/<owner>/skills-dungeon .claude/external/skills-dungeon

cd .claude/external/skills-dungeon
git sparse-checkout init --cone
git sparse-checkout set skills/incremental-implementation-workflow scripts
git checkout main

# Then symlink
./scripts/install.sh incremental-implementation-workflow
```

Trade-off: more setup complexity, less common in team workflows.

## Pattern 4 — direct .skill upload (no git relationship)

Best for one-off use where you don't want a long-term link to this repo.

Download a specific `.skill` file from `packaged/` (e.g. via `curl` against the raw GitHub URL, or by cloning and copying), then load it into Claude Code through its skill installation flow:

```bash
curl -fsSL https://raw.githubusercontent.com/<owner>/skills-dungeon/main/packaged/incremental-implementation-workflow.skill \
  -o /tmp/incremental-implementation-workflow.skill

# Then upload via Claude Code UI, or unzip into .claude/skills/ directly
unzip /tmp/incremental-implementation-workflow.skill -d .claude/skills/
```

Trade-off: no version pinning, no automatic update path. You re-download manually when you want a newer version.

## Decision matrix

| Need | Pattern |
|---|---|
| Centralized updates across projects, selective skills per project | 1 (submodule) |
| Collaborators should not need extra git steps | 2 (subtree) |
| Minimize clone size for CI | 3 (sparse) |
| One-time use, no long-term link | 4 (direct .skill) |
