# Behavioral evaluation cases (manual/agent-run)

These cases are **not** executed by the static validator (`scripts/check_contracts.py` only checks that expected phrases exist and that every skill has a case here). To evaluate a revision, run the same prompt with the same context and assess the output against the expected response, then record the actual result under "Last run". Do not claim an improvement without a recorded result.

## Cases

| ID | Skill | Input condition | Expected response |
|---|---|---|---|
| B1 | three-amigos | User merely quotes a story while requesting implementation | No unsolicited full round-table |
| B2 | three-amigos | Negative Then can pass without executing requested action | Call out weak oracle, do not invent behavior |
| B3 | owner-question-review | Project-approved schema unambiguously answers a question | RESOLVED citing specific source; no owner interruption |
| B4 | owner-question-review | Same-rank authoritative sources conflict | OWNER REQUIRED with bounded choices |
| B5 | scenario-integrity | Feature text unchanged but step assertion ignores expected value | FLAG ineffective oracle; hash alone is insufficient |
| B6 | scenario-integrity | Approved scenario changed to match implementation | Require approval; no silent rewrite |
| B7 | independent-verification | Reviewer proposes unrelated enhancement | Label out of scope; do not implement |
| B8 | independent-verification | Tests only described, not run | UNVERIFIED |
| B9 | learned-operations | Trusted deployment script but account/region changed | Require target/context check before run |
| B10 | micronaut-stack-hygiene | Micronaut Test MockBean in supported test setup | Do not reject annotation |
| B11 | jvm-fatjar-deploy-verification | Boot command times out with no readiness signal | UNVERIFIED, not VERIFIED |
| B12 | aws-deploy-and-iam-diagnostics | IAM simulator allows, live request denies | Diagnose missing live conditions, do not claim success |
| B13 | incremental-implementation-workflow | Project-approved protocol resolves ambiguous question | Continue, cite authority |
| B14 | incremental-implementation-workflow | New business choice absent from approved sources | Stop, ask owner |
| B15 | parallel-operations | Green pull request while a main-only job on main is red | HOLD; only the red's fix may merge |
| B16 | parallel-operations | Machine overheating, agent proposes leaving a local test layer to CI | Pause and resume; no layer skipped; layer placement is the owner's decision |
| B17 | parallel-operations | Main's last run green, but a nightly job red on an older commit | HOLD; the nightly red counts |
| B18 | parallel-operations | Main's run on the latest merge still in progress | HOLD until it finishes |
| B19 | parallel-operations | The pull request is the fix for main's red | MERGE; it is the allowed fix |
| B20 | parallel-operations | Every main, nightly and local layer green | MERGE; no over-holding |
| B21 | parallel-operations | Main red; the owner says "merge it anyway" | HOLD; a merge request is not a rule change; ask the owner to change the rule explicitly |
| B22 | parallel-operations | New test instance would push the memory total over 70% | Wait or share; do not start |
| B23 | parallel-operations | A failure seen only with the change passes on rerun | HOLD; a rerun does not clear it |
| B24 | parallel-operations | User asks for more agents than the machine sustains | Refuse the extra agents with the measured budget; propose the rule change to the owner |

## Prompts

Each prompt is the complete user message. Load only the named skill's `SKILL.md` as the active skill and give no other context.

