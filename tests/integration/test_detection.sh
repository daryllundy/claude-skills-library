#!/usr/bin/env bash
set -euo pipefail

# Integration tests for end-to-end skill recommendations.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/recommend_skills.sh"
FIXTURES="$REPO_ROOT/tests/fixtures"
REPO_ARGS=(--repo "file://$REPO_ROOT" --branch "")

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

cleanup() {
  rm -f /tmp/test-detection-*.json
}

trap cleanup EXIT

log_test() { echo -e "${YELLOW}[TEST]${NC} $1"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $1"; ((++TESTS_PASSED)); }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; ((++TESTS_FAILED)); }
run_test() { ((++TESTS_RUN)); log_test "$1"; }

test_aws_terraform_detection() {
  run_test "AWS + Terraform project should detect infrastructure recommendations"

  cd "$FIXTURES/aws-terraform-project"
  local output
  output=$(bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run --min-confidence 10 2>&1)

  if echo "$output" | grep -q "terraform-specialist"; then
    log_pass "Detected terraform-specialist"
  else
    log_fail "Failed to detect terraform-specialist"
  fi
}

test_react_frontend_detection() {
  run_test "React frontend project should detect frontend recommendations"

  cd "$FIXTURES/react-frontend-project"
  local output
  output=$(bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run --min-confidence 10 2>&1)

  if echo "$output" | grep -Eq "frontend-specialist|test-specialist"; then
    log_pass "Detected frontend-oriented recommendations"
  else
    log_fail "Frontend-oriented recommendations missing"
  fi
}

test_kubernetes_detection() {
  run_test "Kubernetes project should detect kubernetes recommendations"

  cd "$FIXTURES/kubernetes-project"
  local output
  output=$(bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run --min-confidence 10 2>&1)

  if echo "$output" | grep -q "kubernetes-specialist"; then
    log_pass "Detected kubernetes-specialist"
  else
    log_fail "Expected kubernetes recommendation was missing"
  fi
}

test_multicloud_detection() {
  run_test "Multi-cloud project should detect multiple infrastructure recommendations"

  cd "$FIXTURES/multi-cloud-project"
  local output
  output=$(bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run --min-confidence 10 2>&1)

  if echo "$output" | grep -Eq "aws-specialist|terraform-specialist|observability-specialist|devops-orchestrator"; then
    log_pass "Detected multi-cloud infrastructure recommendations"
  else
    log_fail "Multi-cloud infrastructure recommendations missing"
  fi
}

test_empty_project_fallback() {
  run_test "Empty project should recommend core skills"

  cd "$FIXTURES/empty-project"
  local output
  output=$(bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run 2>&1)

  if echo "$output" | grep -q "code-review-specialist" && \
     echo "$output" | grep -q "refactoring-specialist" && \
     echo "$output" | grep -q "test-specialist"; then
    log_pass "Core skills recommended for empty project"
  else
    log_fail "Core recommendations missing for empty project"
  fi
}

test_export_json() {
  run_test "Export functionality should create valid JSON"

  cd "$FIXTURES/react-frontend-project"
  local export_file="/tmp/test-detection-$$.json"
  bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run --export "$export_file" --min-confidence 10 >/dev/null 2>&1

  if [[ -f "$export_file" ]] && command -v jq >/dev/null 2>&1 && jq empty "$export_file" >/dev/null 2>&1; then
    log_pass "Export created valid JSON"
  else
    log_fail "Export did not create valid JSON"
  fi
}

test_invalid_threshold() {
  run_test "Invalid confidence threshold should return an error"

  cd "$FIXTURES/react-frontend-project"
  local output
  output=$(bash "$SCRIPT" "${REPO_ARGS[@]}" --min-confidence 150 2>&1 || true)
  if echo "$output" | grep -q "must be a number between 0 and 100"; then
    log_pass "Invalid threshold was rejected"
  else
    log_fail "Invalid threshold was not rejected"
  fi
}

echo "========================================="
echo "Skill Recommendation Integration Tests"
echo "========================================="
echo ""

test_aws_terraform_detection
test_react_frontend_detection
test_kubernetes_detection
test_multicloud_detection
test_empty_project_fallback
test_export_json
test_invalid_threshold

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
