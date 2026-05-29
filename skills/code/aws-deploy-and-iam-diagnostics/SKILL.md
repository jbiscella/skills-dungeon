---
name: aws-deploy-and-iam-diagnostics
description: Diagnose AWS deployment and IAM problems mechanically rather than by speculation. Use this skill whenever an AWS-related symptom appears — AccessDenied exceptions, "the new code doesn't seem to be running", "CI is green but production is broken", Lambda env var not picked up, IAM works from CLI but fails from service role, config value declared but never reaches runtime. Especially load when the user says "Bedrock model not enabled", "config not loading", "alias points to old version", or any time there is a mismatch between what was deployed and what is actually running. Covers four diagnostic patterns — cross-identity policy diff, deploy state verification chain, config wiring audit, and build artifact provenance.
---

# AWS Deploy and IAM Diagnostics

A skill for resolving four classes of AWS problem that appear similar at the surface ("something is broken in the cloud") but have distinct root causes. Each pattern documents the symptoms it covers, the wrong path most agents take, and the mechanical verification that resolves it.

The skill exists because speculation is cheap and misleading on AWS. The right answer is almost always reachable by 2-4 CLI calls; speculation produces hypotheses that take 10x longer to disprove than to verify.

## When this skill applies

Active in any AWS-deployed project (Lambda, ECS, EKS, EC2) where a symptom is observed and the cause is not immediately obvious from application logs. The four patterns are independent; load the section that matches the symptom.

## Prerequisites

Tools assumed available in the shell:
- `aws` CLI v2 (`aws --version` shows `aws-cli/2.x`)
- `jq`
- `bash`, `grep`, `diff`
- The user's AWS credentials configured (typically via `aws configure` or SSO)
- IAM permissions to read the resources being diagnosed (`iam:SimulatePrincipalPolicy`, `lambda:GetFunction`, `lambda:GetAlias`, `ssm:GetParameter`, etc.)

If a check fails with `AccessDenied` on the diagnostic call itself, the user's credentials lack permission to investigate — say so explicitly, do not speculate about the underlying issue.

## Pattern 1 — Cross-identity policy diff

### Symptom

A service call works when invoked from one AWS identity and fails with `AccessDeniedException` from another. Most common variant: the call works from the user's CLI session (typically with admin or developer-level access) but fails from a service role (Lambda execution role, EC2 instance role, etc.).

A concrete real-world example: a Bedrock model invocation succeeded from the user's admin role but failed from a Lambda role with `AccessDeniedException: aws-marketplace:Subscribe`. The Lambda role had Bedrock invoke permissions but not Marketplace permissions, which newer Anthropic models require because they are served through Marketplace listings. This is the kind of cross-service permission split that is impossible to predict from documentation alone.

### Wrong path (avoid)

Speculating about what the problem might be: "model not enabled", "wrong region", "policy too restrictive". These guesses send the user down rabbit holes. The exception body usually states the exact missing action; read it.

### Procedure

1. **Read the exception body literally.** Extract the action name AWS says is denied. Format is usually `<service>:<Action>` (e.g. `aws-marketplace:Subscribe`, `ses:SendRawEmail`, `bedrock:InvokeModel`). Do not generalize, do not paraphrase.

2. **Diff the two identities' effective permissions for that action.** The CLI command:

```bash
# Replace ROLE_OR_USER_ARN with the failing identity, and ACTION with what the exception named
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/lambda-execution-role \
  --action-names aws-marketplace:Subscribe \
  --query 'EvaluationResults[].{Action:EvalActionName,Decision:EvalDecision}' \
  --output table

# Then the same for the working identity
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:user/your-username \
  --action-names aws-marketplace:Subscribe \
  --query 'EvaluationResults[].{Action:EvalActionName,Decision:EvalDecision}' \
  --output table
```

3. **The fix is mechanical**, not architectural: attach the missing action to the failing role's policy. Do not redesign the IAM structure based on this one finding.

### Verification

