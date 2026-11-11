---
name: owner-question-review
description: Triage unresolved requirement questions against project-designated sources before escalating to the owner. Use for blocked behavioral choices, missing authority and conflicting specifications; not for straightforward implementation.
---

# Owner Question Review

Resolve what the project has already decided; escalate only decisions the agent does not own.

## Minimum protocol

**On load.** Read the exact blocked question, affected scenario and source-of-truth order established by the project.
**Stop on.** Missing authority, same-level contradictions, source inaccessible, or a new business decision.
**Expected output shape.** Question | authoritative evidence | disposition (RESOLVED / OWNER REQUIRED / UNVERIFIED) | bounded owner choice, if necessary.

## Procedure

1. State the precise unknown without expanding scope.
2. Inspect sources in the *project's* declared order. Never invent universal precedence.
3. If an authoritative source resolves the case, cite its specific passage and return RESOLVED.
4. If sources conflict at equal rank or no source decides, return OWNER REQUIRED with bounded choices and selection criteria.
5. If a referenced source is inaccessible, return UNVERIFIED; do not guess.

Recommendations are proposals and never override the spec owner. Do not request already-recorded decisions again.

## Output

Provide context, evidence consulted, disposition, owner question if any, and explicitly approved out-of-scope. Compatible with the eight-section clarification brief but independently usable in Claude.ai.
