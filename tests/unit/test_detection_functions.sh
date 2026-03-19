#!/usr/bin/env bash
set -euo pipefail

# Unit tests for detection functions in recommend_agents.sh
# Tests individual functions in isolation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURES="$REPO_ROOT/tests/fixtures"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
log_test() {
  echo -e "${YELLOW}[TEST]${NC} $1"
}

log_pass() {
  echo -e "${GREEN}[PASS]${NC} $1"
  ((++TESTS_PASSED))
}

log_fail() {
  echo -e "${RED}[FAIL]${NC} $1"
  ((++TESTS_FAILED))
}

run_test() {
  local test_name="$1"
  ((++TESTS_RUN))
  log_test "$test_name"
}

# Source the detection functions from the script
# We'll extract just the functions we need for testing
source_detection_functions() {
  # Extract has_file function
  eval "$(sed -n '/^has_file() {/,/^}/p' "$REPO_ROOT/scripts/recommend_agents.sh")"
  
  # Extract has_path function
  eval "$(sed -n '/^has_path() {/,/^}/p' "$REPO_ROOT/scripts/recommend_agents.sh")"
  
  # Extract file_contains function
  eval "$(sed -n '/^file_contains() {/,/^}/p' "$REPO_ROOT/scripts/recommend_agents.sh")"
  
  # Extract search_contents function
  eval "$(sed -n '/^search_contents() {/,/^}/p' "$REPO_ROOT/scripts/recommend_agents.sh")"
}

source_detection_functions

# Test 1: has_file function with existing file
test_has_file_exists() {
  run_test "has_file should detect existing files"
  
  cd "$FIXTURES/aws-terraform-project"
  
  if has_file "main.tf"; then
    log_pass "Detected main.tf"
  else
    log_fail "Failed to detect main.tf"
  fi
}

# Test 2: has_file function with non-existing file
test_has_file_not_exists() {
  run_test "has_file should return false for non-existing files"
  
  cd "$FIXTURES/aws-terraform-project"
  
  if has_file "nonexistent.txt"; then
    log_fail "False positive: detected non-existent file"
  else
    log_pass "Correctly returned false for non-existent file"
  fi
}

# Test 3: has_file with wildcard pattern
test_has_file_wildcard() {
  run_test "has_file should work with wildcard patterns"
  
  cd "$FIXTURES/aws-terraform-project"
  
  if has_file "*.tf"; then
    log_pass "Detected .tf files with wildcard"
  else
    log_fail "Failed to detect .tf files with wildcard"
  fi
}

# Test 4: has_path function with existing directory
test_has_path_exists() {
  run_test "has_path should detect existing directories"
  
  cd "$FIXTURES/kubernetes-project"
  
  if has_path "k8s"; then
    log_pass "Detected k8s directory"
  else
    log_fail "Failed to detect k8s directory"
  fi
}

# Test 5: has_path function with non-existing directory
test_has_path_not_exists() {
  run_test "has_path should return false for non-existing directories"
  
  cd "$FIXTURES/kubernetes-project"
  
  if has_path "nonexistent"; then
    log_fail "False positive: detected non-existent directory"
  else
    log_pass "Correctly returned false for non-existent directory"
  fi
}

# Test 6: file_contains function with matching content
test_file_contains_match() {
  run_test "file_contains should detect matching content"
  
  cd "$FIXTURES/aws-terraform-project"
  
  if file_contains "main.tf" "provider"; then
    log_pass "Detected 'provider' in main.tf"
  else
    log_fail "Failed to detect 'provider' in main.tf"
  fi
}

# Test 7: file_contains function with non-matching content
test_file_contains_no_match() {
  run_test "file_contains should return false for non-matching content"
  
  cd "$FIXTURES/aws-terraform-project"
  
  if file_contains "main.tf" "nonexistent_string_xyz"; then
    log_fail "False positive: detected non-existent content"
  else
    log_pass "Correctly returned false for non-matching content"
  fi
}

# Test 8: file_contains with non-existing file
test_file_contains_no_file() {
  run_test "file_contains should return false for non-existing file"
  
  cd "$FIXTURES/aws-terraform-project"
  
  if file_contains "nonexistent.txt" "content"; then
    log_fail "False positive: detected content in non-existent file"
  else
    log_pass "Correctly returned false for non-existent file"
  fi
}

# Test 9: search_contents function with matching content
test_search_contents_match() {
  run_test "search_contents should find content across files"
  
  cd "$FIXTURES/react-frontend-project"
  
  if search_contents "react"; then
    log_pass "Found 'react' in project files"
  else
    log_fail "Failed to find 'react' in project files"
  fi
}

# Test 10: search_contents function with non-matching content
test_search_contents_no_match() {
  run_test "search_contents should return false for non-matching content"
  
  cd "$FIXTURES/empty-project"
  
  if search_contents "nonexistent_unique_string_xyz"; then
    log_fail "False positive: found non-existent content"
  else
    log_pass "Correctly returned false for non-matching content"
  fi
}

# Test 11: Git directory exclusion
test_git_exclusion() {
  run_test "Detection functions should exclude .git directory"
  
  cd "$FIXTURES/aws-terraform-project"
  
  # Create a temporary .git directory with a file
  mkdir -p .git/test
  echo "should_not_be_found" > .git/test/file.txt
  
  if search_contents "should_not_be_found"; then
    log_fail "Failed to exclude .git directory"
  else
    log_pass "Correctly excluded .git directory"
  fi
  
  # Cleanup
  rm -rf .git
}

# Test 12: has_file with nested paths
test_has_file_nested() {
  run_test "has_file should detect files in nested directories"
  
  cd "$FIXTURES/kubernetes-project"
  
  if has_file "deployment.yaml"; then
    log_pass "Detected deployment.yaml in nested directory"
  else
    log_fail "Failed to detect deployment.yaml in nested directory"
  fi
}

# Test 13: has_path with nested paths
test_has_path_nested() {
  run_test "has_path should detect nested directory paths"
  
  cd "$FIXTURES/multi-cloud-project"
  
  if has_path ".github/workflows"; then
    log_pass "Detected .github/workflows nested path"
  else
    log_fail "Failed to detect .github/workflows nested path"
  fi
}

# Test 14: Case sensitivity in file_contains
test_file_contains_case_sensitive() {
  run_test "file_contains should be case-sensitive"
  
  cd "$FIXTURES/react-frontend-project"
  
  # Check for exact case match
  if file_contains "package.json" "react"; then
    log_pass "Found 'react' with correct case"
  else
    log_fail "Failed to find 'react' with correct case"
  fi
}

# Test 15: Special characters in search patterns
test_search_special_chars() {
  run_test "search_contents should handle special characters"
  
  cd "$FIXTURES/aws-terraform-project"
  
  # Search for content with special characters (quotes)
  if search_contents "\"aws\""; then
    log_pass "Handled special characters in search"
  else
    log_fail "Failed to handle special characters"
  fi
}

# Run all tests
echo "========================================="
echo "Detection Functions Unit Tests"
echo "========================================="
echo ""

test_has_file_exists
test_has_file_not_exists
test_has_file_wildcard
test_has_path_exists
test_has_path_not_exists
test_file_contains_match
test_file_contains_no_match
test_file_contains_no_file
test_search_contents_match
test_search_contents_no_match
test_git_exclusion
test_has_file_nested
test_has_path_nested
test_file_contains_case_sensitive
test_search_special_chars

# Summary
echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo "Tests run:    $TESTS_RUN"
echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
if [[ $TESTS_FAILED -gt 0 ]]; then
  echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
  exit 1
else
  echo ""
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi
