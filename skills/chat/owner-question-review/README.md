# owner-question-review

Triages an unresolved requirement question against the sources the project itself designates, and only escalates to the owner what the agent does not own. Output is a disposition: RESOLVED, OWNER REQUIRED, or UNVERIFIED.

## When to install

This is a Claude.ai chat skill. Install it when you refine or review specs in chat and keep hitting questions that someone, somewhere in the project, has probably already answered (a schema, an ADR, an approved protocol). It also works as the triage step behind the handoff in `three-amigos` and in `incremental-implementation-workflow` §13.

## What it actually catches

- A question that gets sent to the owner although an approved source already decides it. The skill requires citing the specific passage and returning RESOLVED instead of interrupting.
- Two sources of the same rank that contradict each other. The skill returns OWNER REQUIRED with bounded choices and selection criteria, not an open "what do you think".
- A source that is referenced but cannot be read in the chat. The skill returns UNVERIFIED and does not guess.
- Invented precedence rules. The skill reads sources in the order the *project* declares, never in a universal order.

## When this skill might add less value

- Straightforward implementation questions with no behavioral choice behind them.
- Projects with no designated sources of truth to consult. There the skill degrades to "ask the owner", which you could do directly.
- Questions that are already answered in the current conversation.

## Installation

Upload via the Claude.ai UI (Settings → Customize → Skills → + Create skill) using `packaged/owner-question-review.skill`. Step-by-step and plan support are in [INSTALL.md](../../../INSTALL.md) (Pattern 0).

## Composability

Independent of the Claude Code skills, but its output is compatible with the eight-section clarification brief used by `three-amigos` and `incremental-implementation-workflow`. Recommendations it produces are proposals and never override the spec owner.
