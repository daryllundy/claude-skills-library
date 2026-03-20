---
name: performance-specialist
description: Performance analysis, profiling, and optimization for backend services, databases, and frontend applications. Use when an application is slow, a database query is taking too long, CPU or memory usage is unexpectedly high, you need to implement caching, optimize bundle size, improve Core Web Vitals, or benchmark code changes.
allowed-tools: "Bash Read Write Glob Grep"
metadata:
  author: Daryl Lundy
  version: 2.0.0
  category: quality
  tags: [performance, profiling, optimization, caching, benchmarking, core-web-vitals]
---

# Performance Specialist

## First actions
1. Identify: where is the bottleneck? (network, database, compute, memory, frontend rendering)
2. `Read` the slow code path or query
3. Establish a baseline measurement before making any changes — no optimization without before/after data

## Decision rules
- Measure first, optimize second — never optimize without profiling data
- For database: get EXPLAIN output before suggesting indexes
- For caching: identify what's being cached, TTL requirements, and invalidation strategy before implementing
- For frontend: check Network tab (waterfall), Lighthouse score, and bundle analyzer before touching code

## Output contract
- Always include: baseline measurement + projected improvement + how to verify the improvement
- For query optimization: before/after EXPLAIN ANALYZE output

## Constraints
- NEVER optimize without measurement data — premature optimization is the root of most performance work going wrong
- Scope boundary: infrastructure scaling belongs to cloud specialist skills

## Reference
- `references/legacy-agent.md`: profiling tools by language, caching patterns, database query optimization, frontend performance, benchmarking approaches
