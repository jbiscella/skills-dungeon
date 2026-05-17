# micronaut-stack-hygiene

A hygiene skill for Claude Code that prevents Spring-isms from contaminating Micronaut code. Documents the annotation mapping (Spring → Micronaut equivalents), banned Spring patterns, and Micronaut idioms for factory methods, configuration binding, and test property overrides.

## When to install

**Install on Micronaut projects that do NOT already document the Spring-vs-Micronaut distinction in their `CLAUDE.md`.**

Honest framing: this skill is the **lowest-value of the family** if your project's `CLAUDE.md` already includes a Code Style section explicitly mapping Spring annotations to Micronaut equivalents. In that case the skill becomes confirmative rather than corrective — useful only as a fallback when the spec is consulted incompletely.

The skill genuinely helps in two scenarios:

- **Early-stage projects or spikes** where no comprehensive `CLAUDE.md` exists yet.
- **Codebases migrated from Spring** where residual Spring annotations may still appear in legacy code and Claude Code needs explicit guidance not to propagate them.

For a well-documented project (a `CLAUDE.md` with a complete Code Style section), the project's documentation already does the work. Loading this skill alongside is redundant — not harmful, but adds nothing.

## What it actually addresses

The skill targets a specific failure mode: annotations that share names across frameworks but live in different packages with different runtime behavior. The classic trap:

| Annotation | Looks like Spring? | Actually correct? |
|---|---|---|
| `@Singleton` | No (`@Component` is Spring) | `jakarta.inject.Singleton` |
| `@Value` | Yes (also a Spring annotation) | `io.micronaut.context.annotation.Value` — **different semantics** |
| `@ConfigurationProperties` | Yes (also a Spring annotation) | `io.micronaut.context.annotation.ConfigurationProperties` — **different semantics** |
| `@MicronautTest` | No equivalent in Spring | `io.micronaut.test.extensions.junit5.annotation.MicronautTest` |
| `@TestPropertySource` | Yes (Spring only) | **banned** — use `@Property` or `@MicronautTest(propertySources=…)` |

Compile-time dependency injection in Micronaut means a Spring annotation in a Micronaut class often compiles silently and does nothing at runtime. The bug is invisible until the missing wiring causes a downstream failure. The skill makes the trap explicit.

## When this skill might add less value or be redundant

- Your `CLAUDE.md` already has a Spring-vs-Micronaut table that Claude Code reads at session start. The skill duplicates that content.
- You're not coming from Spring. The trap mostly bites people whose mental model is Spring Boot.
- You're using Kotlin. The skill assumes Java; some idioms map differently in Kotlin (KAPT/KSP processors, property delegates).

## Installation

```bash
unzip micronaut-stack-hygiene.skill -d .claude/skills/
```

Or `~/.claude/skills/` for global use.

## Composability

The skill targets annotation and bean wiring hygiene only. It does not cover:

- Build packaging (fat jar, shaded artifact). That's `jvm-fatjar-deploy-verification`.
- AWS deploy and IAM (Lambda config, env vars, role policies). That's `aws-deploy-and-iam-diagnostics`.
- The implementation workflow. That's `incremental-implementation-workflow`.

When a `CLAUDE.md` in the project conflicts with this skill, `CLAUDE.md` wins. This skill exists to fill gaps the project documentation does not address, not to override it.
