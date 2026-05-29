# three-amigos

A refinement skill for chat sessions where the user is shaping a draft user story or `CLAUDE.md` increment. Runs three role personas — Business Analyst, Tester, Technician — over the draft and either emits a refined spec ready for implementation or surfaces the ambiguity that blocks it.

## When to install

In any project where the user drafts user stories or `CLAUDE.md` increments in Claude chat before implementation begins. Pairs naturally with `incremental-implementation-workflow`, which consumes the output artifact this skill produces.

## What it actually catches

Concrete examples of refinement gaps this skill surfaces:

- Story has no actor (`As a user, I want ...`) — BA flags and asks which production-identifiable role applies.
- The `so that` clause restates the `I want` — BA flags as unfalsifiable value.
- A Gherkin scenario has a `Then` that any no-op implementation would satisfy — Tester flags as dead coverage and tightens the oracle.
- An edge case (empty input, duplicate, concurrent action) is not covered — Tester appends a scenario.
- The story depends on a service or library not in the dependency graph — Technician flags as a missing prereq.
- The spec implies migrations, backfill, or idempotency the user has not priced in — Technician surfaces as out-of-scope or as an explicit additional increment.

## When this skill might add less value

- The spec was already refined in a real human Three Amigos session.
- Pure implementation tasks against a frozen, signed-off spec.
- One-off throwaway scripts where refinement cost exceeds implementation cost.

## Installation

This is a Claude.ai chat skill. Install it via the Claude.ai UI:

1. Open Claude.ai (web or desktop) → **Settings → Customize → Skills**.
2. Click **+ Create skill** and upload `three-amigos.skill` from this repo's `packaged/` directory.
3. After upload, toggle the skill on.

The `.skill` archive contains the `three-amigos/` folder at its root with `SKILL.md` and `README.md` inside — that's the exact shape Claude.ai expects.

Available on Free, Pro, and Max plans; on Team and Enterprise the org admin enables Skills first and then individual members can upload their own under **Settings → Customize → Skills**.

If you instead want to use this in Claude Code as a loose-style chat skill (uncommon but supported), drop the folder into `.claude/skills/`:

```bash
unzip three-amigos.skill -d .claude/skills/
```

## Composability

Upstream of `incremental-implementation-workflow`. The round-table artifact (refined value clause, Gherkin scenarios, open questions, out of scope) is exactly the input shape that skill expects, so a refined story flows straight into implementation without translation.

This skill does not replace stakeholder validation. It interrogates the draft against three role lenses; it does not confirm that real-world stakeholders agree with the refined spec.
