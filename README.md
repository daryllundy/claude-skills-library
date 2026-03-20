# Claude Skills Library

A repository of reusable Claude Code skills plus the tooling to recommend and install them into other projects.

It currently ships:

- 38 skill directories in the canonical `.claude/skills/` format
- a Bash-based recommender/installer CLI in `scripts/recommend_skills.sh`
- declarative YAML detection patterns under `data/patterns/`
- docs, examples, and a shell test suite for the recommender workflow

[Getting started](./GETTING_STARTED.md) • [Skills registry](./.claude/skills/SKILLS_REGISTRY.md) • [Examples](./examples/README.md) • [Docs](./docs/README.md)

## What is in this repo

The main catalog lives under `.claude/skills/`. Each skill is packaged as a directory with:

- `SKILL.md`: the discovery-oriented entrypoint Claude reads first
- `references/`: longer-form guidance migrated from older prompt assets
- `scripts/`: optional helper scripts
- `assets/`: templates and supporting artifacts when a skill needs them
- `manifest.txt`: the file list used for install/update operations

The recommender scans a target project, matches it against weighted detection patterns, then suggests or installs the most relevant skills into that project's `.claude/skills/` directory.

## Quick start

Clone the repo if you want the full catalog locally:

```bash
git clone git@github-daryllundy:daryllundy/claude-skills-library.git
cd claude-skills-library
```

Or run the recommender directly from the project you want to enhance:

```bash
curl -sSL https://raw.githubusercontent.com/daryllundy/claude-skills-library/main/scripts/recommend_skills.sh | bash
```

Preview recommendations without writing files:

```bash
bash scripts/recommend_skills.sh --dry-run
```

Install the recommended skills into the current project:

```bash
bash scripts/recommend_skills.sh
```

Use interactive selection when you want to override the automatic picks:

```bash
bash scripts/recommend_skills.sh --interactive
```

## Recommender capabilities

`scripts/recommend_skills.sh` supports:

- confidence-based recommendations with `--min-confidence`
- interactive selection with keyboard navigation
- profile export/import with `--export` and `--import`
- update checks with `--check-updates` and `--update-all`
- network retry and caching controls such as `--force-refresh`, `--clear-cache`, and `--cache-expiry`
- custom pattern sources through `--patterns-dir` or `SKILL_PATTERNS_DIR`

The legacy `scripts/recommend_agents.sh` entrypoint still exists as a deprecation wrapper around `scripts/recommend_skills.sh`.

## Detection patterns

Detection logic is no longer just embedded in shell code.

- `data/patterns/*.yml` contains the current modular YAML pattern library by category
- `data/patterns/SCHEMA.md` documents the pattern schema
- `data/patterns/QUICK_REFERENCE.md` provides a short authoring guide
- `data/agent_patterns.yaml` remains in the repo as legacy consolidated pattern data used during the transition

These patterns drive weighted confidence scores for infrastructure, development, quality, operations, productivity, business, and specialized skills.

## Repository layout

```text
.claude/skills/              Canonical shipped skill catalog
scripts/                     Recommender and compatibility wrapper
data/patterns/               Modular YAML detection patterns and docs
docs/                        Technical docs for caching, testing, and scoring
examples/                    Prompt-shaped usage examples
tests/                       Unit and integration tests for the CLI
archive/                     Legacy setup scripts and archived Python implementation
```

## Example use cases

```text
"Use the docker-specialist to create a production-ready multi-stage Dockerfile."
"Use the security-specialist to review src/auth/ for vulnerabilities."
"Use the architecture-specialist to design an API, then hand off to database, test, and documentation specialists."
```

More examples live in [examples/README.md](./examples/README.md).

## Testing

Run the full recommender test suite with:

```bash
bash tests/run_all_tests.sh
```

The suite covers detection, confidence scoring, rendering, caching, retry behavior, profile import/export, update flows, YAML parsing, and interactive mode. Interactive tests run only when `expect` is available.

## Migration notes

- The canonical surface is `.claude/skills/`, not `.claude/agents/`
- Skill entrypoints in this repo are named `SKILL.md`
- `CLAUDE_SKILLS_*` environment variables are the preferred names
- legacy `CLAUDE_AGENTS_*` environment variables and `~/.cache/claude-agents` are still honored temporarily for compatibility

## Limitations

This repository does not bundle MCP servers or external integrations. If a skill reference mentions MCP-backed workflows, treat those as prerequisites that must already exist in the user environment.

Archived material under `archive/` is kept for reference and migration context; the active implementation is the Bash recommender plus the current `.claude/skills/` catalog.
