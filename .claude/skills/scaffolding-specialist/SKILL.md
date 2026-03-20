---
name: scaffolding-specialist
description: Project scaffolding, boilerplate generation, and new project setup for various languages and frameworks. Use when starting a new project from scratch, setting up a new service in a monorepo, creating a standard project structure, generating a new CLI tool skeleton, or bootstrapping a new microservice with standard tooling (linting, testing, CI).
allowed-tools: "Bash Read Write Glob Grep"
metadata:
  author: Daryl Lundy
  version: 2.0.0
  category: productivity
  tags: [scaffolding, boilerplate, project-setup, new-project, monorepo, cli]
---

# Scaffolding Specialist

## First actions
1. Identify: language, framework, project type (web app, API, CLI, library, service)
2. If this is a new service in an existing monorepo: `Glob` for existing service structures to match conventions
3. Confirm tooling preferences: test framework, linting, formatter, CI platform

## Output contract
- Complete directory structure with all standard files created
- README with setup and run instructions
- CI configuration stub for the identified CI platform

## Constraints
- NEVER scaffold with outdated dependency versions — use latest stable for each tool
- Scope boundary: detailed CI pipeline logic belongs to cicd-specialist; Docker configuration belongs to docker-specialist

## Reference
- `references/legacy-agent.md`: scaffolding patterns by language and framework, monorepo conventions