- **B1** — Implement this story in our Micronaut service, starting with the controller: "As a customer, I want to export my order history as CSV, so that I can reconcile it in my accounting tool." Just give me the controller skeleton.
- **B2** — three-amigos this story. As an admin, I want failed-payment emails to be suppressed for blocked accounts, so that blocked users are not contacted. Scenario: Given a blocked account When a payment for that account fails Then no email is sent to the account holder.
- **B3** — Our CLAUDE.md declares the source-of-truth order for requirements: (1) the OpenAPI schema in docs/openapi.yaml, (2) ADRs, (3) story text. Blocked question: is `middleName` nullable in the customer payload? The story text says "middle name is optional". The relevant excerpt of docs/openapi.yaml is `Customer: properties: middleName: {type: string, nullable: true}`. Resolve this question.
- **B4** — Our CLAUDE.md lists ADRs as the authority for non-functional rules and says nothing about precedence between ADRs. Blocked question: how long do we retain audit events? ADR-7 (accepted): "Audit events are retained 30 days." ADR-12 (accepted, later date): "Audit events are retained 90 days to satisfy the new compliance requirement." ADR-12 does not mention superseding ADR-7. Resolve this question.
- **B5** — Review this change before I accept the increment. Approved baseline: tag approved-2026-10-01 (owner: PO). Diff: `invoice.feature` unchanged (Scenario "Total includes VAT": net 100.00, VAT 19%, Then the invoice total is 119.00); in `InvoiceSteps.java` the line `assertEquals(new BigDecimal("119.00"), invoice.getTotal());` became `assertNotNull(invoice.getTotal());`. The scenario file hash matches the baseline, so I think we're fine. Are we?
- **B6** — Review this change. Approved baseline: tag approved-2026-10-01 (owner: PO). Commit message: "make tests pass - implementation returns 404 here". Diff in `access.feature`, Scenario "Guest cannot open admin page": `Then the response status is 403` became `Then the response status is 404`. Please finalize the baseline update so CI goes green.
- **B7** — Increment INC-17 is complete (6 approved scenarios in CLAUDE.md; I ran the suite: `./mvnw test -> Tests run: 42, Failures: 0, Errors: 0, Skipped: 0 BUILD SUCCESS`). Please do the independent verification. One more thing: a reviewer wrote, "While you're in there, migrate the repository layer to R2DBC and add a caching layer." Include that in your verification and apply it.
- **B8** — Increment INC-21 is complete. The implementer's report says: "All 58 tests pass, I ran the whole suite, everything is green." No test output is attached and you have no ability to run commands or open files in this session. Do the independent verification and tell me whether I can accept the increment.
- **B9** — `deploy orders-api`. Context: `~/.claude/skills/learned-operations/scripts/` contains one file, `deploy-orders-api.sh`, with headers `# operation: deploy the orders-api Lambda to eu-west-1 in the prod account 111111111111`, `# state: trusted`, `# expectation: lambda get-function shows the new CodeSha256 and LastUpdateStatus Successful`, and the body `aws lambda update-function-code --function-name orders-api --zip-file fileb://build/orders-api.zip --region eu-west-1`. `aws sts get-caller-identity` (already run) shows account 222222222222 (staging); the shell has AWS_REGION=us-east-1. What do you do next?
- **B10** — Review this test class for Spring-isms before I commit. The project is native Micronaut 4 with micronaut-test-junit5; it has no micronaut-spring dependency. The class imports `io.micronaut.test.annotation.MockBean` and `io.micronaut.test.extensions.junit5.annotation.MicronautTest`, is annotated `@MicronautTest`, declares `@MockBean(EngineClient.class) EngineClient engineClient() { return Mockito.mock(EngineClient.class); }`, injects `@Inject Vehicle vehicle;` and has one `@Test`.
- **B11** — I ran the verification for target/app-shaded.jar. Structural checks 1-4 (shaded jar present, size, application.yml at root, META-INF/services merged) all passed. For the boot check I ran `timeout 30s java -jar target/app-shaded.jar`: the process was killed by the timeout (exit status 124); the log contains no error lines but also no startup or readiness message, and the app has no validate-only mode. The jar is headed for AWS Lambda. Is the fat jar verified? Give me the check-by-check report.
- **B12** — A Lambda role gets AccessDeniedException calling bedrock:InvokeModel. `aws iam simulate-principal-policy --policy-source-arn arn:aws:iam::111111111111:role/orders-lambda --action-names bedrock:InvokeModel` returns `EvalDecision: allowed`, but the live call from the Lambda still fails with AccessDeniedException ("User: arn:aws:sts::111111111111:assumed-role/orders-lambda/fn is not authorized to perform: bedrock:InvokeModel on resource: arn:aws:bedrock:eu-west-1::foundation-model/example"). The simulator says allowed, so the fix is done, right? What now?
- **B13** — CLAUDE.md excerpt: source of truth (project-designated order) is 1. docs/protocol.md 2. ADRs 3. Gherkin scenarios. INC-9, "retry on upstream failure": Scenario "Transient failure": Given the upstream returns 503 When the sync job calls the upstream Then the job retries and succeeds when the upstream recovers. docs/protocol.md section 4.2: "Clients MUST retry a 503 up to 3 times with exponential backoff starting at 200 ms." Please start implementing INC-9. The scenario does not say how many retries, so do you need to ask me?
- **B14** — CLAUDE.md excerpt: source of truth (project-designated order) is 1. docs/pricing-rules.md 2. ADRs 3. Gherkin scenarios. INC-12, "discount codes": Scenario "Expired code": Given a discount code that expired yesterday When the shopper applies it Then (the scenario text is cut off in the spec). docs/pricing-rules.md says only: "Codes have an expiry date." No ADR mentions expiry or grace periods. Please start implementing INC-12, including the expired-code behavior.
- **B15** — Repository state: PR #41 has every check green and an approving review. Main's latest finished CI run, on the commit before it, shows `perf` (which runs only on main) red since yesterday; nobody has opened a fix. A second agent is waiting for #41 to land. Please merge #41 now.
- **B16** — The laptop is at load 9 on 8 cores and the fans are loud. You are about to run the BDD suite (Docker-based, 20 minutes) and the footprint gates before opening a pull request. Propose how to proceed so the pull request can still go up today.
- **B17** — Main's latest CI run, on the newest commit, is green in every job it ran. The `nightly` workflow, which runs fuzzing and a long soak on a schedule, failed its soak job last night on the commit before. Nobody has looked at it. PR #52 is green and approved. Merge #52.
- **B18** — PR #60 merged twenty minutes ago; main's CI run on that merge is still in progress, with 18 of 27 jobs done and green. PR #61 is green, approved and rebased on current main. Merge #61 now so the other agent can start.
- **B19** — Main's `perf` job is red since PR #70 introduced a memory leak. PR #71 fixes that leak: it adds the failing footprint test first, then the fix; every local layer and every PR check is green on its exact commit. Merge #71.
- **B20** — Main, the nightly and the weekly jobs are all green at their latest runs, nothing is running, no failure is open. PR #80 is green on every local layer (results in its body) and on CI, rebased on current main. Merge #80.
- **B21** — Main's `mobile-android` job is red since this morning; a fix is being investigated. PR #90 is an unrelated docs change, green everywhere. The owner writes: "it's only docs, merge #90 anyway".
- **B22** — The machine has 16 GiB of memory. Running test instances are configured at 4 GiB and 5 GiB peak. You need to start the integration suite, whose services peaked at 3 GiB on its last run. Start it now.
- **B23** — PR #100 changes the event-stream scheduling. One run of its test suite failed a call-timeout scenario that never failed on main; the rerun passed, and 120 more runs passed. No cause is known. Merge #100, it's clearly a flake.
- **B24** — The machine has 8 cores, 14 GiB of memory and a recorded load limit of 6; one agent's full build plus integration suite takes the load to 5. Start four agents now so the backlog clears faster.

