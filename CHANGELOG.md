# Changelog

All notable changes to this repository are recorded here.

## [Initial] — 2026-05-17

First archive snapshot.

### Skills

- `incremental-implementation-workflow` — BDD/TDD discipline for implementing CLAUDE.md increments. Includes red discipline, definition of done, ADR primacy, drift detection (with retroactive pre-flight audit on increments marked done).
- `micronaut-stack-hygiene` — Spring vs Micronaut annotation hygiene with full FQN clarifications.
- `jvm-fatjar-deploy-verification` — Catches four cascading failure modes when producing a fat jar (thin jar, missing application.yml, META-INF/services overwritten, missing transitive dep).
- `aws-deploy-and-iam-diagnostics` — Four diagnostic patterns (cross-identity policy diff, deploy state verification chain, config wiring audit, build artifact provenance).

### Infrastructure

- Installation patterns documented in `INSTALL.md`.
- Symlink helper, package builder, and validator in `scripts/`.
