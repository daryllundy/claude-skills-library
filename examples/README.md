# Claude Code Agents - Usage Examples

This directory contains real-world examples of using the specialized agents in Claude Code Pro.

## Quick Examples

### Example 1: Security Audit
```
"Use the security-specialist to perform a comprehensive security audit of the authentication system in src/auth/"
```

### Example 2: Create Dockerfile
```
"Use the docker-specialist to create a production-ready multi-stage Dockerfile for my Node.js Express application with health checks and non-root user"
```

### Example 3: Add Tests
```
"Use the test-specialist to create comprehensive unit and integration tests for the UserService class in src/services/user.service.ts"
```

## Multi-Agent Workflows

### Workflow 1: New API Endpoint

**Step 1 - Architecture**
```
"Use the architecture-specialist to design a RESTful API endpoint for user profile management with CRUD operations"
```

**Step 2 - Scaffolding**
```
"Use the scaffolding-specialist to create the file structure for the user profile API endpoint based on the architecture designed"
```

**Step 3 - Implementation**
```
"Use the database-specialist to implement the database schema and queries for the user profile feature"
```

**Step 4 - Testing**
```
"Use the test-specialist to create comprehensive tests for the user profile API endpoints"
```

**Step 5 - Security**
```
"Use the security-specialist to review the user profile API for security vulnerabilities"
```

**Step 6 - Documentation**
```
"Use the documentation-specialist to generate API documentation for the user profile endpoints"
```

### Workflow 2: Performance Optimization

**Step 1 - Analysis**
```
"Use the performance-specialist to analyze the application and identify performance bottlenecks"
```

**Step 2 - Database Optimization**
```
"Use the database-specialist to optimize the slow queries identified in the performance analysis"
```

**Step 3 - Caching**
```
"Use the performance-specialist to implement Redis caching for the frequently accessed data"
```

**Step 4 - Monitoring**
```
"Use the observability-specialist to add performance monitoring and alerting"
```

### Workflow 3: Production Deployment

**Step 1 - Containerization**
```
"Use the docker-specialist to create optimized Dockerfiles for all microservices"
```

**Step 2 - CI/CD**
```
"Use the devops-specialist to set up GitHub Actions workflow for automated testing and deployment"
```

**Step 3 - Security Hardening**
```
"Use the security-specialist to harden the Docker containers and deployment configuration"
```

**Step 4 - Observability**
```
"Use the observability-specialist to set up Prometheus monitoring and Grafana dashboards"
```

### Workflow 4: Code Modernization

**Step 1 - Review**
```
"Use the code-review-specialist to analyze the legacy codebase in src/legacy/ and identify areas for improvement"
```

**Step 2 - Refactoring Plan**
```
"Use the refactoring-specialist to create a refactoring plan for modernizing the code"
```

**Step 3 - Refactor**
```
"Use the refactoring-specialist to refactor the authentication module to use modern ES6+ features and async/await"
```

**Step 4 - Tests**
```
"Use the test-specialist to add tests for the refactored code to ensure no regression"
```

**Step 5 - Performance Check**
```
"Use the performance-specialist to verify that refactoring improved or maintained performance"
```

## Domain-Specific Examples

### Frontend Development
```
"Use the frontend-specialist to create a responsive dashboard component with React hooks and TypeScript"
```

### Mobile Development
```
"Use the mobile-specialist to implement biometric authentication in our React Native app"
```

### Database Work
```
"Use the database-specialist to design a normalized schema for an e-commerce platform with products, orders, and customers"
```

### DevOps
```
"Use the devops-specialist to create a GitLab CI/CD pipeline with staging and production environments"
```

### Data Science
```
"Use the data-science-specialist to create a customer churn prediction model using scikit-learn"
```

### Compliance
```
"Use the compliance-specialist to make our user data handling GDPR compliant"
```

### Localization
```
"Use the localization-specialist to add i18n support for English, Spanish, French, and German"
```

## Tips for Effective Agent Use

1. **Be Specific**: Include file paths, technologies, and requirements
2. **Provide Context**: Explain the current state and desired outcome
3. **Sequential Dependencies**: Run dependent tasks one at a time
4. **Review Output**: Always check agent work before proceeding
5. **Iterate**: Ask agents to refine their output if needed

## Advanced Patterns

### Pattern 1: Feature Flag Implementation
```
1. architecture-specialist → Design feature flag system
2. scaffolding-specialist → Create feature flag structure
3. database-specialist → Add feature flag storage
4. test-specialist → Test feature toggling
5. documentation-specialist → Document usage
```

### Pattern 2: Microservice Migration
```
1. architecture-specialist → Design microservice architecture
2. refactoring-specialist → Extract service from monolith
3. docker-specialist → Containerize the service
4. devops-specialist → Set up deployment pipeline
5. observability-specialist → Add monitoring
```

### Pattern 3: Security Hardening
```
1. security-specialist → Full security audit
2. security-specialist → Fix critical vulnerabilities
3. dependency-specialist → Update vulnerable packages
4. docker-specialist → Harden containers
5. compliance-specialist → Verify compliance
```

## Need More Help?

See the main documentation:
- [GETTING_STARTED.md](../GETTING_STARTED.md)
- [CLAUDE_CODE_USAGE.md](../CLAUDE_CODE_USAGE.md)
- [.claude/skills/SKILLS_REGISTRY.md](../.claude/skills/SKILLS_REGISTRY.md)
