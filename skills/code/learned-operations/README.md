# learned-operations

A cross-project memory of repeatable shell operations. Stops Claude from regenerating known command sequences from scratch — and stops it from silently reusing things that were never proven to work.

## When to install

Install at the **user-home** scope, not per-project:

```
~/.claude/skills/learned-operations/
```

Cross-project by design — anything under `~/.claude/skills/` is loaded into every project. The skill's value compounds across sessions: the operation you crystallised yesterday on project A is available today on project B. Per-project install neutralises that.

## What it actually catches

- A 6-command AWS Lambda redeploy you ran three weeks ago is reused as a single trusted script invocation — no regeneration, no per-step confirmation.
- A diagnostic that exited 0 but didn't actually fix anything stays in `# state: draft` until side-effects are checked, so the next session doesn't trust it blindly.
- An attempt to write a near-duplicate of an existing script forces the parametrise-vs-clone test — preventing the slow accumulation of slightly different scripts that all do the same thing wrong.
- A `trusted` script edited in place is rejected by the skill's own discipline: any edit declasses it to `draft` and requires re-verification.

## When this skill might add less value

- One-off, throwaway operations that will never run again.
- Projects with an existing runbook / `Makefile` / Taskfile already covering the relevant operations.
- Sessions where you don't have write access to `~/.claude/skills/learned-operations/scripts/` (rare; happens on locked-down shared environments).

## Installation

Two pieces. Both are needed: the skill folder gives Claude the logic, the `CLAUDE.md` line gives it the trigger that fires on every multi-step operation.

### 1. Skill folder (user-home)

```bash
unzip learned-operations.skill -d ~/.claude/skills/
```

This creates `~/.claude/skills/learned-operations/` with `SKILL.md` and an empty `scripts/` subfolder. Crystallised scripts will land in `scripts/` as the skill is used.

### 2. Trigger line in `~/.claude/CLAUDE.md`

Append the following block to your global `~/.claude/CLAUDE.md` (do not replace the file):

```markdown
## Learned operations

Before performing any multi-step operation (a sequence of shell commands, a build, a deploy, an infra/AWS action, a repeatable diagnostic), consult the `learned-operations` skill first: reuse an existing crystallised script if one matches, and crystallise genuinely new operations after verifying they worked. Do this even when I do not use the words "script" or "skill".
```

Why both: `CLAUDE.md` loads every session (the guaranteed trigger). The skill loads only when relevant (the heavy logic, paid for only when used). The trigger line makes "check before every operation" reliable; the skill keeps it cheap.

### Verify

Start a Claude Code session and ask it to do a small repeatable operation. It should: list `~/.claude/skills/learned-operations/scripts/`, find nothing, do the operation, then offer to crystallise it as a `draft` script with the four-line state header.

## Composability

Independent of every other skill in this repo. It does not produce code (that's `incremental-implementation-workflow`), diagnose cloud problems (that's `aws-deploy-and-iam-diagnostics`), or refine specs (that's `three-amigos`); it remembers operations across sessions so the cost of repeating them drops to one script invocation.

Pairs naturally with `aws-deploy-and-iam-diagnostics` and `jvm-fatjar-deploy-verification`: the diagnostic patterns in those skills frequently turn into 3–5 step recipes worth crystallising.
