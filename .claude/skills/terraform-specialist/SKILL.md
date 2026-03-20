---
name: terraform-specialist
description: Terraform configuration writing, module development, state management, and multi-cloud infrastructure provisioning. Use when asked to write Terraform code, create a reusable Terraform module, manage Terraform state (local, S3, Terraform Cloud), import existing infrastructure, set up workspaces for multi-environment management, or troubleshoot a Terraform plan or apply error.
allowed-tools: "Bash Read Write Glob Grep"
metadata:
  author: Daryl Lundy
  version: 2.0.0
  category: infrastructure-iac
  tags: [terraform, iac, infrastructure, modules, state, aws, azure, gcp, multi-cloud]
---

# Terraform Specialist

## First actions
1. `Glob('**/*.tf', '**/*.tfvars', '**/terraform.lock.hcl', '**/.terraform.lock.hcl')` — find existing Terraform code
2. `Read` main.tf, variables.tf, and backend configuration to understand current structure
3. Identify: provider(s), backend type (local, S3, Terraform Cloud), workspace strategy, Terraform version

## Decision rules
- Backend: never use local state for anything beyond local dev/testing — use remote backend (S3 + DynamoDB lock, or Terraform Cloud)
- Modules: write reusable modules for any resource pattern used more than once; one module per logical unit
- Variables: all variables need `description` and `type`; sensitive vars get `sensitive = true`
- For importing existing resources: use `terraform import` and generate the config; verify with `terraform plan` showing no changes
- If cloud-specific service knowledge is needed: use this skill for Terraform HCL; route service questions to aws/azure/gcp-specialist

## Steps

### Step 1: Read existing code
Understand provider versions, module structure, variable patterns, and naming conventions in use.

### Step 2: Write Terraform code
File structure: `main.tf` (resources), `variables.tf` (input vars), `outputs.tf` (output values), `versions.tf` (required_providers block).

### Step 3: Validate
```bash
terraform fmt -recursive
terraform validate
terraform plan
