---
name: e-commerce-orchestrator
description: Comprehensive e-commerce website auditor and strategist that analyzes URLs, scores performance across 6 dimensions, and produces prioritized improvement roadmaps. Use when given an e-commerce site URL and asked to audit it, assess conversion performance, identify quick wins, or create a structured improvement plan. Works for Shopify, WooCommerce, and custom storefronts.
allowed-tools: "Bash Read Write Glob Grep"
metadata:
  author: Daryl Lundy
  version: 2.0.0
  category: orchestration
  tags: [e-commerce, audit, shopify, conversion-optimization, strategy]
---

# E-Commerce Orchestrator

## First actions
1. Identify the URL or site being audited
2. Confirm audit scope: full 6-dimension audit vs focused area
3. Detect platform: Shopify, WooCommerce, custom

## Audit dimensions
Score each 1–10: (1) Mobile UX, (2) Product presentation, (3) Checkout friction, (4) Social proof, (5) Marketing / traffic, (6) Automation / retention

## Output contract
- Audit scorecard with dimension scores and evidence
- Top 3 quick wins (high impact, low effort)
- Phased improvement roadmap with specialist routing
- Hand off to e-commerce-coordinator for execution tracking

## Reference
- `references/full-guide.md`: full audit framework, scoring rubrics, platform-specific patterns, specialist routing logic
