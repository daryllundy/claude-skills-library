---
name: docker-specialist
description: Docker containerization, Dockerfile writing and optimization, multi-stage builds, and Docker Compose configuration for development and production. Use when asked to write a Dockerfile, optimize an existing Dockerfile, reduce image size, set up Docker Compose for a multi-service app, add health checks to a container, secure a container configuration, debug a Docker build error, or containerize an application before deploying it.
allowed-tools: "Bash Read Write Glob Grep"
metadata:
  author: Daryl Lundy
  version: 2.0.0
  category: infrastructure
  tags: [docker, containerization, dockerfile, docker-compose, multi-stage-builds, container-security]
---

# Docker Specialist

## First actions
1. `Glob('**/Dockerfile*', '**/docker-compose*.yml', '**/.dockerignore')` — find existing Docker files
2. `Read` any existing Dockerfile to understand current base image, layers, and patterns in use
3. Identify: application language/runtime, whether this is dev or production, target registry, and whether orchestration (Kubernetes, ECS) is the eventual destination

## Decision rules
- If the app has a build step (Node.js build, Go compile, etc.): use a multi-stage build — builder stage + minimal runtime stage
- Base image selection:
  - Python: `python:3.x-slim` (not full python:3.x)
  - Node.js: `node:lx-alpine` for prod, `node:lx` for dev
  - Go: compile to static binary → `FROM scratch` or `gcr.io/distroless/static`
  - General Linux: `debian:bookworm-slim` over `ubuntu` for size
- Always run as non-root: create a dedicated user with `useradd` or use `USER` directive
- If the image will go to Kubernetes: include SIGTERM handling and graceful shutdown
- If `.dockerignore` is missing: create it before writing the Dockerfile

## Steps

### Step 1: Assess the application
Identify: language, build tool, runtime dependencies, config/secrets approach, port(s) exposed, and health check endpoint if any.

### Step 2: Write .dockerignore
Exclude: `node_modules/`, `.git/`, `*.log`, `.env`, `dist/` (if built inside container), test files, local config.

### Step 3: Write the Dockerfile
Layer order for cache efficiency: base image → system dependencies → copy dependency manifests → install dependencies → copy source → build → final stage (if multi-stage) → USER → EXPOSE → HEALTHCHECK → CMD/ENTRYPOINT.

### Step 4: Write docker-compose.yml (if needed)
Include: named volumes for persistence, environment variable references (not hardcoded values), health check depends_on, named networks.

### Step 5: Validate
```bash
docker build -t test-image .
docker run --rm test-image echo "build ok"
# Check image size:
docker images test-image
# Check for root process:
docker run --rm test-image whoami  # should NOT be root
