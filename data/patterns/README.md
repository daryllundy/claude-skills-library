# Agent Detection Patterns

This directory contains YAML pattern files that define detection rules for agent recommendations.

## Purpose

Pattern files externalize detection logic from shell code into declarative YAML configuration, making it easier to:
- Maintain and update detection patterns
- Add new agents without modifying code
- Create custom patterns for specific use cases
- Version control pattern changes

## Files in This Directory

- **`SCHEMA.md`**: Complete schema documentation with validation rules and best practices
- **`example.yml`**: Comprehensive example demonstrating all supported fields and pattern types
- **`*.yml`**: Pattern files organized by category (to be created in future tasks)

## Pattern File Structure

Pattern files are organized by agent category:

- `infrastructure.yml` - Cloud, IaC, and Platform agents (AWS, Terraform, Kubernetes, etc.)
- `development.yml` - Frontend, Backend, Mobile, and Database agents
- `quality.yml` - Testing, Security, and Code Review agents
- `operations.yml` - Migration, Dependency, and Git agents
- `productivity.yml` - Scaffolding, Documentation, and Debugging agents
- `business.yml` - Validation, Architecture, Localization, and Compliance agents
- `specialized.yml` - Data Science and E-commerce agents

## Quick Reference

### YAML Schema

```yaml
version: "1.0"              # Required: Schema version
category: "Category Name"   # Optional: Organizational grouping

agents:                     # Required: Array of agents
  - name: "agent-name"      # Required: Agent identifier (kebab-case)
    description: "text"     # Optional: Human-readable description
    category: "text"        # Optional: Agent category
    patterns:               # Required: Detection patterns
      - type: "file"        # Required: file|path|content
        match: "*.ext"      # Required: Pattern to match
        weight: 20          # Required: Importance (0-25)
```

### Pattern Types

| Type | Description | Example |
|------|-------------|---------|
| `file` | Match file names/extensions (glob patterns) | `*.tf`, `Dockerfile`, `package.json` |
| `path` | Match directory names or path segments | `k8s`, `terraform`, `.aws` |
| `content` | Match text content within files | `aws_`, `apiVersion`, `FROM` |

### Weight Guidelines

| Weight | Level | Description | Example |
|--------|-------|-------------|---------|
| **25** | Definitive | Files that definitively identify a technology | `terraform.tfstate` |
| **20** | Strong Primary | Primary file types strongly associated | `*.tf`, `Dockerfile` |
| **15** | Secondary | Supporting files that reinforce primary | `*.tfvars`, `.dockerignore` |
| **10** | Weak/Contextual | Patterns that suggest but don't confirm | `terraform` in content |
| **5** | Very Weak | Generic patterns (use sparingly) | Common keywords |

## Usage

### Default Patterns

Pattern files are automatically loaded from this directory by the skill recommendation script:

```bash
./scripts/recommend_skills.sh
```

### Custom Patterns

Override default patterns or add project-specific agents:

```bash
# Via environment variable
export SKILL_PATTERNS_DIR=/path/to/custom/patterns
./scripts/recommend_skills.sh

# Via command-line flag
./scripts/recommend_skills.sh --patterns-dir=/path/to/custom/patterns
```

## Creating Custom Patterns

### Step-by-Step Guide

1. **Start with the example**
   ```bash
   cp data/patterns/example.yml my-patterns/custom.yml
   ```

2. **Define your agents**
   - Use kebab-case for agent names
   - Match names to agent files in `.claude/skills/`
   - Add clear descriptions

3. **Add detection patterns**
   - Start with definitive indicators (weight 20-25)
   - Add supporting patterns (weight 10-15)
   - Avoid overly generic patterns

4. **Validate syntax**
   ```bash
   # Check YAML syntax
   yq eval my-patterns/custom.yml
   # or
   python3 -c "import yaml; yaml.safe_load(open('my-patterns/custom.yml'))"
   ```

5. **Test against projects**
   ```bash
   cd /path/to/test/project
   SKILL_PATTERNS_DIR=/path/to/my-patterns ../scripts/recommend_skills.sh
   ```

6. **Refine weights**
   - Review recommendations
   - Adjust weights based on false positives/negatives
   - Test again

### Example Custom Pattern

```yaml
version: "1.0"
category: "Custom"

agents:
  - name: "internal-framework-specialist"
    description: "Company-specific framework expertise"
    category: "Development (Custom)"
    patterns:
      - type: "file"
        match: "framework.config.js"
        weight: 25
      
      - type: "path"
        match: "internal-lib"
        weight: 20
      
      - type: "content"
        match: "InternalFramework"
        weight: 15
```

## Pattern Design Best Practices

### Organization
- Group related agents in the same file
- Use descriptive file names (e.g., `infrastructure.yml`, `development.yml`)
- Keep files focused on a single category

### Pattern Selection
- **DO**: Use specific, unique identifiers
- **DO**: Start with high-confidence patterns
- **DO**: Test against real projects
- **DON'T**: Use overly generic patterns
- **DON'T**: Rely solely on content patterns (slower)
- **DON'T**: Create redundant patterns

### Weight Assignment
- **Higher weights** for unique, definitive files
- **Moderate weights** for common but specific patterns
- **Lower weights** for contextual or generic patterns
- **Test and adjust** based on real-world results

### Performance
- Limit content patterns (they're slower than file/path)
- Use specific match strings
- Avoid redundant patterns
- Consider evaluation order

## Validation

Pattern files must pass these checks:

✅ **Required Fields**
- Top-level: `version`, `agents`
- Agent: `name`, `patterns`
- Pattern: `type`, `match`, `weight`

✅ **Valid Values**
- `type`: Must be `file`, `path`, or `content`
- `weight`: Must be integer 0-25
- `name`: Should use kebab-case

✅ **Structure**
- At least 1 agent per file
- At least 1 pattern per agent

## Documentation

For complete documentation, see:
- **`SCHEMA.md`**: Full schema specification, field definitions, and validation rules
- **`example.yml`**: Working examples of all pattern types and features

## Support

For issues or questions:
1. Check `SCHEMA.md` for detailed documentation
2. Review `example.yml` for working examples
3. Validate YAML syntax with `yq` or Python
4. Test patterns against sample projects
5. Adjust weights based on results
