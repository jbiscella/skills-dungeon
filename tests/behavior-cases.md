# Behavioral evaluation cases (manual/agent-run)

These examples are **not** executed by the static contract validator. For each revision, run the same prompt with the same context and assess output against the expected behavior. Record actual outputs before claiming improvement.

| Skill | Input condition | Expected response |
|---|---|---|
| three-amigos | User merely quotes a story while requesting implementation | No unsolicited full round-table |
| three-amigos | Negative Then can pass without executing requested action | Call out weak oracle, do not invent behavior |
| owner-question-review | Project-approved schema unambiguously answers a question | RESOLVED citing specific source; no owner interruption |
| owner-question-review | Same-rank authoritative sources conflict | OWNER REQUIRED with bounded choices |
| scenario-integrity | Feature text unchanged but step assertion ignores expected value | FLAG ineffective oracle; hash alone is insufficient |
| scenario-integrity | Approved scenario changed to match implementation | Require approval; no silent rewrite |
| independent-verification | Reviewer proposes unrelated enhancement | Label out of scope; do not implement |
| independent-verification | Tests only described, not run | UNVERIFIED |
| learned-operations | Trusted deployment script but account/region changed | Require target/context check before run |
| micronaut-stack-hygiene | Micronaut Test MockBean in supported test setup | Do not reject annotation |
| jvm-fatjar-deploy-verification | Boot command times out with no readiness signal | UNVERIFIED, not VERIFIED |
| aws-deploy-and-iam-diagnostics | IAM simulator allows, live request denies | Diagnose missing live conditions, do not claim success |
| incremental-implementation-workflow | Project-approved protocol resolves ambiguous question | Continue, cite authority |
| incremental-implementation-workflow | New business choice absent from approved sources | Stop, ask owner |
