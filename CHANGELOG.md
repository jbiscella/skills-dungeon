# Changelog

All notable changes to this repository are recorded here.

## 2026-05-29 — learned-operations

### Skills

- `learned-operations` — cross-project shell-operation memory. Crystallises multi-step operations as bash scripts with a `draft → verified → trusted` state header; reuses matched scripts instead of regenerating commands. Targets user-home install at `~/.claude/skills/learned-operations/` and pairs with a one-paragraph trigger line in `~/.claude/CLAUDE.md`.

## 2026-05-29

### Structure

- Split `skills/` by target surface: Claude Code skills moved under `skills/code/`, the Claude.ai chat skill `three-amigos` moved under `skills/chat/`. `packaged/` stays flat (one `.skill` per skill, named by bare skill name).
- `scripts/validate.sh` and `scripts/package.sh` now walk two levels (surface + skill). `scripts/install.sh` only sources `skills/code/` — chat skills install through the Claude.ai UI, not via symlink.
- Root `README.md` skills table gained a Surface column. `INSTALL.md` gained Pattern 0 documenting the Claude.ai chat upload flow (Settings → Customize → Skills → + Create skill → upload `.skill`) per the current 2026 Claude.ai UI.

### Skills

- `three-amigos` — chat-time refinement skill for draft user stories and CLAUDE.md increments. Three role personas (Business Analyst, Tester, Technician) with targeted and round-table modes; round-table emits refined value clause, Gherkin scenarios, open questions, and out-of-scope. Designed to feed `incremental-implementation-workflow`.

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
