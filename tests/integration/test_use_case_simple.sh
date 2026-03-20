#!/usr/bin/env bash
# Simplified test suite for use case metadata functionality
# Tasks 12-15: Verification tests

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
test_start() {
  local test_name="$1"
  echo -n "  $test_name ... "
  ((++TESTS_RUN))
}

test_pass() {
  echo -e "${GREEN}PASS${NC}"
  ((++TESTS_PASSED))
}

test_fail() {
  local reason="${1:-}"
  echo -e "${RED}FAIL${NC}"
  if [[ -n "$reason" ]]; then
    echo "    Reason: $reason"
  fi
  ((++TESTS_FAILED))
}

echo "================================"
echo "Use Case Metadata Test Suite"
echo "================================"
echo ""

# ============================================================================
# Task 12: Unit tests for formatting functions
# ============================================================================

echo -e "${BLUE}Task 12: Unit Tests for Formatting Functions${NC}"

test_start "format_use_case() exists"
if declare -F format_use_case >/dev/null 2>&1 || grep -q "^format_use_case()" scripts/recommend_skills.sh; then
  test_pass
else
  test_fail "Function not found"
fi

test_start "get_terminal_width() exists"
if declare -F get_terminal_width >/dev/null 2>&1 || grep -q "^get_terminal_width()" scripts/recommend_skills.sh; then
  test_pass
else
  test_fail "Function not found"
fi

test_start "format_use_case_auto() exists"
if declare -F format_use_case_auto >/dev/null 2>&1 || grep -q "^format_use_case_auto()" scripts/recommend_skills.sh; then
  test_pass
else
  test_fail "Function not found"
fi

test_start "get_use_case_safe() exists"
if declare -F get_use_case_safe >/dev/null 2>&1 || grep -q "^get_use_case_safe()" scripts/recommend_skills.sh; then
  test_pass
else
  test_fail "Function not found"
fi

test_start "format_use_case_cached() exists (Task 16)"
if declare -F format_use_case_cached >/dev/null 2>&1 || grep -q "^format_use_case_cached()" scripts/recommend_skills.sh; then
  test_pass
else
  test_fail "Function not found"
fi

test_start "USE_CASE_WRAP_CACHE declared (Task 16)"
if grep -q "^declare -A USE_CASE_WRAP_CACHE" scripts/recommend_skills.sh; then
  test_pass
else
  test_fail "Cache variable not declared"
fi

echo ""

# ============================================================================
# Task 13: Integration tests for CLI output
# ============================================================================

echo -e "${BLUE}Task 13: Integration Tests for CLI Output${NC}"

test_start "display_agent_details() uses use cases"
if grep -q "use_case.*get_use_case_safe" scripts/recommend_skills.sh; then
  test_pass
else
  test_fail "Function doesn't retrieve use cases"
fi

test_start "\"Use for:\" label in output"
if grep -q 'Use for:' scripts/recommend_skills.sh; then
  test_pass
else
  test_fail "Label not found in script"
fi

test_start "render_agent_item() accepts use_case parameter"
if grep -A 10 "^render_agent_item()" scripts/recommend_skills.sh | grep -q 'use_case.*6'; then
  test_pass
else
  test_fail "Function signature doesn't include use_case parameter"
fi

echo ""

# ============================================================================
# Task 14: Integration tests for JSON export
# ============================================================================

echo -e "${BLUE}Task 14: Integration Tests for JSON Export${NC}"

test_start "export_profile() includes use_case field"
if grep -A 60 "^export_profile()" scripts/recommend_skills.sh | grep -q 'use_case'; then
  test_pass
else
  test_fail "use_case field not found in export function"
fi

test_start "JSON escaping for use cases"
if grep -A 50 "^export_profile()" scripts/recommend_skills.sh | grep -q 'use_case_escaped'; then
  test_pass
else
  test_fail "Escaping not implemented"
fi

test_start "import_profile() function exists"
if declare -F import_profile >/dev/null 2>&1 || grep -q "^import_profile()" scripts/recommend_skills.sh; then
  test_pass
else
  test_fail "Function not found"
fi

echo ""

# ============================================================================
# Task 15: Integration tests for interactive mode
# ============================================================================

echo -e "${BLUE}Task 15: Integration Tests for Interactive Mode${NC}"

test_start "render_agent_list() passes use_cases_ref"
if grep -A 20 "^render_agent_list()" scripts/recommend_skills.sh | grep -q 'use_cases_ref'; then
  test_pass
else
  test_fail "use_cases_ref parameter not found"
fi

test_start "Use case displayed only for current agent"
if grep -A 30 "^render_agent_item()" scripts/recommend_skills.sh | grep -q 'is_current.*1'; then
  test_pass
else
  test_fail "Conditional display not implemented"
fi

test_start "Interactive mode retrieves use cases"
if grep -A 50 "^render_agent_list()" scripts/recommend_skills.sh | grep -q 'use_cases_ref\['; then
  test_pass
else
  test_fail "Use case retrieval not found"
fi

echo ""

# ============================================================================
# Additional: Use case validation tests
# ============================================================================

echo -e "${BLUE}Additional: Use Case Validation (Task 10)${NC}"

test_start "validate_use_cases() function exists"
if declare -F validate_use_cases >/dev/null 2>&1 || grep -q "^validate_use_cases()" scripts/recommend_skills.sh; then
  test_pass
else
  test_fail "Function not found"
fi

test_start "Validation checks AGENT_USE_CASES"
if grep -A 20 "^validate_use_cases()" scripts/recommend_skills.sh | grep -q 'AGENT_USE_CASES'; then
  test_pass
else
  test_fail "Function doesn't check use cases"
fi

echo ""

# ============================================================================
# Functional tests - verify actual behavior
# ============================================================================

echo -e "${BLUE}Functional Tests: Verify Implementation${NC}"

test_start "Script runs without errors"
if ./scripts/recommend_skills.sh --dry-run >/dev/null 2>&1; then
  test_pass
else
  test_fail "Script execution failed"
fi

test_start "Use cases display in actual output"
if ./scripts/recommend_skills.sh --dry-run 2>&1 | grep -q "Use for:"; then
  test_pass
else
  test_fail "Use cases not found in output"
fi

test_start "Pattern loading includes use cases"
if ./scripts/recommend_skills.sh --dry-run 2>&1 | head -20 | grep -q "Loaded.*skill.*patterns"; then
  test_pass
else
  test_fail "Pattern loading output not found"
fi

echo ""

# Summary
echo "================================"
echo "Test Results"
echo "================================"
echo "Total tests run: $TESTS_RUN"
echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
if [[ $TESTS_FAILED -gt 0 ]]; then
  echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
  exit 1
else
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi
