# Skill Detection Pattern Schema

## Overview

This document defines the YAML schema for skill detection pattern files. Pattern files enable declarative configuration of skill recommendation logic without modifying shell code.

## Schema Version

Current version: `1.0`

## File Structure

```yaml
version: "1.0"              # Required: Schema version string
category: "string"          # Optional: Category grouping for organizational purposes

agents:                     # Required: Array of skill definitions
  - name: "skill-name"      # Required: Unique skill identifier (kebab-case)
    description: "text"     # Optional: Human-readable skill description
    category: "text"        # Optional: Skill category for grouping
    patterns:               # Required: Array of detection patterns
      - type: "file"        # Required: Pattern type (file|path|content)
        match: "pattern"    # Required: Match criteria (string or regex)
        weight: 10          # Required: Importance weight (integer 0-25)
```

## Field Definitions

### Top-Level Fields

#### `version` (required)
- **Type**: String
- **Description**: Schema version for compatibility checking
- **Current Value**: `"1.0"`
- **Example**: `version: "1.0"`

#### `category` (optional)
- **Type**: String
- **Description**: Organizational category for the pattern file
- **Purpose**: Groups related agents together (e.g., "Infrastructure", "Development")
- **Example**: `category: "Infrastructure"`

#### `agents` (required)
- **Type**: Array
- **Description**: List of agent definitions with their detection patterns
- **Minimum**: 1 agent per file
- **Example**: See Agent Fields section below

### Agent Fields

#### `name` (required)
- **Type**: String
- **Format**: kebab-case (lowercase with hyphens)
- **Description**: Unique identifier for the agent
- **Must Match**: Agent markdown filename in `.claude/skills/`
- **Example**: `name: "terraform-specialist"`

#### `description` (optional)
- **Type**: String
- **Description**: Human-readable description of agent expertise
- **Purpose**: Documentation and UI display
- **Example**: `description: "Terraform configuration, modules, state management"`

#### `category` (optional)
- **Type**: String
- **Description**: Agent category for grouping in recommendations
- **Common Values**: 
  - "Infrastructure (Cloud)"
  - "Infrastructure (IaC)"
  - "Infrastructure (Platform)"
  - "Development (Frontend)"
  - "Development (Backend)"
  - "Quality (Testing)"
  - "Quality (Security)"
  - "Operations"
  - "Productivity"
  - "Business"
- **Example**: `category: "Infrastructure (IaC)"`

#### `patterns` (required)
- **Type**: Array
- **Description**: Detection patterns for identifying when this agent is relevant
- **Minimum**: 1 pattern per agent
- **Example**: See Pattern Fields section below

### Pattern Fields

#### `type` (required)
- **Type**: String (enum)
- **Valid Values**: `file`, `path`, `content`
- **Description**: Type of pattern matching to perform
- **Details**:
  - `file`: Match against file names and extensions
  - `path`: Match against directory names and paths
  - `content`: Match against file content (text search)

#### `match` (required)
- **Type**: String
- **Description**: Pattern to match against (format depends on type)
- **Formats**:
  - **file**: Glob patterns (e.g., `*.tf`, `package.json`, `Dockerfile`)
  - **path**: Directory names or path segments (e.g., `k8s`, `terraform`, `.aws`)
  - **content**: Text strings or regex patterns (e.g., `aws_`, `apiVersion`, `terraform`)
- **Case Sensitivity**: Depends on detection engine implementation
- **Examples**:
  - `match: "*.tf"` (file glob)
  - `match: "kubernetes"` (path segment)
  - `match: 'provider "aws"'` (content string)

#### `weight` (required)
- **Type**: Integer
- **Range**: 0-25
- **Description**: Importance/confidence score for this pattern match
- **Guidelines**:
  - **25**: Definitive indicator (e.g., `terraform.tfstate` for Terraform)
  - **20**: Strong primary indicator (e.g., `*.tf` files for Terraform)
  - **15**: Secondary indicator (e.g., `*.tfvars` for Terraform)
  - **10**: Weak/contextual indicator (e.g., word "terraform" in content)
  - **5**: Very weak indicator (use sparingly)

## Pattern Type Details

### File Patterns (`type: "file"`)

Match against file names and extensions using glob patterns.

**Supported Glob Patterns**:
- `*` - Match any characters (e.g., `*.tf` matches all Terraform files)
- `?` - Match single character
- Exact names (e.g., `Dockerfile`, `package.json`)

**Examples**:
```yaml
- type: "file"
  match: "*.tf"
  weight: 20

- type: "file"
  match: "package.json"
  weight: 15

- type: "file"
  match: "Dockerfile"
  weight: 15
```

**Best Practices**:
- Use higher weights for unique file names (e.g., `terraform.tfstate`)
- Use moderate weights for common extensions (e.g., `*.tf`)
- Consider false positives (e.g., `*.js` is very common)

### Path Patterns (`type: "path"`)

Match against directory names and path segments.

**Matching Behavior**:
- Matches directory names at any level
- Matches path segments (e.g., `k8s` matches `/project/k8s/deployment.yaml`)
- Case-sensitive by default

**Examples**:
```yaml
- type: "path"
  match: "k8s"
  weight: 20

- type: "path"
  match: "terraform"
  weight: 15

- type: "path"
  match: ".aws"
  weight: 10
```

**Best Practices**:
- Use specific directory names (e.g., `k8s`, `terraform`)
- Avoid overly generic names (e.g., `src`, `lib`)
- Consider hidden directories (e.g., `.aws`, `.github`)

### Content Patterns (`type: "content"`)

