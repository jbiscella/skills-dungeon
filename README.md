# skills-dungeon

[![License: 0BSD](https://img.shields.io/badge/license-0BSD-blue.svg)](LICENSE)
[![Built for Claude Code](https://img.shields.io/badge/built%20for-Claude%20Code-d97757.svg)](https://claude.com/claude-code)
[![Agent Skills](https://img.shields.io/badge/format-Agent%20Skills-555.svg)](https://docs.claude.com/en/docs/claude-code/skills)

A personal stash of Claude Code skills, distilled from real work — not a framework, not a product.

## What this is

`skills-dungeon` is a small, opinionated collection of [Claude Code](https://claude.com/claude-code) skills I've accumulated while shipping real software: Java services on Micronaut, fat-jar deployments, and AWS infrastructure. Each skill encodes a lesson that cost me time the first time around — an AWS failure mode that looks like five different bugs, a fat jar that compiles green and deploys broken, a Spring annotation silently ignored on a Micronaut class — so that an agent can catch it mechanically instead of speculating.

It is deliberately personal. The skills are tuned to one working style: conclusions-first, BDD/TDD-disciplined, no architectural defaults assumed. They make opinions explicit rather than pretending to be neutral. That's a feature here, and a reason to read before adopting.

This is **not** built for mass distribution. There's no roadmap, no SLA, no attempt to cover every stack or please every workflow. It's a public archive: useful as a reference, as a starting point you fork and bend to your own conventions, or as a worked example of how to write skills that earn their place. If a skill doesn't fit your project, skip it — several are explicitly redundant once your `CLAUDE.md` covers the same ground.

## What's inside

- **Four Claude Code skills** in the [Agent Skills](https://docs.claude.com/en/docs/claude-code/skills) format (`SKILL.md` per folder), each with a README explaining when it helps and when it's redundant.
- **Pre-built `.skill` packages** in `packaged/`, ready for one-off upload to Claude Code.
- **Helper scripts** in `scripts/` to install, package, and validate skills.
- **Install guide** in [`INSTALL.md`](INSTALL.md) covering single-skill copies, `.skill` uploads, and submodule setups.

## Skills included

| Skill | What it does | Use it when | Skip it when |
|---|---|---|---|
| [`incremental-implementation-workflow`](skills/incremental-implementation-workflow) | Drives a prereq → red → green → refactor cycle for increments specified in a `CLAUDE.md`, with explicit handling of ambiguity and drift. | Any project where Claude Code writes code against BDD-style increments. | You don't work from `CLAUDE.md` increments or BDD scenarios. |
| [`aws-deploy-and-iam-diagnostics`](skills/aws-deploy-and-iam-diagnostics) | Diagnoses AWS deploy/IAM problems mechanically — cross-identity policy diff, deploy-state verification, config wiring audit, artifact provenance. | `AccessDenied`, "CI green but prod broken", config not reaching runtime, stale Lambda alias. | The project doesn't touch AWS. |
| [`jvm-fatjar-deploy-verification`](skills/jvm-fatjar-deploy-verification) | Catches the four cascading fat-jar failures (thin jar, missing `application.yml`, clobbered `META-INF/services`, missing transitive dep) before deploy. | Building a Maven Shade fat/uber jar for Lambda or scratch containers. | You don't ship fat jars. |
| [`micronaut-stack-hygiene`](skills/micronaut-stack-hygiene) | Keeps Java code idiomatically Micronaut and free of silently-ignored Spring-isms (compile-time DI, FQN clarifications). | Writing or reviewing Java in a Micronaut project. | Not a Micronaut project, or your `CLAUDE.md` §Code Style already covers it. |

## Quick start

Most of the time you want **one skill**, not the whole repo. The simplest path is to drop a single skill folder into your project's `.claude/skills/`:

```bash
# From a clone or download of this repo, in your project root:
cp -r /path/to/skills-dungeon/skills/aws-deploy-and-iam-diagnostics \
  .claude/skills/aws-deploy-and-iam-diagnostics
```

Or grab just one folder from GitHub without a full clone:

```bash
git clone --filter=blob:none --no-checkout \
  https://github.com/jbiscella/skills-dungeon /tmp/skills-dungeon
cd /tmp/skills-dungeon
git sparse-checkout set --no-cone skills/aws-deploy-and-iam-diagnostics
git checkout main
cp -r skills/aws-deploy-and-iam-diagnostics \
  /path/to/your/project/.claude/skills/
```

Claude Code loads any skill that lives as a direct child of `.claude/skills/`. For `.skill` uploads, submodules, and `git pull` update paths, see [`INSTALL.md`](INSTALL.md).

## Repository structure

```
.
├── skills/                # Claude Code skills, one folder per skill
│   ├── incremental-implementation-workflow/
│   ├── micronaut-stack-hygiene/
│   ├── jvm-fatjar-deploy-verification/
│   └── aws-deploy-and-iam-diagnostics/
│
├── packaged/              # Pre-built .skill packages (zips of the above)
├── scripts/               # install.sh · package.sh · validate.sh
├── INSTALL.md             # How to consume this in another project
├── CHANGELOG.md           # What changed when
└── LICENSE                # 0BSD
```

## Important note

This is an archive of *my* working practices, not a neutral toolkit. The skills bake in specific opinions — outside-in BDD, mechanical verification over speculation, explicit governance of ambiguity — and they assume a `CLAUDE.md`-driven workflow. They were written for Java / Micronaut / AWS projects and reflect the failure modes I actually hit.

Read a skill's `SKILL.md` and `README.md` before adopting it. Each one says when it adds value and when it's redundant. Take what fits, rewrite what doesn't, and don't expect it to track your stack — it tracks mine.

## License

[BSD Zero Clause License (0BSD)](LICENSE) — public-domain-equivalent, no attribution required. Do whatever you want with it.
