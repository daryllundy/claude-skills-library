#!/bin/bash
# Lint Ansible playbooks and roles using ansible-lint
# Usage: ./scripts/lint.sh [path-to-playbook-or-role]

TARGET="${1:-.}"

echo "=== Ansible Lint ==="
echo "Target: $TARGET"
echo ""

if ! command -v ansible-lint &> /dev/null; then
  echo "ERROR: ansible-lint not found. Install with: pip install ansible-lint"
  exit 1
fi

ansible-lint "$TARGET"
if [ $? -eq 0 ]; then
  echo ""
  echo "✓ No issues found"
else
  echo ""
  echo "✗ Issues found — review above"
  exit 1
fi
