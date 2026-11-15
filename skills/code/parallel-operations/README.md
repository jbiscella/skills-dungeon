# parallel-operations

Coordinates several agents and pull requests on one repository and one machine: how many agents the hardware sustains, isolated local test environments, the full local regression suite before every pull request, and never merging into a red main.

## When to install

Install it in Claude Code projects where more than one agent works at once, or where one agent opens several pull requests in a row. It loads before parallel work starts and before every merge.

## What it actually catches

- A green pull request merged on top of a red main, which buries the first regression under later changes.
- Test layers left to CI, or to nightly runs only, while the machine could have run them. A regression then reaches main before any test sees it.
- More agents than the machine sustains, which turns load limits into skipped tests.
- Agents sharing one test server, port or data set, so one agent's test changes another's result.
- Operational rules (what runs where, merge cadence, retries) changed by the agent instead of the owner.
- A change merged while a failure that appeared only with it is still unexplained.

## When this skill might add less value

- A single agent with one pull request at a time, on a project whose pull-request CI already runs every test layer. The red-main rule still applies.
- Repositories protected by a merge queue that tests each change on top of the current main and refuses merges while it is red.

## Installation

In a Claude Code project:

```bash
unzip parallel-operations.skill -d .claude/skills/
```

Use `~/.claude/skills/` for global use. Other install patterns are in [INSTALL.md](../../../INSTALL.md).

## Composability

Works with `incremental-implementation-workflow`, whose definition of done covers one increment; this skill covers how increments land together. `independent-verification` reviews an increment's evidence; this skill decides whether it may merge.