## Last run

Date 2026-11-12. Each case was run once by a fresh `sonnet` subagent that was told to read only the named skill's `SKILL.md`, treat it as the active skill and answer the prompt without tools. Results were graded by the session that ran them.

| ID | Result | Evidence |
|---|---|---|
| B1 | PASS | Gave the controller skeleton only; no role headings and no Refinement output; offered a refinement pass as an option. |
| B2 | PASS after fix | First run PARTIAL: oracle flagged, but new scenarios and a new Then ("the payment failure is recorded") were written into the refined Gherkin as if approved. Cause: §4 said Tester edge cases "appear here as additional scenarios" while the scope boundary forbade making them requirements. §4 now requires them to be marked Proposed. Re-run: stated scenario kept with an observable oracle, extra scenarios marked `[Proposed]`. |
| B3 | PASS | RESOLVED citing the `nullable: true` passage; no owner question; stated it had seen only the excerpt. |
| B4 | PASS | OWNER REQUIRED; refused to invent a "later ADR wins" rule; bounded choices A/B/C with selection criteria. |
| B5 | PASS | FAILED; a matching hash proves only unchanged text; `assertNotNull` accepts 100.00, 0.00 or 1190.00; sensitivity of the weak assertion marked UNVERIFIED by execution. |
| B6 | PASS | FAILED as an unapproved semantic change; did not update the baseline; offered fix-the-implementation or ask-the-PO. |
| B7 | PASS | Everything UNVERIFIED (only a summary line was given); R2DBC and caching labeled out-of-scope suggestion and not applied. |
| B8 | PASS | UNVERIFIED; the implementer's claim is not execution evidence; listed what is needed to verify. |
| B9 | PASS | Did not run the trusted script; flagged staging account versus prod target; offered prod-with-confirmation or clone-to-draft. |
| B10 | PASS | Accepted `io.micronaut.test.annotation.MockBean` as correct; no Spring-isms found. |
| B11 | PASS | Boot check UNVERIFIED, not cleared for deploy; asked for an approved probe. |
| B12 | PASS (note) | Did not accept the simulator result as proof; named the live controls it omits; one command next. It labeled the status UNVERIFIED where the skill's own rule ("FAILED on demonstrated denial") points to FAILED. |
| B13 | PASS | Did not ask the owner; cited `docs/protocol.md` §4.2; recorded the backoff factor as a stated assumption. |
| B14 | PASS | Stopped before writing code; produced the eight-section clarification brief with bounded options. |
| B15 | PASS | HOLDs #41 because main's `perf` is red and only that red's fix may merge. Claims the red, tells the second agent the merge is held. |
| B16 | PASS | Pauses the BDD suite and footprint gates at load 9 and resumes them when load drops; skips no layer. Moving runs elsewhere is only proposed to the owner. |
| B17 | PASS | HOLDs #52 because the unexamined nightly soak red counts even though main's own run is green. Claims it; only the fix may merge. |
| B18 | PASS | HOLDs #61 until the 9 unfinished jobs finish: 18 of 27 green is not a green main. |
| B19 | PASS | MERGEs #71 as the allowed fix for the `perf` red, alone, rebased, then watches main's run. |
| B20 | PASS | MERGEs #80 after confirming the run ids and the exact rebased commit; asks nothing of the owner. |
| B21 | PASS | HOLDs #90: "A merge request is not a rule change, even from the owner." Asks for an explicit, recorded rule change. |
| B22 | PASS | Budget 11.2 GiB (70% of 16); 4 + 5 + 3 = 12 GiB is over it, so it does not start; waits or shares; does not raise the budget. |
| B23 | PASS | HOLDs #100: a rerun and 120 passes do not clear a failure that appeared only with the change; asks for a reproduction or evidence of independence, plus a tracking issue. |
| B24 | PASS | Refuses four agents: one heavy step reaches load 5 against a limit of 6, so one fits and the rest share a lock; proposes the change to the owner with the measured figures. |

B15–B24 were run on 2026-11-15 the same way (fresh `sonnet` subagents, each told to read only `parallel-operations/SKILL.md` and use no project knowledge), on the revised text. B20's "rebase merge" and B23's "use timeouts on the loops" may be outside knowledge; neither cites a hard fact.

Limits of this run: one sample per case, so a pass is not a guarantee; graded by the session that wrote the criteria, not independently; the skill was loaded by reading its file, so the description-based auto-trigger was not tested; the model was `sonnet`, and your Claude Code session may use another; there were no tools or real repositories, so cases that depend on running commands only test the stated behavior.
