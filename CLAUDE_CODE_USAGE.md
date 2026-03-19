# Using These Skills in Claude

This repository is organized for Claude's skill loading model:

- `skill.md` is the light entrypoint
- `references/` holds the heavier material
- `scripts/` and `assets/templates/` are available for executable helpers and reusable assets

## Typical Flow

1. Install relevant directories into `.claude/skills/`.
2. Let Claude discover the right skill from the descriptions in `skill.md`.
3. If the task becomes detailed or specialized, follow the links into `references/`.

That structure keeps default context small while still preserving the long-form guidance that used to live in monolithic prompt files.

## Example Requests

```text
Review my Terraform module structure and suggest improvements.
```

Likely relevant skills:

- `terraform-specialist`
- `devops-orchestrator`
- `security-specialist`

```text
Analyze this Shopify storefront and tell me what to fix first.
```

Likely relevant skills:

- `e-commerce-orchestrator`
- `shopify-specialist`
- `web-design-specialist`

```text
Help me debug why this GitHub Actions pipeline fails after deployment.
```

Likely relevant skills:

- `cicd-specialist`
- `debugging-specialist`
- `observability-specialist`

## Recommender Script

Use the bundled CLI when you want automatic detection instead of manual copying:

```bash
bash scripts/recommend_agents.sh --dry-run
bash scripts/recommend_agents.sh --interactive
bash scripts/recommend_agents.sh --export profile.json
bash scripts/recommend_agents.sh --import profile.json
```

The script still keeps its historical filename, but it now installs skill directories under `.claude/skills/`.

## Registry and References

- Catalog: [`.claude/skills/SKILLS_REGISTRY.md`](/Users/daryl/work/claude-agents/.claude/skills/SKILLS_REGISTRY.md)
- Example entrypoint: [`.claude/skills/devops-orchestrator/skill.md`](/Users/daryl/work/claude-agents/.claude/skills/devops-orchestrator/skill.md)
- Example long-form reference: [`.claude/skills/devops-orchestrator/references/legacy-agent.md`](/Users/daryl/work/claude-agents/.claude/skills/devops-orchestrator/references/legacy-agent.md)

## MCP Clarification

Some reference files discuss MCP-enabled workflows because that language existed in the legacy source material. This repo does not bundle MCP servers. Use those workflows only when the required MCP integrations already exist in your environment.

## Authoring Guidance

- Keep `skill.md` concise and discovery-oriented.
- Move detailed rubrics, matrices, and templates into `references/` or `assets/templates/`.
- Update `manifest.txt` whenever a skill directory gains or loses files.
