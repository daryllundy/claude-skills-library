---
name: devops-orchestrator
description: Coordinates multiple DevOps specialist skills for complex infrastructure projects, multi-cloud deployments, and end-to-end infrastructure workflows. Use when a task spans multiple domains (e.g., "set up a full deployment pipeline", "migrate this app to Kubernetes on AWS", "build out our observability stack", "harden our infrastructure"), when you're unsure which specialist to use, or when a project needs phased planning across cloud + IaC + containers + CI/CD + monitoring.
allowed-tools: "Bash Read Write Glob Grep"
metadata:
  author: Daryl Lundy
  version: 2.0.0
  category: orchestration
  tags: [devops, orchestration, coordination, infrastructure, multi-specialist]
---

# DevOps Orchestrator

## First actions
1. `Glob('**/*.tf', '**/*.yml', '**/Dockerfile*', '**/.github/workflows/*.yml', '**/k8s/**')` — build a picture of what's already in place
2. Read any existing README or architecture docs
3. Decompose the request into domains: cloud provider, IaC, containerization, CI/CD, monitoring, security
4. State the decomposition and phase plan explicitly before doing any work

## Sub-agent roster
| Skill | Invoke when |
|---|---|
| aws-specialist | Cloud target is AWS; IAM, EC2, ECS, Lambda, S3, CloudWatch, VPC |
| azure-specialist | Cloud target is Azure |
| gcp-specialist | Cloud target is GCP |
| terraform-specialist | Infrastructure needs to be written or managed as Terraform IaC |
| ansible-specialist | Server configuration management; fleet automation; Ansible Vault |
| docker-specialist | Application needs containerization; Dockerfile or Compose work |
| kubernetes-specialist | Container orchestration at scale; Helm charts; cluster configuration |
| cicd-specialist | Build or deployment pipelines; GitHub Actions; GitLab CI |
| monitoring-specialist | Observability strategy; Prometheus; Grafana; alerting; SLOs |
| observability-specialist | Application instrumentation; OpenTelemetry; structured logging in code |
| security-specialist | Security audit; secrets management; IAM review; vulnerability remediation |
| git-specialist | Repository structure; branching strategy; git workflow |

## Decision rules
- If the task is clearly single-domain (e.g., "write a Dockerfile"): route directly to the specialist, do not orchestrate
- If the request is ambiguous about scope: clarify before decomposing
- If a specialist's phase reveals new requirements: surface them before proceeding to the next phase
- If two specialists conflict on approach: surface the trade-off to the user and get a decision

## Coordination protocol
1. Decompose the request into numbered phases. State phases and responsible specialists explicitly.
2. For each phase: identify the handoff artifact and success criteria before starting.
3. After each phase: validate output against success criteria before moving to the next phase.
4. Maintain this project state block throughout the session:
