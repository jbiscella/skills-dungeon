---
name: scenario-integrity
description: Audit approved BDD scenarios and step definitions for unauthorized behavioral changes or weak oracles. Use when editing feature files, step definitions or accepting completed behavioral increments; skip without an approved baseline.
---

# Scenario Integrity

Approved scenarios constrain the implementer; a passing test does not prove an effective oracle.

## Minimum protocol

**On load.** Identify approved revision and owner, changed scenarios and step definitions.
**Stop on.** Unapproved semantic change, missing authority, ambiguous Then-to-assertion mapping.
**Expected output shape.** Scenario | approved baseline | changed behavior | observable assertion | VERIFIED / FAILED / UNVERIFIED.

## Procedure

1. Identify the project's approved baseline and its approval process. Current repository state is not automatically authoritative.
2. Diff scenario text against baseline. Hashes may detect textual changes but cannot validate semantics or step implementation.
3. Map Given to setup, When to action and each Then to an observable assertion. Verify the assertion discriminates correct from incorrect results.
4. For negative Then, ensure a no-op, inactive subscription or local filter cannot satisfy the assertion without the required action.
5. For risky oracles, run a safe targeted negative control when justified; report unexecuted sensitivity checks as UNVERIFIED.
6. Approved changes update the baseline via the owner-defined process; do not edit a scenario just to make Green.

Do not require blanket mutation testing or introduce scenarios not authorized by the owner.
