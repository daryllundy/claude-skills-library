#!/bin/bash
# Lint Dockerfiles using hadolint
# Usage: ./scripts/lint.sh [path-to-dockerfile]
# Install hadolint: https://github.com/hadolint/hadolint

DOCKERFILE="${1:-Dockerfile}"

echo "=== Dockerfile Lint ==="
echo "File: $DOCKERFILE"
echo ""

if [ ! -f "$DOCKERFILE" ]; then
  echo "ERROR: $DOCKERFILE not found"
  exit 1
fi

if command -v hadolint &> /dev/null; then
  hadolint "$DOCKERFILE"
  if [ $? -eq 0 ]; then
    echo "✓ No issues found"
  fi
else
  echo "hadolint not installed. Running basic checks..."
  echo ""
  
  # Check for latest tag
  if grep -n "FROM.*:latest" "$DOCKERFILE"; then
    echo "WARNING: Using 'latest' tag - pin to a specific version"
  fi
  
  # Check for root user
  if ! grep -q "USER" "$DOCKERFILE"; then
    echo "WARNING: No USER directive found - container may run as root"
  fi
  
  # Check for HEALTHCHECK
  if ! grep -q "HEALTHCHECK" "$DOCKERFILE"; then
    echo "WARNING: No HEALTHCHECK directive found"
  fi
  
  echo ""
  echo "Install hadolint for full linting: https://github.com/hadolint/hadolint"
fi
