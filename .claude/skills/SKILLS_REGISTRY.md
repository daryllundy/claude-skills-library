# Claude Skills Registry

This registry contains 38 Claude skills in the canonical directory format.

## How to Use These Skills

Place the skill directories under `.claude/skills/`. Claude can discover them automatically when their descriptions match the task context.

The repository does not ship MCP servers. Any skill that depends on MCP or external integrations assumes those tools are already configured in the user environment.

## Available Skills

#### 1. ansible-specialist
- **Category**: Infrastructure (IaC)
- **Description**: Ansible playbooks, roles, inventory management, and configuration automation
- **Use for**: Ansible playbooks, role development, configuration management, dynamic inventory, Ansible Vault

#### 2. architecture-specialist
- **Category**: Business
- **Description**: System architecture, design patterns, architectural decisions
- **Use for**: Architecture design, pattern selection, system design

#### 3. aws-specialist
- **Category**: Infrastructure (Cloud)
- **Description**: AWS cloud services, architecture, CloudFormation, CDK, and AWS Well-Architected Framework
- **Use for**: AWS infrastructure, EC2, ECS, EKS, Lambda, RDS, S3, CloudWatch, IAM, VPC, cost optimization

#### 4. azure-specialist
- **Category**: Infrastructure (Cloud)
- **Description**: Azure cloud services, ARM templates, Bicep, and Azure best practices
- **Use for**: Azure infrastructure, VMs, App Service, Functions, AKS, SQL Database, Blob Storage, Azure Monitor, RBAC

#### 5. cicd-specialist
- **Category**: Infrastructure (Platform)
- **Description**: CI/CD pipelines for GitHub Actions, GitLab CI, Jenkins, CircleCI, and Azure DevOps
- **Use for**: Pipeline configuration, build automation, deployment strategies, artifact management, security scanning in CI/CD

#### 6. code-review-specialist
- **Category**: Quality
- **Description**: Automated code review, best practices, code quality analysis
- **Use for**: Code reviews, identifying issues, suggesting improvements

#### 7. compliance-specialist
- **Category**: Business
- **Description**: Regulatory compliance (GDPR, HIPAA, SOC2), audit trails
- **Use for**: Compliance requirements, audit logging, privacy features

#### 8. data-science-specialist
- **Category**: Specialized
- **Description**: ML pipelines, data analysis, visualization, model training
- **Use for**: Data analysis, ML models, data visualization, pipelines

#### 9. database-specialist
- **Category**: Development
- **Description**: Database design, schema optimization, query performance, and migrations
- **Use for**: Schema design, SQL queries, database migrations, indexing strategies

#### 10. debugging-specialist
- **Category**: Productivity
- **Description**: Bug detection, debugging assistance, error resolution
- **Use for**: Finding bugs, debugging issues, error analysis

#### 11. dependency-specialist
- **Category**: Operations
- **Description**: Dependency management, updates, security patches
- **Use for**: Managing dependencies, resolving conflicts, security updates

#### 12. devops-orchestrator
- **Category**: Infrastructure (Orchestration)
- **Description**: Coordinates DevOps specialists for complex infrastructure projects, multi-cloud deployments, and end-to-end infrastructure workflows
- **Use for**: Multi-specialist DevOps workflows, infrastructure planning, deployment coordination, orchestrating cloud + IaC + monitoring specialists

#### 13. docker-specialist
- **Category**: Infrastructure
- **Description**: Expert in Docker containerization, Dockerfile optimization, and container orchestration
- **Use for**: Creating Dockerfiles, optimizing containers, multi-stage builds, docker-compose configurations

#### 14. documentation-specialist
- **Category**: Productivity
- **Description**: Automated documentation generation, API docs, README files
- **Use for**: Generating documentation, writing guides, API documentation

#### 15. e-commerce-coordinator
- **Category**: Specialized
- **Description**: Coordinate multi-step e-commerce improvement programs across design, platform, marketing, and automation specialists
- **Use for**: Multi-week e-commerce transformations, sequencing specialist work, progress tracking, and roadmap coordination

#### 16. e-commerce-orchestrator
- **Category**: Commerce Orchestration
- **Description**: Comprehensive e-commerce website auditor and strategist that analyzes URLs, scores performance across 6 dimensions, coordinates specialist consultations, and guides interactive improvement workflows. Specializes in platform detection, conversion optimization, and orchestrating multi-specialist e-commerce transformations
- **Use for**: End-to-end e-commerce audits, platform detection, prioritized improvement roadmaps, and specialist routing.

#### 17. frontend-specialist
- **Category**: Development
- **Description**: Frontend development, UI/UX implementation, React, Vue, Angular
- **Use for**: Component development, state management, responsive design, accessibility

#### 18. gcp-specialist
- **Category**: Infrastructure (Cloud)
- **Description**: Google Cloud Platform services, Deployment Manager, and GCP architecture patterns
- **Use for**: GCP infrastructure, Compute Engine, Cloud Run, GKE, Cloud SQL, Cloud Storage, Cloud Monitoring, IAM

#### 19. git-specialist
- **Category**: Operations
- **Description**: Git workflow, branching strategies, repository management
- **Use for**: Git operations, merge conflicts, repository organization

