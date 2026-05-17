# aws-deploy-and-iam-diagnostics

A diagnostic skill for Claude Code that resolves four classes of AWS operational problem by structured CLI verification instead of speculation. Covers cross-identity IAM policy diff, deploy state verification chain (git → S3 → alias → version → CodeSha256), config wiring audit (CI variable → Terraform → SSM → Lambda env var), and build artifact provenance.

## When to install

**Install on any project deploying to AWS.** The skill is operational, not architectural — it doesn't dictate how you build, only how to diagnose when something is broken in production.

The value is in **diagnostic speed**, not in preventing the underlying issues. The skill doesn't stop you from forgetting an environment variable or from invoking a Bedrock model your role isn't subscribed to. It does collapse 2-3 PRs of one-bug-at-a-time iteration into a single permissions diff or wiring audit.

## What it actually accelerates

Real symptom-to-cause paths the skill makes much shorter:

- **"Bedrock returns AccessDenied but my CLI session works fine."** Pattern 1 (cross-identity policy diff) extracts the exact action from the exception body and uses `aws iam simulate-principal-policy` to diff the failing role against the working identity. No speculation about "model not enabled" or "wrong region".
- **"I merged to main but the new code doesn't seem to be running."** Pattern 2 (deploy state verification) walks the chain git → artifact in S3 → Lambda alias → version → CodeSha256 in 4 commands. CI green is not proof of deployment.
- **"Env var declared in Terraform but the application reads the default."** Pattern 3 (config wiring audit) cross-references what the app reads against what is actually injected into the Lambda environment, catching missing wiring at the last link of the chain.
- **"I rebuilt and redeployed but the bug is the same."** Pattern 4 (build artifact provenance) compares the SHA256 of the artifact you expect to be deployed against what AWS reports for the function. Mismatch means the deploy did not propagate.

## When this skill might add less value

- Non-AWS projects. The skill is hardcoded to AWS CLI commands and IAM model.
- Projects where you have no permission to run diagnostic IAM/Lambda/SSM calls. If the user lacks `iam:SimulatePrincipalPolicy` or `lambda:GetFunction`, the skill will surface the permission gap honestly but can't proceed.

## Installation

```bash
unzip aws-deploy-and-iam-diagnostics.skill -d .claude/skills/
```

Or `~/.claude/skills/` for global use.

## Composability

The skill assumes infrastructure exists (Terraform, CDK, SAM, etc.) — it doesn't dictate how you author IaC. It also doesn't cover application-level wiring (how a Java/Python/Node app reads env vars and binds them to runtime state); that's stack-specific.

If a deploy issue resolves to "the artifact itself is broken" (thin jar, missing resource, etc.), this skill explicitly points to the `jvm-fatjar-deploy-verification` companion skill for the JVM case.

This skill assumes `incremental-implementation-workflow` is the active development workflow, but does not strictly require it — diagnostic patterns work standalone.
