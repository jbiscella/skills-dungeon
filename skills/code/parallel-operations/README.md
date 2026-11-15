# parallel-operations

Coordinates agents and pull requests on one repository and one machine: how many agents the hardware sustains, how much work may be in flight, isolated local test environments within one memory budget, the full local regression suite before every pull request, and never merging into a red main.

## When to install

Install it in Claude Code projects where agents open pull requests, alone or several at once. It applies before a new change starts, before a test suite runs, and before every merge.

## What it actually catches

- A green pull request merged on top of a red main, which buries the first regression under later changes.
- A main judged green from its last run while a nightly job is red or a run is still in progress.
- Test layers left to CI, or to nightly runs only, while the machine could have run them. A regression then reaches main before any test sees it.
- More agents, or more open pull requests, than the machine and the review queue sustain, which turns load limits into skipped tests and waiting into backlog.
- A new test environment started when the instances already running leave no room for it within the memory budget.
- Agents sharing one test server, port or data set, so one agent's test changes another's result.
- Operational rules (what runs where, merge cadence, retries) changed by the agent instead of the owner, or a "merge anyway" taken as one.
- A change merged while a failure that appeared only with it is still unexplained.

## When this skill might add less value

- A single agent with one pull request at a time, on a project whose pull-request CI already runs every test layer. The red-main rule still applies.
- Repositories protected by a merge queue that tests each change on top of the current main and refuses merges while it is red.

## A mechanical backstop

A skill is guidance: an agent loads it on a description match, and a merge hours later may not reload it. Back the red-main rule with something that runs by itself: required status checks, a merge queue, or a pre-merge script or hook that reads main's jobs. Name the skill in the project's `CLAUDE.md` as the step before any merge.

## Installation

In a Claude Code project:

```bash
unzip parallel-operations.skill -d .claude/skills/
```

Use `~/.claude/skills/` for global use. Other install patterns are in [INSTALL.md](../../../INSTALL.md).

## Composability

Works with `incremental-implementation-workflow`, whose definition of done covers one increment; this skill covers how increments land together, and wins where the two conflict on rerunning checks. `independent-verification` reviews an increment's evidence; this skill decides whether it may merge.
