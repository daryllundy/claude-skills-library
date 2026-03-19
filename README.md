# Claude Skills Collection

This repository is a skills-first collection for Claude. Every capability now lives in the canonical `.claude/skills/{name}/` format with a short `skill.md` entrypoint, linked references, and placeholder folders for scripts and templates.

## Repository Shape

- `.claude/skills/`: canonical skill directories
- `.claude/skills/SKILLS_REGISTRY.md`: catalog of all shipped skills
- `scripts/recommend_agents.sh`: standalone CLI that scans a project and installs recommended skill directories
- `data/agent_patterns.yaml`: detection rules used by the recommender

Each skill directory contains:

- `skill.md`: short entrypoint intended for automatic discovery
- `references/`: long-form guidance migrated out of the entrypoint
- `scripts/`: helper automation stubs or future utilities
- `assets/templates/`: reusable templates and assets
- `manifest.txt`: file list used by the installer to sync the full skill directory

## What Changed

- The legacy `.claude/agents/` surface is gone.
- All migrated content now lives under `.claude/skills/`.
- Former monolithic `SKILL.md` files were split so `skill.md` stays small and detailed material lives in `references/`.
- The repo no longer claims built-in MCP implementations.

## MCP Position

Some legacy guidance mentions MCP-backed workflows. This repository does not ship MCP servers or MCP tool implementations. If a skill references MCP, treat that as an external prerequisite that must already be configured in the user environment.

## Recommender Script

`scripts/recommend_agents.sh` is intentionally retained as a standalone CLI utility. It scans the current project, scores technology matches, and installs skill directories into `.claude/skills/`.

Common usage:

```bash
# Recommend skills without writing files
bash scripts/recommend_agents.sh --dry-run

# Install recommended skills into the current project
bash scripts/recommend_agents.sh

# Manually choose which detected skills to install
bash scripts/recommend_agents.sh --interactive

# Check whether installed skills have updates
bash scripts/recommend_agents.sh --check-updates

# Update all locally installed skills
bash scripts/recommend_agents.sh --update-all
```

The script remains a CLI by design. It is not promoted to MCP in this repository.

## Skill Inventory

The repo ships 38 skill directories:

- 31 migrated development and infrastructure specialists
- 7 existing commerce, design, social, and automation skills

Use the full catalog in [`.claude/skills/SKILLS_REGISTRY.md`](/Users/daryl/work/claude-agents/.claude/skills/SKILLS_REGISTRY.md) for names, descriptions, and use cases.

## Notable Skills

- `devops-orchestrator`: coordinates cloud, IaC, CI/CD, Kubernetes, and monitoring work
- `aws-specialist`, `azure-specialist`, `gcp-specialist`: cloud platform guidance
- `terraform-specialist`, `ansible-specialist`, `kubernetes-specialist`: infrastructure delivery
- `code-review-specialist`, `security-specialist`, `performance-specialist`: quality workflows
- `e-commerce-orchestrator`, `shopify-specialist`, `web-design-specialist`: commerce and conversion work
- `instagram-specialist`, `tiktok-strategist`, `social-media-specialist`, `zapier-specialist`: marketing and automation

## Using the Skills

1. Put the desired directories under `.claude/skills/` in your project.
2. Let Claude discover them from the `skill.md` descriptions, or explicitly point Claude at the relevant skill folder.
3. Use linked files in `references/` only when you need deeper detail.

The design goal is progressive disclosure: load the short entrypoint first, then only consult heavier references if the task needs them.

## Development Notes

- `skill.md` files should stay under 200 lines.
- New detail should go into `references/`, not back into the entrypoint.
- Empty `scripts/` and `assets/templates/` folders are preserved with `.gitkeep`.
- `manifest.txt` must stay current when files are added or removed from a skill directory.

## Testing

Run the repository test suite with:

```bash
bash tests/run_all_tests.sh
```

The tests cover detection logic, interactive selection, profile export/import, caching, and skill update flows.
