# skills-dungeon

Personal archive of working artifacts for collaborating with AI assistants on software projects: Claude Code skills and the scripts that bind them.

The contents are tuned to one user's working style (direct, conclusions-first, BDD-disciplined, no architectural defaults). They are public as a reference and a possible starting point for others; they are not a curated marketplace.

## Layout

```
.
├── skills/                # Claude Code skills, one folder per skill
│   ├── incremental-implementation-workflow/
│   ├── micronaut-stack-hygiene/
│   ├── jvm-fatjar-deploy-verification/
│   └── aws-deploy-and-iam-diagnostics/
│
├── packaged/              # Pre-built .skill packages (zips of the above)
│   └── *.skill
│
├── scripts/               # Helpers for consuming projects
│   ├── install.sh         # Symlink selected skills into a project
│   ├── package.sh         # Rebuild .skill files from skills/
│   └── validate.sh        # Validate every SKILL.md
│
├── INSTALL.md             # How to consume this in another project
├── CHANGELOG.md           # What changed when
└── LICENSE                # MIT
```

## What's inside

### Skills

`skills/` contains Claude Code skills, each in its own folder per the Agent Skills open standard (`SKILL.md` + optional `README.md` + optional bundled resources).

| Skill | Purpose | Install where |
|---|---|---|
| `incremental-implementation-workflow` | BDD/TDD discipline for implementing CLAUDE.md increments | Every project where Claude Code writes code |
| `aws-deploy-and-iam-diagnostics` | Mechanical diagnosis of AWS deploy/IAM problems | Projects deploying to AWS |
| `jvm-fatjar-deploy-verification` | Catch fat-jar packaging cascades before deploy | Java projects deploying fat jars (Lambda, scratch images) |
| `micronaut-stack-hygiene` | Prevent Spring-isms in Micronaut code | Micronaut projects without a comprehensive CLAUDE.md §Code Style |

Each skill folder has its own `README.md` explaining when it adds value and when it is redundant.

### Packaged

`packaged/` contains `.skill` zip archives — the same skills bundled per the Anthropic skill packaging convention. Use these for one-off installs without git submodule, or for upload to the Claude Code skill installation flow.

## How to consume this in another project

See `INSTALL.md` for the four installation patterns (git submodule, sparse checkout, direct copy, .skill upload). The default recommendation is **git submodule + selective symlink via `scripts/install.sh`**.

## License

MIT. See `LICENSE`.

## Status

Personal archive. No SLAs, no roadmap. Updated when the owner's working practices evolve.
