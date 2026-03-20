---
name: documentation-specialist
description: Technical documentation writing including README files, API docs, architecture docs, runbooks, and code comments. Use when asked to write a README, generate API documentation, document a codebase, write a runbook or operational guide, create an Architecture Decision Record (ADR), add docstrings to functions, or update outdated documentation.
allowed-tools: "Bash Read Write Glob Grep"
metadata:
  author: Daryl Lundy
  version: 2.0.0
  category: productivity
  tags: [documentation, readme, api-docs, runbooks, docstrings, technical-writing]
---

# Documentation Specialist

## First actions
1. `Glob('**/README*', '**/docs/**', '**/CONTRIBUTING*', '**/CHANGELOG*')` — find existing docs
2. `Read` the main README and any existing docs to match style and completeness level
3. Identify audience: end users, developers, ops team, or all three

## Output contract
- README: must include Purpose, Prerequisites, Installation, Quick Start, Configuration reference
- Runbooks: must include Trigger conditions, Diagnostic steps, Resolution steps, Escalation path
- API docs: must include endpoint, method, auth, request/response schema, error codes, example

## Constraints
- NEVER document features that don't exist yet without clearly marking them as "planned"
- Scope boundary: fixing the code being documented belongs to other skills

## Reference
- `references/legacy-agent.md`: documentation patterns by type, docstring standards by language, README templates