#### 20. instagram-specialist
- **Category**: Marketing
- **Description**: Create Instagram marketing strategies, develop engaging Reels and Stories content, optimize for Instagram's algorithm, and build authentic brand communities. Specializes in visual storytelling, influencer partnerships, and turning followers into customers
- **Use for**: Instagram content strategy, Reels/Stories planning, influencer campaigns, and profile optimization.

#### 21. kubernetes-specialist
- **Category**: Infrastructure (Platform)
- **Description**: Kubernetes orchestration, Helm charts, service mesh, and cloud-native patterns
- **Use for**: Kubernetes manifests, Helm charts, deployments, services, ingress, ConfigMaps, Secrets, RBAC, auto-scaling

#### 22. localization-specialist
- **Category**: Business
- **Description**: Internationalization, localization, multi-language support
- **Use for**: i18n setup, translation management, locale handling

#### 23. migration-specialist
- **Category**: Operations
- **Description**: Database migrations, code migrations, version upgrades
- **Use for**: Migrating databases, upgrading frameworks, data transformations

#### 24. mobile-specialist
- **Category**: Development
- **Description**: iOS, Android, React Native, and Flutter development
- **Use for**: Mobile app development, native features, cross-platform solutions

#### 25. monitoring-specialist
- **Category**: Infrastructure (Platform)
- **Description**: Observability strategy, Prometheus, Grafana, ELK stack, distributed tracing, and alerting
- **Use for**: Monitoring setup, dashboard design, alerting strategies, SLO/SLI definitions, log aggregation, distributed tracing

#### 26. observability-specialist
- **Category**: Infrastructure
- **Description**: Monitoring, logging, alerting, and system observability implementation
- **Use for**: Setting up Prometheus, Grafana, ELK stack, application monitoring, instrumentation

#### 27. performance-specialist
- **Category**: Quality
- **Description**: Performance optimization, profiling, bottleneck identification
- **Use for**: Performance analysis, optimization, caching strategies

#### 28. refactoring-specialist
- **Category**: Quality
- **Description**: Code refactoring, modernization, technical debt reduction
- **Use for**: Refactoring code, improving structure, removing duplication

#### 29. scaffolding-specialist
- **Category**: Productivity
- **Description**: Project scaffolding, boilerplate generation, project setup
- **Use for**: Creating new projects, generating boilerplate, project structure

#### 30. security-specialist
- **Category**: Quality
- **Description**: Security auditing, vulnerability scanning, secure coding practices
- **Use for**: Security reviews, vulnerability fixes, secure authentication

#### 31. shopify-specialist
- **Category**: Commerce Platform
- **Description**: Build and optimize Shopify e-commerce stores, customize themes with Liquid, implement conversion optimization strategies, integrate apps and payment systems, and scale stores for maximum revenue. Specializes in turning Shopify stores into high-converting sales machines
- **Use for**: Shopify setup, Liquid theme work, conversion optimization, app integrations, and performance improvements.

#### 32. social-media-specialist
- **Category**: Marketing
- **Description**: Develop comprehensive multi-platform social media strategies, create engaging content, manage communities, run data-driven campaigns, and build authentic brand presence across all major social platforms. Specializes in turning social engagement into business results
- **Use for**: Cross-platform content strategy, channel planning, community growth, and social proof systems.

#### 33. terraform-specialist
- **Category**: Infrastructure (IaC)
- **Description**: Terraform configuration, modules, state management, and multi-cloud provisioning
- **Use for**: Terraform modules, state management, multi-cloud IaC, provider configuration, Terraform Cloud/Enterprise

#### 34. test-specialist
- **Category**: Quality
- **Description**: Comprehensive test suite generation, unit tests, integration tests
- **Use for**: Writing tests, test coverage, TDD, testing strategies

#### 35. tiktok-strategist
- **Category**: Marketing
- **Description**: Create TikTok marketing strategies, develop viral content ideas, plan TikTok campaigns, and optimize for TikTok's algorithm. Specializes in creating shareable moments and leveraging TikTok trends for app growth
- **Use for**: TikTok growth strategy, short-form video ideas, creator collaboration plans, and viral content experiments.

#### 36. validation-specialist
- **Category**: Business
- **Description**: Input validation, business rule implementation, data validation
- **Use for**: Adding validation, business logic, data integrity

#### 37. web-design-specialist
- **Category**: Design
- **Description**: Create modern, accessible, and conversion-optimized web designs. Expert in UX/UI best practices, responsive design, design systems, accessibility (WCAG), and designing for performance. Specializes in user-centered design that balances aesthetics with usability
- **Use for**: High-conversion web design direction, responsive UX, accessibility improvements, and design system guidance.

#### 38. zapier-specialist
- **Category**: Automation
- **Description**: Design and implement powerful workflow automations using Zapier, integrate 6000+ apps without code, optimize multi-step Zaps for reliability and performance, and automate business processes to save time and reduce errors. Specializes in turning repetitive tasks into automated workflows
- **Use for**: Workflow automation, SaaS integrations, lead routing, operational handoffs, and Zapier implementation planning.
