# Claude Skills Registry

This registry contains 38 Claude skills in the canonical directory format.

## How to Use These Skills

Place the skill directories under `.claude/skills/`. Skills load automatically when their description matches the task context.

## Available Skills

#### 1. ansible-specialist
- **Category**: Infrastructure (IaC)
- **Description**: Ansible playbooks, roles, inventory, and configuration automation
- **Use for**: Writing playbooks, Ansible roles, dynamic inventory, Ansible Vault, fleet config management
- **Not for**: Cloud resource provisioning (use aws/azure/gcp-specialist); container builds (use docker-specialist)
- **Pairs with**: docker-specialist, kubernetes-specialist, cicd-specialist, terraform-specialist
- **Triggers on**: "write a playbook", "Ansible role", "configure servers", "Ansible Vault", "dynamic inventory", "fleet automation"

#### 2. architecture-specialist
- **Category**: Design
- **Description**: Software architecture, design patterns, and architectural decision-making
- **Use for**: System design, technology selection, ADRs, microservices vs monolith decisions, API design
- **Not for**: Writing implementation code; infrastructure provisioning
- **Pairs with**: database-specialist, security-specialist, performance-specialist
- **Triggers on**: "design the system", "architecture decision", "should I use microservices", "ADR", "system design", "how should I structure"

#### 3. aws-specialist
- **Category**: Infrastructure (Cloud)
- **Description**: AWS cloud infrastructure, services, CloudFormation, CDK, and Well-Architected Framework
- **Use for**: EC2, ECS, EKS, Lambda, RDS, S3, CloudWatch, IAM, VPC, cost optimization, AWS security
- **Not for**: Azure or GCP work; Terraform HCL writing (use terraform-specialist); application code
- **Pairs with**: terraform-specialist, docker-specialist, kubernetes-specialist, security-specialist
- **Triggers on**: "deploy to AWS", "set up EC2", "configure IAM", "Lambda function", "S3 bucket", "CloudFormation", "CDK", "AWS cost"

#### 4. azure-specialist
- **Category**: Infrastructure (Cloud)
- **Description**: Azure cloud services, ARM templates, Bicep, and Azure best practices
- **Use for**: Azure VMs, App Service, AKS, Functions, SQL Database, Blob Storage, Azure AD, RBAC
- **Not for**: AWS or GCP work; Terraform HCL writing (use terraform-specialist)
- **Pairs with**: terraform-specialist, docker-specialist, kubernetes-specialist
- **Triggers on**: "deploy to Azure", "ARM template", "Bicep", "AKS", "Azure Functions", "Azure AD"

#### 5. cicd-specialist
- **Category**: Infrastructure (Platform)
- **Description**: CI/CD pipelines for GitHub Actions, GitLab CI, Jenkins, CircleCI, and Azure DevOps
- **Use for**: Pipeline configuration, build automation, deployment strategies, security scanning in CI, artifact management
- **Not for**: Application build logic; infrastructure provisioning
- **Pairs with**: docker-specialist, kubernetes-specialist, terraform-specialist, security-specialist
- **Triggers on**: "set up a pipeline", "GitHub Actions", "GitLab CI", "deploy automatically", "CI/CD", "build and deploy", "fix the pipeline"

#### 6. code-review-specialist
- **Category**: Quality
- **Description**: Code review covering quality, security, performance, and best practices
- **Use for**: PR reviews, code audits, security-focused code review, identifying bugs and anti-patterns
- **Not for**: Architectural changes (use architecture-specialist); refactoring (use refactoring-specialist)
- **Pairs with**: security-specialist, refactoring-specialist, test-specialist
- **Triggers on**: "review this code", "audit this file", "check for issues", "code review", "find bugs"

#### 7. compliance-specialist
- **Category**: Business
- **Description**: GDPR, HIPAA, SOC 2, PCI-DSS compliance implementation and audit trail design
- **Use for**: Compliance gap assessment, audit logging, data retention, right-to-erasure implementation
- **Not for**: Legal interpretation; security hardening (use security-specialist)
- **Triggers on**: "GDPR compliance", "HIPAA controls", "SOC 2", "audit trail", "data retention", "right to be forgotten", "privacy policy implementation"

#### 8. data-science-specialist
- **Category**: Specialized
- **Description**: ML pipelines, data analysis, statistical modeling, and visualization
- **Use for**: ML models, data analysis, Jupyter notebooks, pandas/scikit-learn/PyTorch/TensorFlow
- **Not for**: Data infrastructure/pipelines at scale (use database-specialist or dedicated tooling)
- **Triggers on**: "build a model", "analyze this dataset", "machine learning", "pandas", "scikit-learn", "train a classifier", "visualize the data"

