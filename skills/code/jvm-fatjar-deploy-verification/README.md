# jvm-fatjar-deploy-verification

A build-time verification skill for Claude Code that catches four cascading failure modes when producing a Java fat/uber jar via Maven Shade Plugin: thin jar deployed instead of shaded, missing `application.yml` at classpath root, `META-INF/services` files overwritten, and transitive dependencies excluded from the shaded artifact. Each failure surfaces as a different runtime error, which is what makes the cascade so expensive to debug.

## When to install

**Install on Java projects deploying fat jars to AWS Lambda, container scratch images, or any environment that runs `java -jar <artifact>` without your local classpath.**

The skill is **preventive insurance**, not a problem solver. If your build pipeline already has solid shaded jar verification, the skill adds little. If it doesn't, the skill catches the four failure modes before they reach production.

## What it actually catches

These are the failure modes the skill verifies, each at the level of a bash assertion run after `mvn package`:

| Failure mode | Symptom at deploy | Catch mechanism |
|---|---|---|
| Thin jar deployed | `NoClassDefFoundError` on any non-JDK class | Size threshold check (~10MB minimum) |
| `application.yml` missing | "Property doesn't exist" on bean wiring | `unzip -p` check for resource at classpath root |
| `META-INF/services` overwritten | `NoSuchProviderException`, missing PropertySourceLoader, Jackson modules silently absent | Content check of critical service file |
| Transitive dep missing | `ClassNotFoundException` at boot | Boot the jar in a separate JVM with timeout |

The skill also documents the canonical Maven Shade Plugin configuration (with `ServicesResourceTransformer`) that prevents failure #3 at the source.

## When this skill might add less value

- Projects deploying through mechanisms other than fat jar (Spring Boot launcher jar, WAR file, GraalVM native image, Docker with full JRE).
- Projects whose build pipeline already has artifact verification you trust.
- Gradle projects. The skill mentions Gradle equivalents exist but the concrete configuration shown is Maven-specific.

## Installation

```bash
unzip jvm-fatjar-deploy-verification.skill -d .claude/skills/
```

Or `~/.claude/skills/` for global use.

## Composability

The skill verifies the artifact at build time. It does not cover:

- Whether the verified artifact actually reaches AWS Lambda after CI. That's `aws-deploy-and-iam-diagnostics` Pattern 2.
- Whether the application correctly binds config values once loaded. That's stack-specific (Micronaut, Spring).
- The implementation workflow that produced the code. That's `incremental-implementation-workflow`.

When a deploy fails despite this skill's checks passing, the cause is elsewhere — escalate to the AWS diagnostics skill.