Match against text content within files.

**Matching Behavior**:
- Searches file content for text strings
- May support regex patterns (implementation-dependent)
- Case-sensitive by default

**Examples**:
```yaml
- type: "content"
  match: "aws_"
  weight: 15

- type: "content"
  match: 'provider "aws"'
  weight: 20

- type: "content"
  match: "apiVersion"
  weight: 10
```

**Best Practices**:
- Use specific technical terms (e.g., `aws_`, `apiVersion`)
- Use lower weights (content matching is less precise)
- Avoid common words (e.g., `test`, `config`)
- Quote strings with special characters

## Weight Guidelines

Weights determine the confidence score when a pattern matches. Use these guidelines:

### Weight 25: Definitive Indicators
Files or patterns that definitively identify a technology.

**Examples**:
- `terraform.tfstate` → Terraform
- `docker-compose.yml` → Docker
- `Chart.yaml` → Kubernetes/Helm

### Weight 20: Strong Primary Indicators
Primary file types or patterns strongly associated with a technology.

**Examples**:
- `*.tf` → Terraform
- `Dockerfile` → Docker
- `k8s/` directory → Kubernetes

### Weight 15: Secondary Indicators
Supporting files or patterns that reinforce primary indicators.

**Examples**:
- `*.tfvars` → Terraform
- `.dockerignore` → Docker
- `values.yaml` → Kubernetes/Helm

### Weight 10: Weak/Contextual Indicators
Patterns that suggest but don't confirm technology usage.

**Examples**:
- Word "terraform" in content
- `.aws/` directory
- Generic config files

### Weight 5: Very Weak Indicators
Use sparingly for very generic patterns.

**Examples**:
- Common keywords in comments
- Generic directory names

## Complete Example

```yaml
version: "1.0"
category: "Infrastructure"

agents:
  - name: "terraform-specialist"
    description: "Terraform configuration, modules, state management"
    category: "Infrastructure (IaC)"
    patterns:
      # Definitive indicator
      - type: "file"
        match: "terraform.tfstate"
        weight: 25
      
      # Strong primary indicators
      - type: "file"
        match: "*.tf"
        weight: 20
      
      - type: "path"
        match: "terraform"
        weight: 20
      
      # Secondary indicators
      - type: "file"
        match: "*.tfvars"
        weight: 15
      
      - type: "file"
        match: ".terraform.lock.hcl"
        weight: 15
      
      # Weak indicators
      - type: "content"
        match: "terraform"
        weight: 10
      
      - type: "path"
        match: ".terraform"
        weight: 10

  - name: "aws-specialist"
    description: "AWS cloud services, architecture, CloudFormation, CDK"
    category: "Infrastructure (Cloud)"
    patterns:
      # Strong indicators
      - type: "content"
        match: 'provider "aws"'
        weight: 20
      
      - type: "file"
        match: "cloudformation.yaml"
        weight: 20
      
      - type: "file"
        match: "cdk.json"
        weight: 20
      
      # Secondary indicators
      - type: "content"
        match: "aws_"
        weight: 15
      
      - type: "file"
        match: "*.template.json"
        weight: 15
      
      # Weak indicators
      - type: "path"
        match: ".aws"
        weight: 10
      
      - type: "file"
        match: "*.tf"
        weight: 10
```

## Validation Rules

Pattern files must pass these validation checks:

1. **Required Fields**: `version` and `agents` must be present
2. **Agent Requirements**: Each agent must have `name` and `patterns`
3. **Pattern Requirements**: Each pattern must have `type`, `match`, and `weight`
4. **Type Validation**: Pattern `type` must be one of: `file`, `path`, `content`
5. **Weight Range**: Pattern `weight` must be an integer between 0 and 25
6. **Name Format**: Agent `name` should use kebab-case
7. **Array Minimums**: At least 1 agent, at least 1 pattern per agent

## Best Practices

### Organization
- Group related agents in the same file (e.g., all cloud providers)
- Use descriptive file names (e.g., `infrastructure.yml`, `development.yml`)
- Keep files focused on a single category

### Pattern Design
- Start with definitive indicators (weight 20-25)
- Add supporting patterns (weight 10-15)
- Avoid overly generic patterns
- Test patterns against real projects

### Maintenance
- Document pattern rationale in comments
- Review weights periodically
- Update patterns based on false positives/negatives
- Version pattern files when making breaking changes

### Performance
- Limit content patterns (slower than file/path)
- Use specific match strings
- Avoid redundant patterns
- Consider pattern evaluation order

## Custom Pattern Files

Users can create custom pattern files to override defaults or add project-specific agents.

### Custom File Location
```bash
# Via environment variable
export SKILL_PATTERNS_DIR=/path/to/custom/patterns

# Via command-line flag
./scripts/recommend_skills.sh --patterns-dir=/path/to/custom/patterns
```

### Custom File Requirements
- Must follow the same schema
- Must pass validation
- Can override default agents by using same `name`
- Can add new agents not in defaults

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
```

## Migration from Hardcoded Patterns

To convert existing hardcoded patterns to YAML:

1. Identify agent name and category
2. Extract pattern matching logic
3. Convert to YAML format with appropriate types
4. Assign weights based on pattern importance
5. Validate YAML syntax and schema
6. Test against sample projects

## Schema Evolution

Future schema versions may add:
- Pattern negation (exclude patterns)
- Pattern combinations (AND/OR logic)
- Conditional patterns (if X then Y)
- Pattern priorities/ordering
- Regex flags and options
- Performance hints

Version changes will be documented and backward compatibility maintained where possible.
