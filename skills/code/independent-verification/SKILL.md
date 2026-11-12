---
name: independent-verification
description: Review a completed agent-written increment using fresh evidence of behavioral correctness, regressions and operational invariants. Use at meaningful increment boundaries or high-risk reviews, not as a second decision maker.
---

# Independent Verification

Independent evidence matters more than adding a second opinion.

## Minimum protocol

**On load.** Gather approved scenario, authority order, diff, assertions and actual test outputs; use a fresh reviewer context when available.
**Stop on.** Unauthorized behavioral change, demonstrated defect, missing proof or a suggested fix outside scope.
**Expected output shape.** Finding | evidence/reproduction | class | VERIFIED / FAILED / UNVERIFIED | owner decision required.

## Procedure

1. Inspect original approved scenarios and ADRs independently of implementer's summary.
2. Map important Then clauses to assertions; evaluate no-op and negative-case false passes.
3. Inspect actual focused/regression test results and applicable operational invariants. A screenshot or summary alone is not execution evidence.
4. Classify findings: proven in-scope defect; unresolved owner choice; out-of-scope suggestion; unverified hypothesis.
5. Independently substantiate findings before changes. Reviewer suggestions are not automatically requirements.
6. Report VERIFIED, FAILED or UNVERIFIED with explicit limitations.

A second model can diversify review but does not itself prove independence or correctness. If unable to run checks, disclose this instead of certifying success.
