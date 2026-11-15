---
name: parallel-operations
description: Run every locally runnable test layer, size agents and work in flight to the hardware and the review queue, isolate container test environments within 70% of memory, and never merge into a red main. Use before starting agents or a new change, before running a test suite or opening a pull request, and before every merge or merge instruction, also with a single agent.
---

# Parallel Operations

Parallel work is only faster while every change still lands on a green main after the full local regression suite, and while work in flight stays small enough not to queue. Speed never buys an exception.

## Minimum protocol

**On load.** Read the machine (cores, memory, current load), the project's recorded load limit, its test layers and how each starts its services, the latest result of every job that runs on main, on a schedule or nightly, and every open pull request with its agent, age and what it waits on.
**Stop on.** A red, unexplained or still-running job on main; a change with a failure that appeared only with it; a test layer that could run locally but was not run; more agents, memory or open pull requests than the budgets below; no recorded load limit; any change to how or where tests run that the owner has not approved.
**Expected output shape.** Before parallel work: cores, memory and load measured | agents allowed and why | test environment per agent, or shared and why | memory budget and the room left in it | open pull requests against their cap. Before a merge: every main, scheduled and nightly job's latest result (run id) | local layers run on the exact commit, with results | open failures and who claimed them | MERGE or HOLD with the reason.

## 1. Operations are the owner's decisions

The owner sets the operational rules: which layers run where, how many agents run, work-in-flight caps, container limits, merge cadence, retry policy and CI layout. Apply the rules below and any the project records; applying a recorded rule never needs the owner. To add, change or relax one, even to save time or to cool the machine, propose it with facts and wait for the owner. While waiting, keep applying the current rules and continue unblocked work. Batch proposals into one message. Record each approved rule where every later session loads it.

## 2. Size agents and work in flight

- Budget from measurement, not hope: cores, memory and the load an agent's heaviest step produces (a full build plus the integration suite).
- Run at most as many agents as the machine sustains with every one in its heaviest step at once, under the project's recorded load limit. When the heaviest steps cannot overlap, take turns through a shared lock instead of adding agents.
- Performance gates and timing-sensitive layers run alone under the shared lock.
- A heat or load limit pauses work and resumes it. It never skips a test layer.
- Open pull requests are capped too. Start no new change while more than N (owner-set; default: the agent count) are waiting on CI, review or the owner. Finish, fix or close the oldest first. More agents do not help while the review and CI queue is the bottleneck.

## 3. Isolate test environments

- Each agent works in its own git worktree and build directory, and runs its test services (databases, servers, brokers) as its own instance, with its own ports, names and data: a Docker Compose project per agent (`docker compose -p agent-1`), or per-run containers where the project already uses them. One shared deployment is enough when it serves every agent's tests and nothing in it can conflict: no shared state, ports or names. Tear an instance down when its run ends (`docker compose -p agent-1 down -v`).
- All containers together stay within one total budget of 70% of the machine's memory. The other 30% is for everything outside containers, builds and links included.
- The budget decides whether a new instance may start. Before an agent starts one, add up what every running instance needs at its peak (its configured limit, or its peak measured on an earlier run, never only what it uses now) and what the new one needs at its peak. Start it only if the total stays within the budget. Otherwise wait for a running instance to finish, or share one where nothing conflicts. Never start it anyway, and never raise the budget alone.
- A test target that must stay unreachable keeps its port: bind port 0 and hold the socket for the test's lifetime, or pass the listener to the server. Never free a port and expect it to stay free.

## 4. Test locally what can be tested locally

- Before every pull request, run on the exact commit every test layer the project runs on each change and that this machine can run (unit, integration, end-to-end, performance gates, the build and lint of every target, and any others), including those that so far run only on main. Run them cheapest first and stop at the first failure. The pull request records each layer's command and result.
- Periodic suites, those the project runs on a schedule (nightly or weekly: long chaos, soak, fuzzing), run remotely on that schedule, not before each pull request.
- CI then repeats the per-change layers. It does not replace them. Only layers the machine cannot run (other operating systems, devices, unavailable browsers) are left to CI, and those are listed in the pull request.
- Where another skill says not to rerun expensive checks without new information, this one wins: a new commit is new information.

## 5. Never merge into a red main

- Before every merge, read the latest result of every job that runs on main, on a schedule or nightly, wherever it last ran. Wait for a run in progress.
- While any job there is red, the only merge allowed is the fix for that red. A green pull request is not enough. A merge request is not a rule change, even from the owner: the owner changes the rule explicitly, and the change is recorded.
- The first agent to see a red claims it in its report, and reverts the change that caused it when the fix takes longer than a revert. Other agents continue local work but do not merge.
- Merge one pull request at a time, rebased on current main and tested on that commit.
- A failure that appeared only with a change blocks that change until it is reproduced and fixed, or shown independent of it with evidence. "Not significant" is not green, and a rerun never clears it.
- After a merge, watch main's run on it, and report a failure before anything else merges.

## 6. Flakes

- Root-cause and fix each flake. A rerun is only a stopgap, logged with its tracking issue, and never clears a failure that first appeared with the change under test.

## 7. Report

At each merge, and when asked for status, give: every main, scheduled and nightly job's latest result, the open pull requests with their agent, age and what each waits on (CI, review or the owner), the local layers run and their results, and every open failure with who claimed it. Give the time from the clock, never an estimate.