#### 9. database-specialist
- **Category**: Development
- **Description**: Database schema design, query optimization, indexing, and migrations
- **Use for**: Schema design, SQL queries, database migrations, indexing strategies, database selection
- **Not for**: Application-level ORM code; data science/ML pipelines
- **Pairs with**: architecture-specialist, performance-specialist, migration-specialist
- **Triggers on**: "design the schema", "optimize this query", "write a migration", "add an index", "slow query", "database design"

#### 10. debugging-specialist
- **Category**: Productivity
- **Description**: Systematic bug detection, root cause analysis, and error resolution
- **Use for**: Fixing errors, reading stack traces, diagnosing unexpected behavior, race conditions, memory leaks
- **Not for**: Architectural refactors; security vulnerability remediation
- **Triggers on**: "this is throwing an error", "why is this failing", "help me debug", "stack trace", "unexpected behavior", "race condition"

#### 11. dependency-specialist
- **Category**: Operations
- **Description**: Dependency management, version conflict resolution, and security patch updates
- **Use for**: Updating dependencies, resolving conflicts, security audits, Renovate/Dependabot setup
- **Not for**: Application code changes caused by breaking dependency updates
- **Triggers on**: "update dependencies", "version conflict", "npm audit", "vulnerable package", "dependency error", "Renovate", "Dependabot"

#### 12. devops-orchestrator
- **Category**: Orchestration
- **Description**: Coordinates multiple DevOps specialists for complex, multi-domain infrastructure projects
- **Use for**: Multi-domain projects, unclear specialist routing, phased infrastructure transformations
- **Not for**: Single-domain tasks (route directly to specialist instead)
- **Pairs with**: All DevOps specialists
- **Triggers on**: "set up our entire deployment pipeline", "migrate to Kubernetes", "build out the observability stack", "I'm not sure where to start with", "end-to-end infrastructure"

#### 13. docker-specialist
- **Category**: Infrastructure
- **Description**: Docker containerization, Dockerfile optimization, and Docker Compose configuration
- **Use for**: Writing Dockerfiles, multi-stage builds, reducing image size, Docker Compose, container security
- **Not for**: Kubernetes manifest writing (use kubernetes-specialist); cloud registry setup (use cloud specialist)
- **Pairs with**: kubernetes-specialist, cicd-specialist, aws-specialist
- **Triggers on**: "write a Dockerfile", "optimize my Docker image", "Docker Compose", "containerize this app", "reduce image size", "container health check"

#### 14. documentation-specialist
- **Category**: Productivity
- **Description**: Technical documentation — README files, API docs, runbooks, ADRs, docstrings
- **Use for**: Writing READMEs, API documentation, runbooks, docstrings, architecture docs
- **Not for**: Fixing the code being documented
- **Triggers on**: "write a README", "document this API", "add docstrings", "write a runbook", "generate documentation", "update the docs"

#### 15. e-commerce-coordinator
- **Category**: Orchestration
- **Description**: Coordinates multi-week e-commerce improvement programs across specialists
- **Use for**: Post-audit execution planning, sequencing specialist work, tracking e-commerce roadmap progress
- **Not for**: Initial audits (use e-commerce-orchestrator); individual platform work (use platform specialist directly)
- **Pairs with**: web-design-specialist, shopify-specialist, instagram-specialist, zapier-specialist
- **Triggers on**: "coordinate the e-commerce improvements", "sequence the work", "what specialist should I use next", "track the roadmap"

#### 16. e-commerce-orchestrator
- **Category**: Commerce Orchestration
- **Description**: E-commerce site auditor scoring performance across 6 dimensions with prioritized roadmaps
- **Use for**: Full e-commerce audits, platform detection, conversion analysis, improvement roadmaps
- **Not for**: Single-platform deep work (use shopify-specialist or web-design-specialist directly)
- **Triggers on**: "audit my store", "analyze [URL]", "assess my e-commerce site", "conversion optimization audit", "what's wrong with my store"

#### 17. frontend-specialist
- **Category**: Development
- **Description**: React, Vue, Angular, and TypeScript frontend development
- **Use for**: UI components, state management, accessibility, responsive design, Core Web Vitals
- **Not for**: Backend API design (use architecture-specialist); CI/CD (use cicd-specialist)
- **Triggers on**: "build a component", "React hook", "fix this CSS", "state management", "accessibility", "responsive layout", "TypeScript type"

#### 18. gcp-specialist
- **Category**: Infrastructure (Cloud)
- **Description**: GCP infrastructure, services, and architecture
- **Use for**: Compute Engine, Cloud Run, GKE, Cloud SQL, Cloud Storage, IAM, Cloud Monitoring
- **Not for**: AWS or Azure work; Terraform HCL writing (use terraform-specialist)
- **Triggers on**: "deploy to GCP", "Google Cloud", "Cloud Run", "GKE", "BigQuery", "gcloud", "GCP IAM"

