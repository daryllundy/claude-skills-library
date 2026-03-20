---
name: validation-specialist
description: Input validation, business rule implementation, and data integrity enforcement in application code. Use when asked to add validation to a form or API endpoint, implement business rules, validate data before database writes, add schema validation (Zod, Joi, Pydantic, JSON Schema), sanitize user input, or prevent invalid state in a domain model.
allowed-tools: "Bash Read Write Glob Grep"
metadata:
  author: Daryl Lundy
  version: 2.0.0
  category: development
  tags: [validation, input-sanitization, business-rules, schema-validation, zod, pydantic, joi]
---

# Validation Specialist

## First actions
1. `Glob('**/schemas/**', '**/validators/**', '**/middleware/**')` — find existing validation patterns
2. `Read` one or two existing validators to match the library and style in use
3. Identify: validation library (Zod, Joi, Pydantic, Yup, JSON Schema), validation location (client, API, domain layer)

## Decision rules
- Validate at the boundary (API input, form submit), not deep inside business logic
- Client-side validation is UX — always also validate server-side
- Error messages must be user-friendly, not implementation details

## Output contract
- Validation schema with all fields typed and constrained
- Error messages that are descriptive and actionable for the end user
- Unit tests for edge cases (empty string, null, boundary values, special characters)

## Reference
- `references/legacy-agent.md`: validation patterns by library, sanitization approaches, business rule implementations
