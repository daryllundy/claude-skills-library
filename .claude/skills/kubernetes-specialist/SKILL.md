---
name: kubernetes-specialist
description: Kubernetes manifest writing, Helm chart development, cluster configuration, auto-scaling, and cloud-native deployment patterns. Use when asked to write Kubernetes YAML, create a Helm chart, set up HPA or VPA, configure ingress, write RBAC policies, implement network policies, set up cert-manager, debug a failing pod, configure persistent storage, or deploy to EKS/AKS/GKE.
allowed-tools: "Bash Read Write Glob Grep"
metadata:
  author: Daryl Lundy
  version: 2.0.0
  category: infrastructure-platform
  tags: [kubernetes, k8s, helm, eks, aks, gke, hpa, rbac, ingress, kustomize]
---

# Kubernetes Specialist

## First actions
1. `Glob('**/k8s/**', '**/charts/**', '**/kustomize/**', '**/helmfile.yaml')` — find existing manifests
2. `Read` existing Deployments or Helm values to understand current resource patterns
3. Identify: cluster type (EKS/AKS/GKE/local), Kubernetes version, ingress controller in use, whether Helm or Kustomize is the IaC approach

## Decision rules
- All containers must have `resources.requests` and `resources.limits` defined — never leave them unset in production
- All Deployments must have liveness and readiness probes
- For secrets: never put plaintext secrets in manifests — use Sealed Secrets, External Secrets Operator, or cloud-native secret injection
- For ingress: match the existing ingress controller (NGINX, Traefik, etc.) in the cluster
- If Helm chart already exists: extend via values override, do not fork the chart

## Steps

### Step 1: Read existing manifests
Understand naming conventions, label schemas, namespace structure, and resource patterns.

### Step 2: Write manifests
Follow label conventions: `app.kubernetes.io/name`, `app.kubernetes.io/version`, `app.kubernetes.io/component`. Set resource requests conservatively; set limits generously (avoid OOMKill).

### Step 3: Validate
```bash
kubectl apply --dry-run=client -f manifests/
# For Helm:
helm lint charts/myapp/
helm template charts/myapp/ | kubectl apply --dry-run=client -f -
