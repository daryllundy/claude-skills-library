# Confidence Score Calculation

This document explains how confidence scores are calculated for skill recommendations.

## Overview

Confidence scores indicate how well a project matches an agent's expertise area. Scores range from 0% to 100%, with higher scores indicating stronger matches.

## Formula

```
confidence = (accumulated_weight / max_possible_weight) × 100
```

Where:
- **accumulated_weight**: Sum of weights from matched patterns
- **max_possible_weight**: Sum of all pattern weights for the agent

## How It Works

Each agent has a set of detection patterns with associated weights:

- **file patterns**: Match file names or extensions (e.g., `*.tf`, `package.json`)
- **path patterns**: Match directory names (e.g., `terraform/`, `k8s/`)
- **content patterns**: Match text within files (e.g., `terraform`, `apiVersion`)

When the script scans your project:

1. It evaluates each pattern for the agent
2. If a pattern matches, its weight is added to the accumulated weight
3. The max possible weight is the sum of ALL pattern weights (matched or not)
4. The confidence is calculated as a percentage

## Example

Agent with patterns:
```
file:*.tf:20          (matches)
file:*.tfvars:15      (matches)
content:terraform:10  (no match)
path:.terraform:15    (no match)
```

Calculation:
- **Accumulated weight**: 20 + 15 = 35
- **Max possible weight**: 20 + 15 + 10 + 15 = 60
- **Confidence**: (35 / 60) × 100 = 58.33% ≈ 58%

## Interpretation

- **75-100%**: Highly recommended (strong match)
  - Multiple key indicators present
  - Agent is very likely to be useful

- **50-74%**: Recommended (moderate match)
  - Some key indicators present
  - Agent is likely to be useful

- **25-49%**: Suggested (weak match)
  - Few indicators present
  - Agent might be useful

- **0-24%**: Not recommended (insufficient match)
  - Very few or no indicators
  - Agent unlikely to be useful

## Why Dynamic Calculation?

Previously, the script used a fixed maximum weight of 100 for all agents. This caused problems:

- Agents with total weights < 100 could never reach 100% confidence
- Agents with total weights > 100 would saturate early
- Scores weren't comparable across agents

The new dynamic calculation ensures:
- ✓ Every agent can reach 100% confidence if all patterns match
- ✓ Scores are proportional to pattern coverage
- ✓ Scores are comparable across different agents
- ✓ More accurate representation of project-agent fit

## Debugging Confidence Scores

### Show Max Weights

See the maximum possible weight for all agents:

```bash
./scripts/recommend_skills.sh --show-max-weights
```

### Debug Specific Agent

See detailed calculation for a specific agent:

```bash
./scripts/recommend_skills.sh --debug-confidence terraform-specialist
```

This shows:
- Each pattern and whether it matched (✓/✗)
- Weight of each pattern
- Accumulated weight
- Max possible weight
- Final confidence percentage

### Debug All Agents

See detailed calculations for all agents:

```bash
./scripts/recommend_skills.sh --debug-confidence
```

## Pattern Weights

Pattern weights typically follow these guidelines:

- **25**: Strong indicator (e.g., `terraform.tfstate` for Terraform)
- **20**: Primary indicator (e.g., `*.tf` files for Terraform)
- **15**: Secondary indicator (e.g., `*.tfvars` for Terraform)
- **10**: Weak indicator (e.g., `terraform` in content)
- **5**: Very weak indicator (e.g., generic patterns)

Higher weights mean the pattern is more important for identifying the agent's use case.

## Troubleshooting

### Unexpected Low Scores

If an agent has unexpectedly low confidence:

1. Check what patterns the agent looks for:
   ```bash
   ./scripts/recommend_skills.sh --debug-confidence agent-name
   ```

2. Verify your project has the expected files/patterns

3. Check if patterns are too specific (e.g., exact file names vs. glob patterns)

### Unexpected High Scores

If an agent has unexpectedly high confidence:

1. Check which patterns matched:
   ```bash
   ./scripts/recommend_skills.sh --debug-confidence agent-name
   ```

2. Verify the patterns aren't too generic

3. Consider if the agent is actually relevant (high score might be correct!)

### All Scores Are Low

If all agents have low scores:

1. Check that you're running the script from your project root
2. Verify your project has recognizable technology indicators
3. Use `--verbose` to see detailed detection results
4. Consider that your project might be very new or use uncommon technologies

## Examples

### Terraform Project

```
Project structure:
├── main.tf
├── variables.tf
├── terraform.tfstate
└── modules/
    └── vpc/
        └── main.tf

Terraform Specialist Confidence:
- file:*.tf:20 → ✓ (multiple matches)
- file:terraform.tfstate:25 → ✓
- path:terraform:15 → ✗
- content:terraform:10 → ✓

Accumulated: 20 + 25 + 10 = 55
Max Possible: 20 + 25 + 15 + 10 = 70
Confidence: 78% (Highly Recommended)
```

### React Project

```
Project structure:
├── package.json (with "react": "^18.0.0")
├── src/
│   ├── components/
│   │   └── App.jsx
│   └── index.js
└── public/

Frontend Specialist Confidence:
- file:package.json:15 → ✓
- content:react:20 → ✓
- path:components:10 → ✓
- content:vue:15 → ✗
- content:angular:15 → ✗

Accumulated: 15 + 20 + 10 = 45
Max Possible: 15 + 20 + 10 + 15 + 15 = 75
Confidence: 60% (Recommended)
```

## See Also

- [Testing Documentation](TESTING_INTERACTIVE_MODE.md)
- [Main README](../README.md)
- [Getting Started Guide](../GETTING_STARTED.md)
