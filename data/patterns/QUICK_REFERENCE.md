# Pattern Schema Quick Reference

## Minimal Valid Pattern File

```yaml
version: "1.0"
agents:
  - name: "agent-name"
    patterns:
      - type: "file"
        match: "*.ext"
        weight: 10
```

## Pattern Types

### File Patterns
```yaml
- type: "file"
  match: "*.tf"           # Glob pattern
  weight: 20
```
- Matches file names and extensions
- Supports glob patterns (`*`, `?`)
- Examples: `*.tf`, `Dockerfile`, `package.json`

### Path Patterns
```yaml
- type: "path"
  match: "k8s"            # Directory name
  weight: 20
```
- Matches directory names and path segments
- Case-sensitive
- Examples: `k8s`, `terraform`, `.aws`

### Content Patterns
```yaml
- type: "content"
  match: "aws_"           # Text string
  weight: 15
```
- Matches text within files
- May support regex (implementation-dependent)
- Examples: `aws_`, `apiVersion`, `FROM`

## Weight Scale

| Weight | Level | Use For |
|--------|-------|---------|
| 25 | Definitive | `terraform.tfstate`, `docker-compose.yml` |
| 20 | Strong Primary | `*.tf`, `Dockerfile`, `Chart.yaml` |
| 15 | Secondary | `*.tfvars`, `.dockerignore`, `values.yaml` |
| 10 | Weak/Contextual | `terraform` in content, `.aws` directory |
| 5 | Very Weak | Generic keywords (use sparingly) |

## Common Patterns

### Infrastructure as Code
```yaml
# Terraform
- type: "file"
  match: "*.tf"
  weight: 20

# CloudFormation
- type: "file"
  match: "cloudformation.yaml"
  weight: 20

# Kubernetes
- type: "file"
  match: "Chart.yaml"
  weight: 20
```

### Containers
```yaml
# Docker
- type: "file"
  match: "Dockerfile"
  weight: 25

- type: "file"
  match: "docker-compose.yml"
  weight: 25
```

### Frontend Development
```yaml
# React
- type: "file"
  match: "*.jsx"
  weight: 20

- type: "content"
  match: "import React"
  weight: 15

# Vue
- type: "file"
  match: "*.vue"
  weight: 20
```

### Testing
```yaml
# Test files
- type: "file"
  match: "*.test.js"
  weight: 15

# Test directories
- type: "path"
  match: "__tests__"
  weight: 15

# Test frameworks
- type: "file"
  match: "jest.config.js"
  weight: 20
```

## Field Reference

### Required Fields
- `version` (top-level)
- `agents` (top-level)
- `name` (agent)
- `patterns` (agent)
- `type` (pattern)
- `match` (pattern)
- `weight` (pattern)

### Optional Fields
- `category` (top-level)
- `description` (agent)
- `category` (agent)

## Validation Checklist

- [ ] `version` field present and set to `"1.0"`
- [ ] `agents` array present with at least 1 agent
- [ ] Each agent has `name` field (kebab-case)
- [ ] Each agent has `patterns` array with at least 1 pattern
- [ ] Each pattern has `type` field (`file`, `path`, or `content`)
- [ ] Each pattern has `match` field (non-empty string)
- [ ] Each pattern has `weight` field (integer 0-25)
- [ ] YAML syntax is valid

## Usage Examples

### Load Default Patterns
```bash
./scripts/recommend_skills.sh
```

### Load Custom Patterns
```bash
# Environment variable
export SKILL_PATTERNS_DIR=/path/to/patterns
./scripts/recommend_skills.sh

# Command-line flag
./scripts/recommend_skills.sh --patterns-dir=/path/to/patterns
```

### Validate YAML Syntax
```bash
# Using yq
yq eval pattern.yml

# Using Python
python3 -c "import yaml; yaml.safe_load(open('pattern.yml'))"
```

## Common Mistakes

❌ **Wrong pattern type**
```yaml
- type: "filename"  # Invalid - must be file, path, or content
```

❌ **Missing required fields**
```yaml
- type: "file"
  match: "*.tf"
  # Missing weight field
```

❌ **Weight out of range**
```yaml
- type: "file"
  match: "*.tf"
  weight: 30  # Invalid - must be 0-25
```

❌ **Generic patterns with high weights**
```yaml
- type: "content"
  match: "test"  # Too generic
  weight: 25     # Too high for generic pattern
```

✅ **Correct patterns**
```yaml
- type: "file"
  match: "*.tf"
  weight: 20

- type: "path"
  match: "terraform"
  weight: 15

- type: "content"
  match: "terraform"
  weight: 10
```

## See Also

- `SCHEMA.md` - Complete schema documentation
- `example.yml` - Working examples with all features
- `README.md` - Usage guide and best practices
