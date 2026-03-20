#!/bin/bash
# Validate Kubernetes manifests using kubectl dry-run
# Usage: ./scripts/validate.sh [path-to-manifests-dir]

MANIFESTS_DIR="${1:-k8s}"

echo "=== Kubernetes Manifest Validation ==="
echo "Directory: $MANIFESTS_DIR"
echo ""

if ! command -v kubectl &> /dev/null; then
  echo "ERROR: kubectl not found in PATH"
  exit 1
fi

ERRORS=0

# Find all YAML files
find "$MANIFESTS_DIR" -name "*.yaml" -o -name "*.yml" | while read -r manifest; do
  echo "Validating: $manifest"
  if kubectl apply --dry-run=client -f "$manifest" > /dev/null 2>&1; then
    echo "  ✓ OK"
  else
    echo "  ✗ FAILED:"
    kubectl apply --dry-run=client -f "$manifest" 2>&1 | sed 's/^/    /'
    ERRORS=$((ERRORS + 1))
  fi
done

echo ""
if [ $ERRORS -eq 0 ]; then
  echo "=== All manifests valid ==="
else
  echo "=== $ERRORS manifest(s) failed validation ==="
  exit 1
fi
