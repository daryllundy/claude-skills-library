#!/usr/bin/env bash

# Bash wrapper for expect-based interactive tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if expect is available
if ! command -v expect &> /dev/null; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "SKIP: Interactive tests require 'expect' to be installed"
  echo ""
  echo "To install expect:"
  echo "  macOS:   brew install expect"
  echo "  Ubuntu:  sudo apt-get install expect"
  echo "  Fedora:  sudo dnf install expect"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi

echo "Running interactive mode tests..."
echo ""

# Track test results
total_tests=0
passed_tests=0
failed_tests=0
failed_test_names=()

# Run all expect test scripts
for test_file in "$SCRIPT_DIR"/*.exp; do
  if [[ -f "$test_file" ]]; then
    test_name=$(basename "$test_file" .exp)
    ((++total_tests))
    
    echo "Running $test_name..."
    
    if expect "$test_file" > /dev/null 2>&1; then
      echo "  ✓ PASS"
      ((++passed_tests))
    else
      echo "  ✗ FAIL"
      ((++failed_tests))
      failed_test_names+=("$test_name")
    fi
    echo ""
  fi
done

# Print summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Interactive Test Summary:"
echo "  Total:  $total_tests"
echo "  Passed: $passed_tests"
echo "  Failed: $failed_tests"

if [[ $failed_tests -gt 0 ]]; then
  echo ""
  echo "Failed tests:"
  for test_name in "${failed_test_names[@]}"; do
    echo "  - $test_name"
  done
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $failed_tests -eq 0 ]]; then
  echo "✓ All interactive tests passed!"
  exit 0
else
  echo "✗ Some interactive tests failed"
  exit 1
fi