After applying the fix, re-run `simulate-principal-policy` on the failing identity — it must now show `allowed`. Then re-invoke the failing call; it should succeed without code changes.

## Pattern 2 — Deploy state verification chain

### Symptom

The CI pipeline reported success, but the deployed system seems to be running old code, or behaves inconsistently with what the source repo says it should do. Variants:
- "I deployed but my change is not visible."
- "The Lambda alias points to an old version."
- "Sometimes invocations hit new code, sometimes old."

### Wrong path (avoid)

Reasoning about runtime behavior before confirming what is deployed. If you cannot prove that the new code is in production, runtime errors are uninterpretable.

### Procedure

Verify the chain mechanically, in order. Each step's output is the input for the next.

1. **What commit is on `main`?**
   ```bash
   git log -1 --format="%H %s" origin/main
   ```

2. **What artifact is in the artifact store?** For Lambda from S3:
   ```bash
   aws s3 ls s3://your-artifact-bucket/path/to/lambda.jar --recursive
   # Note the LastModified and Size
   ```

3. **What version is the alias pointing to?**
   ```bash
   aws lambda get-alias --function-name your-function --name LIVE \
     --query '{Version:FunctionVersion, Updated:RevisionId}'
   ```

4. **What is the LastModified of that version?**
   ```bash
   aws lambda get-function --function-name your-function:LIVE \
     --query 'Configuration.{Version:Version, LastModified:LastModified, State:State, LastUpdateStatus:LastUpdateStatus, CodeSha256:CodeSha256}'
   ```

5. **State and update status.** From the same call: `State` must be `Active`, `LastUpdateStatus` must be `Successful`. If `LastUpdateStatus` is `InProgress`, the function is being deployed right now — wait. If `Failed`, the deploy failed and the alias may still point to the previous version.

If any link in the chain breaks (artifact newer than function code, alias pointing at a different version than expected, state not Active), the cause is in the deploy pipeline, not in the application code. Investigate the CI step that should have published the new version.

### SnapStart-specific edge case

For Lambda with SnapStart, after publishing a new version AWS takes 60-120 seconds to build the snapshot. During this window, invocations against the alias may return `ResourceConflictException` even though the deploy "succeeded". This is transient. The check:

```bash
aws lambda get-function --function-name your-function:LIVE \
  --query 'Configuration.SnapStart'
```

If `OptimizationStatus` is `In Progress`, wait. If `On`, the snapshot is ready.

### Verification

After the chain is confirmed, invoke the Lambda with a payload that exercises the new code and check the result. Do not consider the deploy verified until end-to-end invocation succeeds with the expected behavior.

## Pattern 3 — Config wiring audit

### Symptom

A configuration value is declared in some layer of infrastructure (CI variable, Terraform variable, SSM parameter) but the application behaves as if it has the default value. The change "deployed", but the runtime did not see it.

The common shape: a value travels through `GitHub Variable → workflow env → Terraform variable → SSM parameter → ??? → Lambda runtime` and a link is missing — typically the last one, where the SSM value is supposed to land as a Lambda environment variable but no Terraform resource creates that injection point.

### Wrong path (avoid)

Assuming the chain is intact and debugging from the application side ("the bean must not be reading the property"). If the value never reached the runtime, no application code change will help.

### Procedure

Maintain (or build, ad-hoc) a manifest of every config value the application reads at runtime. For each value:

1. **What is the source of truth?** Default in code, env var, SSM parameter, secret manager?

2. **What injects the value into the application?** For Lambda specifically, only environment variables and the bundled artifact reach the runtime. SSM parameters do *not* automatically become env vars; an explicit Terraform resource (or equivalent) must read SSM and pass the value to the Lambda `environment.variables` block.

3. **Cross-check by reading the deployed runtime configuration:**

```bash
aws lambda get-function-configuration --function-name your-function:LIVE \
  --query 'Environment.Variables' --output json
```