#### 19. git-specialist
- **Category**: Operations
- **Description**: Git workflows, branching strategies, and conflict resolution
- **Use for**: Branching strategies, merge conflicts, git history cleanup, git hooks, monorepo git config
- **Not for**: CI/CD pipeline configuration (use cicd-specialist)
- **Triggers on**: "resolve this merge conflict", "git branching strategy", "rebase", "squash commits", "git history", ".gitignore", "git hooks"

#### 20. instagram-specialist
- **Category**: Marketing
- **Description**: Instagram marketing strategy, Reels, Stories, and Instagram Shopping
- **Use for**: Instagram growth, Reels content strategy, Shopping setup, influencer campaigns, profile audit
- **Not for**: Multi-platform strategy (use social-media-specialist); TikTok (use tiktok-strategist)
- **Triggers on**: "grow on Instagram", "Reels strategy", "Instagram Shopping", "Instagram content", "influencer outreach", "Instagram audit"

#### 21. kubernetes-specialist
- **Category**: Infrastructure (Platform)
- **Description**: Kubernetes manifests, Helm charts, auto-scaling, and cloud-native deployment patterns
- **Use for**: K8s YAML, Helm charts, HPA/VPA, ingress, RBAC, network policies, StatefulSets, cert-manager
- **Not for**: Cloud cluster provisioning (use cloud specialist); Docker image building (use docker-specialist)
- **Pairs with**: docker-specialist, cicd-specialist, monitoring-specialist
- **Triggers on**: "write a Kubernetes manifest", "Helm chart", "K8s deployment", "HPA", "ingress config", "RBAC", "pod failing", "Kubernetes secret"

#### 22. localization-specialist
- **Category**: Development
- **Description**: Internationalization and localization implementation
- **Use for**: i18n setup, translation file management, RTL support, locale-aware formatting
- **Triggers on**: "add multi-language support", "i18n", "l10n", "translation files", "RTL", "locale formatting", "internationalize"

#### 23. migration-specialist
- **Category**: Operations
- **Description**: Database migrations, framework upgrades, and data transformation
- **Use for**: Writing migrations, zero-downtime schema changes, framework version upgrades, data transformations
- **Not for**: Application code changes after migration (use relevant language skill)
- **Triggers on**: "write a migration", "upgrade to version X", "migrate the schema", "zero-downtime migration", "data transformation script", "breaking change upgrade"

#### 24. mobile-specialist
- **Category**: Development
- **Description**: iOS, Android, React Native, and Flutter mobile development
- **Use for**: Mobile screens/components, native device features, React Native/Flutter issues, mobile CI/CD
- **Triggers on**: "React Native", "Flutter", "mobile app", "iOS", "Android", "push notifications", "Expo", "mobile screen"

#### 25. monitoring-specialist
- **Category**: Infrastructure (Platform)
- **Description**: Prometheus, Grafana, ELK stack, distributed tracing, alerting, and SLO/SLI definition
- **Use for**: Monitoring setup, dashboard design, alert rules, SLO definition, Loki, Jaeger, runbooks
- **Not for**: Application instrumentation code (use observability-specialist)
- **Disambiguation**: Config files and dashboards → monitoring-specialist. App source code instrumentation → observability-specialist.
- **Pairs with**: observability-specialist, kubernetes-specialist, cicd-specialist
- **Triggers on**: "set up monitoring", "Grafana dashboard", "Prometheus alert", "SLO", "alerting rules", "log aggregation", "distributed tracing setup", "runbook"

#### 26. observability-specialist
- **Category**: Infrastructure
- **Description**: Application-level instrumentation — OpenTelemetry, structured logging, custom metrics
- **Use for**: Adding instrumentation to app code, OpenTelemetry SDK integration, structured logging setup, correlation IDs
- **Not for**: Infrastructure monitoring config (use monitoring-specialist)
- **Disambiguation**: App source code → observability-specialist. Config files and dashboards → monitoring-specialist.
- **Triggers on**: "add tracing to my app", "OpenTelemetry", "structured logging", "correlation IDs", "add metrics to the code", "instrument this service"

#### 27. performance-specialist
- **Category**: Quality
- **Description**: Performance analysis, profiling, optimization, and caching implementation
- **Use for**: Slow code analysis, query optimization, caching strategies, bundle size, Core Web Vitals, benchmarking
- **Not for**: Infrastructure scaling (use cloud specialist)
- **Triggers on**: "this is slow", "optimize performance", "profiling", "implement caching", "bundle size", "Core Web Vitals", "benchmark"

