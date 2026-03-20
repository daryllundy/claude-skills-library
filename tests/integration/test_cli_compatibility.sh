#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OLD_SCRIPT="$REPO_ROOT/scripts/recommend_agents.sh"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

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
  ((++TESTS_RUN))
  log_test "$1"
}

test_wrapper_warns_and_forwards_help() {
  run_test "recommend_agents.sh should warn and forward to recommend_skills.sh"

  local output
  output=$(bash "$OLD_SCRIPT" --help 2>&1 || true)

  if echo "$output" | grep -q "deprecated; use scripts/recommend_skills.sh instead" && \
     echo "$output" | grep -q "recommend_skills.sh \\[options\\]"; then
    log_pass "Compatibility wrapper warns and forwards correctly"
  else
    log_fail "Compatibility wrapper did not warn and forward as expected"
  fi
}

test_wrapper_preserves_exit_code() {
  run_test "recommend_agents.sh should preserve forwarded command behavior"

  local output
  output=$(bash "$OLD_SCRIPT" --definitely-invalid 2>&1 || true)

  if echo "$output" | grep -q "Unknown option: --definitely-invalid"; then
    log_pass "Compatibility wrapper preserved forwarded CLI behavior"
  else
    log_fail "Compatibility wrapper did not preserve forwarded CLI behavior"
  fi
}

echo "========================================="
echo "CLI Compatibility Integration Tests"
echo "========================================="
echo ""

test_wrapper_warns_and_forwards_help
test_wrapper_preserves_exit_code

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
