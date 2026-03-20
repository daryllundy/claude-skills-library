#!/bin/bash
# Validate Terraform configuration
# Usage: ./scripts/validate.sh [path-to-terraform-dir]

TF_DIR="${1:-.}"

echo "=== Terraform Validation ==="
echo "Directory: $TF_DIR"
echo ""

# Check Terraform is installed
if ! command -v terraform &> /dev/null; then
  echo "ERROR: terraform not found in PATH"
  exit 1
fi

cd "$TF_DIR" || exit 1

# Format check
echo "--- Format check ---"
if terraform fmt -check -recursive; then
  echo "✓ Format OK"
else
  echo "✗ Format issues found. Run: terraform fmt -recursive"
  exit 1
fi

# Validate
echo ""
echo "--- Validate ---"
terraform init -backend=false -input=false > /dev/null 2>&1
if terraform validate; then
  echo "✓ Validate OK"
else
  echo "✗ Validation failed"
  exit 1
fi

echo ""
echo "=== All checks passed ==="