#### 28. refactoring-specialist
- **Category**: Quality
- **Description**: Code refactoring and technical debt reduction without changing external behavior
- **Use for**: Reducing duplication, applying SOLID, modernizing legacy code, extracting abstractions
- **Not for**: Adding new features while refactoring; performance optimization; security fixes
- **Triggers on**: "refactor this", "clean up this code", "too much duplication", "technical debt", "apply SOLID", "this is hard to read"

#### 29. scaffolding-specialist
- **Category**: Productivity
- **Description**: Project scaffolding, boilerplate generation, and new project setup
- **Use for**: New project creation, new service scaffolding in monorepo, standard project structure
- **Not for**: Detailed CI pipeline logic (use cicd-specialist); Docker setup (use docker-specialist)
- **Triggers on**: "start a new project", "scaffold a service", "generate boilerplate", "new microservice setup", "project template"

#### 30. security-specialist
- **Category**: Quality
- **Description**: Security auditing, vulnerability identification, and secrets management
- **Use for**: Code security review, IAM hardening, secrets management, OWASP Top 10, CVE remediation
- **Not for**: Cloud infrastructure changes (use cloud specialist); application feature code
- **Pairs with**: aws-specialist, compliance-specialist, code-review-specialist
- **Triggers on**: "security audit", "hardcoded secret", "OWASP", "CVE", "vulnerability", "IAM review", "secrets management", "authentication review"

#### 31. shopify-specialist
- **Category**: Commerce Platform
- **Description**: Shopify theme customization, Liquid, conversion optimization, and app integration
- **Use for**: Liquid theme work, product/checkout optimization, Shopify app setup, store speed
- **Not for**: Email marketing automation (use zapier-specialist); social media (use instagram-specialist)
- **Triggers on**: "Shopify theme", "Liquid template", "Shopify store", "checkout optimization", "Shopify app", "product page", "Shopify speed"

#### 32. social-media-specialist
- **Category**: Marketing
- **Description**: Cross-platform social media strategy and content planning
- **Use for**: Multi-platform strategy, content calendars, brand voice, community management
- **Not for**: Platform-specific deep tactics (use instagram-specialist or tiktok-strategist)
- **Triggers on**: "social media strategy", "content calendar", "cross-platform", "brand voice", "social media audit", "content pillars"

#### 33. terraform-specialist
- **Category**: Infrastructure (IaC)
- **Description**: Terraform configuration, modules, state management, and multi-cloud provisioning
- **Use for**: Terraform HCL writing, module development, state management, workspace strategy, import
- **Not for**: Cloud service selection (use cloud specialist for that context); application code
- **Pairs with**: aws-specialist, azure-specialist, gcp-specialist, cicd-specialist
- **Triggers on**: "write Terraform", "Terraform module", "terraform plan error", "manage Terraform state", "import infrastructure", "Terraform workspace"

#### 34. test-specialist
- **Category**: Quality
- **Description**: Test suite writing, coverage improvement, and testing strategy
- **Use for**: Unit tests, integration tests, E2E tests, TDD, fixing flaky tests, coverage improvement
- **Triggers on**: "write tests", "unit test", "integration test", "Playwright", "Cypress", "Jest", "pytest", "improve coverage", "flaky test", "TDD"

#### 35. tiktok-strategist
- **Category**: Marketing
- **Description**: TikTok content strategy, short-form video planning, and algorithm optimization
- **Use for**: TikTok growth, video scripts, trending sounds, creator collaboration, profile audits
- **Not for**: Multi-platform strategy (use social-media-specialist); Instagram (use instagram-specialist)
- **Triggers on**: "TikTok strategy", "TikTok content", "short-form video", "TikTok script", "grow on TikTok", "TikTok algorithm"

#### 36. validation-specialist
- **Category**: Development
- **Description**: Input validation, business rule implementation, and schema validation
- **Use for**: API input validation, form validation, Zod/Pydantic/Joi schemas, sanitization, business rules
- **Triggers on**: "add validation", "validate this input", "Zod schema", "Pydantic model", "business rules", "sanitize input", "form validation"

#### 37. web-design-specialist
- **Category**: Design
- **Description**: Modern, accessible, conversion-optimized web design direction and UX guidance
- **Use for**: Design audits, accessibility (WCAG), landing page conversion, design systems, UX feedback
- **Triggers on**: "improve the design", "accessibility audit", "WCAG", "conversion rate", "design system", "landing page design", "UX feedback", "mobile design"

#### 38. zapier-specialist
- **Category**: Automation
- **Description**: Zapier workflow automation design and SaaS integration planning
- **Use for**: Workflow automation, SaaS integrations, lead routing, order processing automation, Zap troubleshooting
- **Not for**: Custom code automation for complex logic (suggest Make or n8n instead)
- **Triggers on**: "automate this workflow", "Zapier", "connect these two tools", "lead routing", "order processing automation", "failing Zap", "multi-step automation"