Compare what the application *reads* against what is *injected*. A config key the application reads but that is not in the env var list is a latent bug.

4. **For SSM-backed values**, confirm the parameter exists and has the expected value:

```bash
aws ssm get-parameter --name /your-app/some/parameter \
  --with-decryption --query 'Parameter.Value'
```

If the parameter exists but is not injected into the Lambda env vars, the Terraform (or CDK / SAM / Pulumi) resource that wires SSM → Lambda env var is missing.

### Verification

After fixing the wiring (typically a one-line addition to the Lambda Terraform resource's `environment.variables` block), re-deploy and re-run `get-function-configuration`. The new key must appear. Then invoke the function and confirm the application picks it up.

## Pattern 4 — Build artifact provenance

### Symptom

You suspect the deployed artifact is not the one produced by the latest CI build. Variants:
- "I rebuilt and redeployed but the bug is still there."
- "The artifact name changed during the build process."
- "Two artifacts with similar names; not sure which one ended up deployed."

### Procedure

The Lambda function's `CodeSha256` is computed by AWS over the deployed package contents. If you compute the SHA256 of the artifact in S3 (or wherever CI uploaded it) and compare with what AWS reports, they must match. If they don't, the artifact deployed is not the one you think.

1. **Compute the SHA256 of the artifact you expect to be running.** For a local file:

```bash
sha256sum target/your-app-shaded.jar | awk '{print $1}' | xxd -r -p | base64
```

The `xxd | base64` dance is because AWS reports the hash in base64, not hex. The result should match exactly the `CodeSha256` field from `aws lambda get-function`.

2. **Compare with what Lambda reports:**

```bash
aws lambda get-function --function-name your-function:LIVE \
  --query 'Configuration.CodeSha256' --output text
```

3. **For multi-artifact pipelines**, compute hashes at every handoff (compiled jar → uploaded to S3 → fetched by Lambda update-function-code → reported by AWS). The handoff where the hash changes is the broken link.

### Forward-looking habit

In CI, log the SHA256 of the artifact at the moment of upload and at the moment of deploy completion. Store both in a known location (Lambda function description, DynamoDB audit log, GitHub Actions step summary). When debugging later, compare against expected without having to recompute.

## Anti-patterns

- **Speculating about IAM without reading the exception body.** The exception names the missing action. Read it. Do not invent more general hypotheses (e.g. "Bedrock model needs to be enabled in console" when the exception says `aws-marketplace:Subscribe`).
- **Assuming "CI green" means "code is running".** It means the build, test, and deploy steps did not error. None of those steps verifies the deployed code is what's invoked. Always check the alias → version → CodeSha256 chain when in doubt.
- **Debugging runtime symptoms before confirming the deploy is intact.** A runtime error in old code is a different problem from a runtime error in new code; you cannot fix the second one if you're looking at the first.
- **Adding logs to "see what's happening" before checking config wiring.** If the value never reached the runtime, no log statement in the application code will show the right value. Verify wiring first.
- **Treating SnapStart `ResourceConflictException` as a deploy failure.** It's a transient state during snapshot build. Wait 1-2 minutes and recheck.
- **Bundling multiple diagnostic steps in one chat message.** When troubleshooting a live AWS system, each command's output may invalidate the next planned step. One command per turn, wait for output.

## Composability with other skills

This skill covers operational diagnostics only. It does not cover:

- IaC authoring (Terraform/CDK structure, module patterns). The skill assumes IaC exists; it doesn't dictate how to write it.
- Lambda build artifact verification (was the right jar produced in the first place?). See `jvm-fatjar-deploy-verification` for that.
- Application-level wiring (Micronaut, Spring annotations binding env vars to beans). See stack-specific hygiene skills.
- The implementation workflow that generated the code being deployed. See `incremental-implementation-workflow`.

If a deploy issue resolves to "the artifact itself is broken" (e.g. thin jar instead of fat jar, missing application.yml), this skill points outside its scope — escalate to the build verification skill.
