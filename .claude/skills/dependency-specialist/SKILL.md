---
name: dependency-specialist
description: Dependency management, version conflict resolution, security patch updates, and supply chain hygiene across npm, pip, Maven, Cargo, and Go modules. Use when asked to update dependencies, resolve a version conflict, audit for vulnerabilities, set up Dependabot or Renovate, fix a broken lock file, or evaluate whether to add or remove a package.
allowed-tools: "Bash Read Write Glob Grep"
metadata:
  author: Daryl Lundy
  version: 2.0.0
  category: operations
  tags: [dependencies, npm, pip, maven, cargo, go-modules, renovate, dependabot, security]
---

# Dependency Specialist

## First actions
1. `Glob('**/package.json', '**/requirements.txt', '**/Pipfile', '**/go.mod', '**/Cargo.toml', '**/pom.xml', '**/build.gradle')` — identify package manager(s) in use
2. `Read` the manifest file and lock file (package-lock.json, Pipfile.lock, go.sum, etc.)
3. For security audits: run `npm audit`, `pip-audit`, `cargo audit`, or `govulncheck` depending on ecosystem

## Decision rules
- For security vulnerabilities: fix CRITICAL and HIGH first; document MEDIUM/LOW for backlog
- For major version updates: check changelog for breaking changes before upgrading; update one major dependency at a time
- If a lock file is missing: generate it before making any other changes
- For supply chain: prefer packages with active maintenance (recent commits, responsive maintainers)

## Output contract
- For security audits: structured table — Package | Version | CVE | Severity | Fix Version | Status
- For updates: exact commands to run; note any breaking changes that require code changes

## Constraints
- NEVER update all dependencies in one commit — update in batches by severity or ecosystem
- Scope boundary: fixing breaking changes in application code after a dependency update belongs to the relevant language/framework skill

## Reference
- `references/legacy-agent.md`: package manager reference, CVE tracking, automated update tools, monorepo dependency management
