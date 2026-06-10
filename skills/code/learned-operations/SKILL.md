---
name: learned-operations
description: Self-teaching operation memory. Whenever you are about to perform a multi-step operation (a sequence of shell commands, a build, a deploy, an AWS/infra action, a repeatable diagnostic), use this skill FIRST. It tells you to check whether the operation was already crystallised into a reusable script, reuse it instead of regenerating the command sequence, and — for genuinely new operations — crystallise them after verifying they worked. Use it even when the user does not say "script" or "skill" — any repeatable multi-command operation qualifies.
---

# Learned Operations

A self-teaching memory for repeatable operations. The point is to stop regenerating known command sequences from scratch (wastes tokens) and to stop silently reusing things that were never proven to work (causes regression).

Scripts live in this skill's own `scripts/` directory: `~/.claude/skills/learned-operations/scripts/`. They are bash. Each script carries its own state in a header comment — there is no separate index file, and the script is the single source of truth for its own state.

## Minimum protocol

**On load.** Before any multi-step operation, list `~/.claude/skills/learned-operations/scripts/` and read each candidate's `# operation:` header. Match semantically, not by filename.

**Stop and surface to the user on.** Listed script unreadable or corrupted (treat as absent, tell the user, do not silently recreate). A new operation that needs a near-duplicate of an existing script — apply the parametrise-vs-clone table before writing anything. A `trusted` script whose context no longer matches — clone to a draft, do not edit in place.

**Expected output shape.** Match in `trusted` state — invoke directly, do not re-read the body. Match in `verified` — re-read, confirm fit, invoke. Match in `draft` — re-read, run, re-verify side-effects before relying. No match — perform manually this turn, then crystallise a new script with the four-line state header and `# state: draft`.

## State header

Every script begins with exactly these three header lines:

```
#!/usr/bin/env bash
# operation: <one line: what operation this performs>
# state: draft | verified | trusted
# expectation: <the side-effect that proves it worked>
```

State meanings:

| state | meaning | who sets it |
|---|---|---|
| draft | just crystallised, not yet proven | you, at creation |
| verified | side-effects were asserted against the expectation and matched | you, after checking |
| trusted | the user approved skipping the body re-read | the user only |

## Before any multi-step operation

1. List `~/.claude/skills/learned-operations/scripts/`.
2. Read the `# operation:` header of candidates to find a semantic match for the request. Do not match on filename alone.
3. Decide:

| Situation | Action |
|---|---|
| Match, `# state: trusted` | Invoke directly. Do NOT re-read the body. |
| Match, `# state: verified` | Re-read the body, confirm it fits this context, then invoke. |
| Match, `# state: draft` | Re-read body, run it, then re-verify side-effects before relying on the result. |
| Listed file unreadable/broken | Treat as absent. Tell the user. Do not silently recreate. |
| No match | Perform the operation manually this turn, then crystallise it (below). |

## Crystallising a new operation

After running a brand-new operation manually and confirming it worked:

1. Save the exact command sequence as a bash script in `scripts/`, with the four header lines above and `# state: draft`.
2. Put in the script only what the operation actually needed. Do NOT add flags, logging, error handling, or options that were not used. The script reproduces what was just done — nothing more.

## Verification (draft -> verified)

Verification is an external judgement you make AFTER execution. It is NOT code inside the script.

- Judge by inspecting real **side-effects** (file created/modified, record present, resource in expected state), never by exit code alone — exit 0 is necessary, never sufficient.
- Check the actual world against the `# expectation:` line.
- Side-effects match -> rewrite the header to `# state: verified`.
- They do not -> leave `# state: draft` and report the mismatch.

## Promotion (verified -> trusted)

Only the user promotes to `trusted`. Never self-promote. `trusted` is what authorises skipping the body re-read, so it requires a human decision. When the user approves, rewrite the header to `# state: trusted`.

## Parametrise vs duplicate

Before creating a near-duplicate of an existing script, apply this test against the closest match:

| Condition | Action |
|---|---|
| Only a **value** differs (region, name, path) AND state is draft/verified | Add an argument to the existing script. |
| Only a value differs AND state is `trusted` | Clone to a new draft, parametrise the clone, leave the original untouched. |
| The **command flow** differs (different/reordered steps) | New script. Do not parametrise. |
| The **expected side-effect** differs | New script. Do not parametrise. |
| Supporting the new case needs an `if`/`case` that branches behaviour | New script. Do not parametrise. |

## Immutability and declassing

- A `trusted` script is immutable: never edit it in place. Need a variant? Clone to a new draft first.
- Any edit to a draft/verified script — including adding an argument — rewrites its header to `# state: draft` and requires re-verification. A changed script has not been proven in its new form.
