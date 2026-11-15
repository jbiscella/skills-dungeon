---
name: parallel-operations
description: Run every locally runnable test layer, size parallel agents to the hardware, isolate container test environments per agent within 70% of memory, and never merge into a red main. Use before starting parallel agents, before running a test suite or opening a pull request, and before every merge or merge instruction, even with a single agent.
---

# Parallel Operations

Parallel work is only faster while every change still lands on a green main after the full local regression suite. Speed never buys an exception.

## Minimum protocol

**On load.** Read the machine (cores, memory, current load), the project's test layers and how each starts its services, the main branch's latest finished CI run, and every open pull request with its agent.
**Stop on.** A red or unexplained job on main; a change with a failure that appeared only with it; a test layer that could run locally but was not run; a plan needing more agents or memory than the budget below; any change to how or where tests run that the owner has not approved.
**Expected output shape.** Before parallel work: cores, memory and load measured | agents allowed and why | test environment per agent, or shared and why | container memory cap and the room left in it. Before a merge: main status (run id, every job) | local layers run on the exact commit, with results | open failures and their owners | MERGE or HOLD with the reason.

## 1. Operations are the owner's decisions

The owner sets the operational rules: which layers run where, how many agents run, container limits, merge cadence, retry policy and CI layout. Apply the rules below and any the project records. To add, change or relax one, even to save time or to cool the machine, propose it with facts and wait for the owner. Record each approved rule where every later session loads it.

## 2. Size the agents to the hardware

- Budget from measurement, not hope: cores, memory and the load an agent's heaviest step produces (a full build plus the integration suite).
- Run at most as many agents as the machine sustains with every one in its heaviest step at once, under the project's load limit. When the heaviest steps cannot overlap, take turns through a shared lock instead of adding agents.
- A heat or load limit pauses work and resumes it. It never skips a test layer.

## 3. Isolate test environments

- Each agent runs its test services (databases, servers, brokers) as its own instance, with its own ports, names and data: a Docker Compose project per agent (`docker compose -p agent-1`), or per-run containers where the project already uses them. One shared deployment is enough when it serves every agent's tests and nothing in it can conflict: no shared state, ports or names.
- Containers together stay within 70% of the machine's memory, enforced by per-service limits or a parent cgroup, not by hope.
- The 70% budget also decides whether a new instance may start. Before an agent starts one, add the memory the running containers use now (`docker stats --no-stream`) to what the new instance needs at its peak, measured from an earlier run or set as its limit. Start it only if the total stays within 70% of the machine's memory. Otherwise wait for a running instance to finish, or share one where nothing conflicts. Never start it anyway, and never raise the budget alone.
- Never free a port and expect it to stay free for a test target. Hold the socket for the test's lifetime.

## 4. Test locally what can be tested locally

- Before every pull request, run on the exact commit every test layer the project runs on each change and that this machine can run (unit, integration, end-to-end, performance gates, the build and lint of every target, and any others), including those that so far run only on main or on a schedule. The pull request records each layer's command and result.
- Long or expensive suites the project runs only when a change needs them (chaos, soak, load) run locally when the change makes them necessary. The pull request says whether they were needed, and why.
- CI then repeats them. It does not replace them. Only layers the machine cannot run (other operating systems, devices, unavailable browsers) are left to CI, and those are listed in the pull request.
- A test the change touches but no CI job runs on pull requests must be run locally.

## 5. Never merge into a red main

- Before every merge, read main's latest finished CI run, every job including those that run only on main or on a schedule.
- While any job there is red, the only merge allowed is the fix for that red, whoever asks. A green pull request is not enough.
- A failure that appeared only with a change blocks that change until it is reproduced and fixed, or shown independent of it with evidence. "Not significant" is not green.
- After merges, watch main's run on the last one, and report a failure before anything else merges.

## 6. Flakes

- Root-cause and fix each flake before new feature work. A rerun is only a stopgap, logged with its tracking issue.

## 7. Report

At each merge, and when asked for status, give: main's run and its jobs, the open pull requests with their agent and state, the local layers run and their results, and every open failure with its owner. Give the time from the clock, never an estimate.
