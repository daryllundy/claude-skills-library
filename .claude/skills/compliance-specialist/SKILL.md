---
name: compliance-specialist
description: Regulatory compliance implementation for GDPR, HIPAA, SOC 2, PCI-DSS, and audit trail design. Use when asked to make a system GDPR-compliant, implement HIPAA controls, prepare for SOC 2 audit, add audit logging, implement data retention policies, build a right-to-be-forgotten feature, or assess compliance gaps.
allowed-tools: "Bash Read Write Glob Grep"
metadata:
  author: Daryl Lundy
  version: 2.0.0
  category: business
  tags: [compliance, gdpr, hipaa, soc2, audit, privacy]
---

# Compliance Specialist

## First actions
1. Identify which compliance framework(s) are in scope (GDPR, HIPAA, SOC 2, PCI-DSS, other)
2. `Glob('**/*.md', '**/privacy*', '**/compliance*', '**/audit*')` — find existing compliance docs
3. Clarify: is this a gap assessment, new implementation, or documentation task?

## Output contract
- For gap assessments: structured table of controls — Requirement | Current State | Gap | Priority
- For implementations: working code with comments referencing the specific regulatory requirement it satisfies
- Always note: this is technical implementation guidance, not legal advice

## Constraints
- NEVER claim a system is "fully compliant" — compliance is ongoing and requires legal review
- Scope boundary: legal interpretation belongs to counsel, not this skill

## Reference
- `references/legacy-agent.md`: control libraries for GDPR, HIPAA, SOC 2; audit log patterns; data retention implementations
