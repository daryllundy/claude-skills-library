#!/usr/bin/env bash
set -euo pipefail

# Unit tests for recommender confidence behavior.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURES="$REPO_ROOT/tests/fixtures"
SCRIPT="$REPO_ROOT/scripts/recommend_agents.sh"
REPO_ARGS=(--repo "file://$REPO_ROOT" --branch "")

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

log_test() { echo -e "${YELLOW}[TEST]${NC} $1"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $1"; ((++TESTS_PASSED)); }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; ((++TESTS_FAILED)); }
run_test() { ((++TESTS_RUN)); log_test "$1"; }

test_empty_project_defaults() {
  run_test "Empty project should fall back to core recommendations"

  cd "$FIXTURES/empty-project"
  local output
  output=$(bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run 2>&1)

  if echo "$output" | grep -q "code-review-specialist" && \
     echo "$output" | grep -q "refactoring-specialist" && \
     echo "$output" | grep -q "test-specialist"; then
    log_pass "Core fallback recommendations are present"
  else
    log_fail "Core fallback recommendations are missing"
  fi
}

test_aws_terraform_fixture() {
  run_test "AWS + Terraform fixture should recommend infrastructure skills"

  cd "$FIXTURES/aws-terraform-project"
  local output
  output=$(bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run --min-confidence 10 2>&1)

  if echo "$output" | grep -q "terraform-specialist"; then
    log_pass "Terraform specialist detected for infrastructure fixture"
  else
    log_fail "Terraform specialist was not detected"
  fi

  if echo "$output" | grep -Eq "aws-specialist|devops-orchestrator"; then
    log_pass "Cloud-oriented recommendation also appeared"
  else
    log_fail "No cloud-oriented recommendation appeared"
  fi
}

test_threshold_filtering() {
  run_test "Higher confidence threshold should not increase recommendation count"

  cd "$FIXTURES/aws-terraform-project"
  local low_output high_output low_count high_count
  low_output=$(bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run --min-confidence 10 2>&1)
  high_output=$(bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run --min-confidence 60 2>&1)
  low_count=$(echo "$low_output" | grep -c "specialist\|orchestrator" || true)
  high_count=$(echo "$high_output" | grep -c "specialist\|orchestrator" || true)

  if [[ $low_count -ge $high_count ]]; then
    log_pass "Threshold filtering reduced or preserved the result count"
  else
    log_fail "Higher threshold unexpectedly increased recommendation count"
  fi
}

test_verbose_output_contains_detection_details() {
  run_test "Verbose mode should include detection details"

  cd "$FIXTURES/kubernetes-project"
  local output
  output=$(bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run --verbose --min-confidence 10 2>&1)

  if echo "$output" | grep -q "Matched Patterns:"; then
    log_pass "Verbose output includes matched-pattern details"
  else
    log_fail "Verbose output did not include matched-pattern details"
  fi
}

test_confidence_percentages_are_bounded() {
  run_test "Displayed confidence percentages should stay within 0-100"

  cd "$FIXTURES/react-frontend-project"
  local output bad_count
  output=$(bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run --min-confidence 0 2>&1)
  bad_count=$(echo "$output" | grep -Eo '[0-9]+%' | tr -d '%' | awk '$1 < 0 || $1 > 100 {count++} END {print count+0}')

  if [[ $bad_count -eq 0 ]]; then
    log_pass "All displayed confidence values are within bounds"
  else
    log_fail "Out-of-range confidence value detected"
  fi
}

echo "========================================="
echo "Confidence Scoring Unit Tests"
echo "========================================="
echo ""

test_empty_project_defaults
test_aws_terraform_fixture
test_threshold_filtering
test_verbose_output_contains_detection_details
test_confidence_percentages_are_bounded

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
