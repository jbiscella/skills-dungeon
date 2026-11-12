# scenario-integrity

Audits approved BDD scenarios and their step definitions for two failures: behavior changed without authorization, and assertions too weak to fail when they should. A green test is not treated as proof of an effective oracle.

## When to install

Install it in projects where Claude Code edits feature files or step definitions, or where you accept completed behavioral increments. It needs an approved baseline to diff against; without one it has nothing to protect.

## What it actually catches

- A scenario edited to match the implementation instead of the other way round. Changes to approved behavior need the designated owner; the skill refuses to treat "make it green" as a reason.
- Feature text unchanged but the step assertion ignores the expected value. A hash of the scenario would not notice; the Then-to-assertion mapping does.
- A negative Then ("nothing is sent") that a no-op, an inactive subscription or a local filter would satisfy without the required action ever being attempted.
- Oracles whose sensitivity was only reasoned about. The skill asks for a safe targeted negative control where justified and reports the rest as UNVERIFIED.

## When this skill might add less value

- No approved baseline exists (new project, scenarios still in flux).
- The project already runs mutation testing or an equivalent independent check on its oracles. The skill explicitly does not require blanket mutation testing.
- Pure refactors that touch neither scenarios nor step definitions.

## Installation

In a Claude Code project:

```bash
unzip scenario-integrity.skill -d .claude/skills/
```

Use `~/.claude/skills/` for global use. Other install patterns are in [INSTALL.md](../../../INSTALL.md).

## Composability

Referenced by `incremental-implementation-workflow` §13, which says what to do when it is installed. It audits scenarios and mappings; it does not decide behavior, so approved changes still go through the owner-defined process. Pair with `independent-verification` at increment boundaries.
