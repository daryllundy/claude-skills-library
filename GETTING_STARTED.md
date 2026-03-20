# Getting Started

This repository now uses the official Claude skill directory format. If you want to use these capabilities in another project, install the relevant directories into that project's `.claude/skills/` folder.

## Quick Start

1. Clone this repository somewhere accessible.

```bash
git clone https://github.com/daryllundy/claude-skills-library.git
cd claude-skills-library
```

2. From the root of the project you want to enhance, run the recommender.

```bash
curl -sSL https://raw.githubusercontent.com/daryllundy/claude-skills-library/main/scripts/recommend_skills.sh | bash
```

3. Verify the installed files under `.claude/skills/`.

Expected structure:

```text
.claude/
  skills/
    SKILLS_REGISTRY.md
    docker-specialist/
      skill.md
      manifest.txt
      references/
      scripts/
      assets/templates/
```

## Common Commands

```bash
# Show recommendations only
bash scripts/recommend_skills.sh --dry-run

# Choose skills interactively
bash scripts/recommend_skills.sh --interactive

# Export the recommended skill set
bash scripts/recommend_skills.sh --dry-run --export my-project-profile.json

# Import a saved skill set
bash scripts/recommend_skills.sh --import my-project-profile.json

# Check for updates
bash scripts/recommend_skills.sh --check-updates

# Apply updates
bash scripts/recommend_skills.sh --update-all
```

Migration note: `scripts/recommend_agents.sh` remains available as a temporary wrapper. Legacy `CLAUDE_AGENTS_*` env vars and `~/.cache/claude-agents` are still read during the transition, but the canonical names are now `CLAUDE_SKILLS_*` and `~/.cache/claude-skills-library`.

## How the Skills Are Organized

Each skill directory contains:

- `skill.md`: short discovery-oriented entrypoint
- `references/`: detailed guidance and migrated legacy material
- `scripts/`: helper scripts if the skill needs executable support
- `assets/templates/`: reusable templates and artifacts
- `manifest.txt`: installer manifest for downloading/updating the full directory

The catalog lives in [`.claude/skills/SKILLS_REGISTRY.md`](/Users/daryl/work/claude-agents/.claude/skills/SKILLS_REGISTRY.md).

## MCP Clarification

The repository does not include MCP servers. Any MCP-related workflow described by a skill assumes the needed MCP server is already configured in your environment.

## Recommended Usage Pattern

- Let Claude discover skills automatically from `skill.md`.
- Open `references/` only when the task needs detailed checklists or examples.
- Keep new skill entrypoints concise; move bulky content into linked files.

## More Reading

- [README.md](/Users/daryl/work/claude-agents/README.md)
- [CLAUDE_CODE_USAGE.md](/Users/daryl/work/claude-agents/CLAUDE_CODE_USAGE.md)
- [docs/NETWORK_OPERATIONS.md](/Users/daryl/work/claude-agents/docs/NETWORK_OPERATIONS.md)
