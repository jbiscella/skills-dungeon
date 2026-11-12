# independent-verification

Reviews a finished agent-written increment against fresh evidence (approved scenarios, the diff, real test output, operational invariants) instead of the implementer's own summary. It reports VERIFIED, FAILED or UNVERIFIED and says what it could not check.

## When to install

Install it in Claude Code projects where an agent writes increments and you want a review step at meaningful boundaries or on high-risk changes. It is a verifier, not a second decision maker: its suggestions are not requirements.

## What it actually catches

- "Tests pass" claims backed only by a description or a screenshot. Without actual execution output the result is UNVERIFIED, not success.
- Then clauses that map to assertions a no-op or a negative case would satisfy.
- Reviewer suggestions drifting into scope. Findings are classified (proven in-scope defect, unresolved owner choice, out-of-scope suggestion, unverified hypothesis) and only proven ones are acted on.
- Silent certification when the reviewer cannot run the checks. The skill requires disclosing that instead.

## When this skill might add less value

- Small, low-risk changes where a full review costs more than the change.
- Projects that already have an equivalent independent review or CI gate on the same evidence.
- Situations where no evidence is available; the skill can only answer UNVERIFIED there.

## Installation

In a Claude Code project:

```bash
unzip independent-verification.skill -d .claude/skills/
```

Use `~/.claude/skills/` for global use. Other install patterns are in [INSTALL.md](../../../INSTALL.md).

## Composability

Referenced by `incremental-implementation-workflow` §13 as the increment-boundary check. Works with `scenario-integrity`, which covers the scenario and oracle side. A second model can diversify the review, but that does not by itself prove independence or correctness.
