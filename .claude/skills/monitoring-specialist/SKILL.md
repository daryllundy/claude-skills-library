---
name: monitoring-specialist
description: Observability strategy, Prometheus and Grafana setup, ELK stack, distributed tracing, alerting, and SLO/SLI definition. Use when asked to set up monitoring, create a Grafana dashboard, write Prometheus alerting rules, define SLOs, configure Alertmanager routing, implement distributed tracing with Jaeger or Zipkin, set up centralized logging with Loki or Elasticsearch, or write an on-call runbook.
allowed-tools: "Bash Read Write Glob Grep"
metadata:
  author: Daryl Lundy
  version: 2.0.0
  category: infrastructure-platform
  tags: [monitoring, prometheus, grafana, alerting, slo, sli, elk, loki, tracing, observability]
---

# Monitoring Specialist

## First actions
1. `Glob('**/prometheus/**', '**/grafana/**', '**/alertmanager/**', '**/monitoring/**', '**/loki/**')` — find existing monitoring config
2. Read existing prometheus.yml and alert rules to understand current scrape targets and alert conventions
3. Identify monitoring stack: Prometheus+Grafana, ELK, Datadog, CloudWatch, or custom

## Decision rules
- Alert on symptoms (user-facing impact), not causes (disk space, CPU) — unless directly linked to user impact
- Every alert must have: `severity` label, `runbook_url` annotation, and `for:` duration to avoid flapping
- SLO alerts: use multi-window multi-burn-rate (1h + 6h for fast burn, 3d + 30d for slow burn)
- For new stacks: recommend Prometheus + Grafana + Loki + Tempo (open-source) unless a commercial tool is already in use

## Steps

### Step 1: Assess current observability coverage
Identify gaps: what metrics, logs, and traces are missing? What is the current alert coverage?

### Step 2: Design the solution
For each observability signal: metrics (Prometheus exporters), logs (structured JSON + Loki/Elasticsearch), traces (OpenTelemetry → Jaeger/Tempo).

### Step 3: Write configurations
Prometheus: scrape configs, recording rules, alert rules. Grafana: dashboard JSON with proper variables for multi-environment use. Alertmanager: routing tree with correct receiver grouping.

### Step 4: Validate
```bash
# Validate Prometheus config
promtool check config prometheus.yml
# Validate alert rules
promtool check rules alerts/*.yml
# Validate Grafana dashboard JSON (look for syntax errors)
python3 -m json.tool dashboard.json > /dev/null
