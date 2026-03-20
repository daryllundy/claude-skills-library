#!/usr/bin/env bash
# Unit tests for pattern loading functions
# Task 13: Create unit tests for pattern loading

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Source the main script functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "${REPO_ROOT}/scripts/recommend_skills.sh" 2>/dev/null || true

# Override log function for tests
log() {
  echo "$@" >&2
}

# Test helper functions
test_start() {
  local test_name="$1"
  echo -n "Testing: $test_name ... "
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
    echo "  Reason: $reason"
  fi
  ((++TESTS_FAILED))
}

# Create test directory
TEST_DIR=$(mktemp -d)
cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Test 1: parse_yaml() with valid YAML input
test_parse_yaml_valid() {
  test_start "parse_yaml() with valid YAML input"

  local yaml_file="${TEST_DIR}/valid.yml"
  cat > "$yaml_file" <<'EOF'
version: "1.0"
agents:
  - name: "test-agent"
    description: "Test agent"
    patterns:
      - type: "file"
        match: "test.txt"
        weight: 10
EOF

  local json_output
  if json_output=$(parse_yaml "$yaml_file" 2>&1); then
    if echo "$json_output" | jq -e '.version == "1.0"' &> /dev/null; then
      test_pass
    else
      test_fail "JSON output doesn't contain expected version"
    fi
  else
    test_fail "parse_yaml failed"
  fi
}

# Test 2: validate_pattern_schema() with valid schema
test_validate_schema_valid() {
  test_start "validate_pattern_schema() with valid schema"

  local json_data='{
    "version": "1.0",
    "agents": [
      {
        "name": "test-agent",
        "patterns": [
          {
            "type": "file",
            "match": "test.txt",
            "weight": 10
          }
        ]
      }
    ]
  }'

  if validate_pattern_schema "$json_data" 2>/dev/null; then
    test_pass
  else
    test_fail "validate_pattern_schema rejected valid schema"
  fi
}

# Test 3: validate_pattern_schema() rejecting missing version
test_validate_schema_missing_version() {
  test_start "validate_pattern_schema() rejecting missing version"

  local json_data='{
    "agents": [
      {
        "name": "test-agent",
        "patterns": []
      }
    ]
  }'

  if validate_pattern_schema "$json_data" 2>/dev/null; then
    test_fail "validate_pattern_schema accepted schema without version"
  else
    test_pass
  fi
}

# Test 4: validate_pattern_schema() rejecting invalid pattern type
test_validate_schema_invalid_type() {
  test_start "validate_pattern_schema() rejecting invalid pattern type"

  local json_data='{
    "version": "1.0",
    "agents": [
      {
        "name": "test-agent",
        "patterns": [
          {
            "type": "invalid_type",
            "match": "test.txt",
            "weight": 10
          }
        ]
      }
    ]
  }'

  if validate_pattern_schema "$json_data" 2>/dev/null; then
    test_fail "validate_pattern_schema accepted invalid pattern type"
  else
    test_pass
  fi
}

# Test 5: load_pattern_file() populating data structures correctly
test_load_pattern_file() {
  test_start "load_pattern_file() populating data structures correctly"

  # Clear any existing patterns
  AGENT_PATTERNS=()
  AGENT_DESCRIPTIONS=()
  AGENT_CATEGORIES=()

  local yaml_file="${TEST_DIR}/test_pattern.yml"
  cat > "$yaml_file" <<'EOF'
version: "1.0"
agents:
  - name: "test-agent"
    description: "Test agent description"
    category: "Test Category"
    patterns:
      - type: "file"
        match: "test.txt"
        weight: 10
      - type: "path"
        match: "testdir"
        weight: 5
EOF

  if load_pattern_file "$yaml_file" 2>/dev/null; then
    # Check if patterns were populated
    if [[ -n "${AGENT_PATTERNS[test-agent]:-}" ]]; then
      # Check if description was populated
      if [[ "${AGENT_DESCRIPTIONS[test-agent]:-}" == "Test agent description" ]]; then
        # Check if category was populated
        if [[ "${AGENT_CATEGORIES[test-agent]:-}" == "Test Category" ]]; then
          # Check if patterns contain expected entries
          if echo "${AGENT_PATTERNS[test-agent]}" | grep -q "file:test.txt:10"; then
            test_pass
          else
            test_fail "Patterns don't contain expected entries"
          fi
        else
          test_fail "Category not populated correctly"
        fi
      else
        test_fail "Description not populated correctly"
      fi
    else
      test_fail "Patterns not populated"
    fi
  else
    test_fail "load_pattern_file failed"
  fi
}

# Test 6: Error handling with malformed YAML
test_malformed_yaml() {
  test_start "Error handling with malformed YAML"

  local yaml_file="${TEST_DIR}/malformed.yml"
  cat > "$yaml_file" <<'EOF'
version: "1.0"
agents:
  - name: "test-agent"
    patterns:
      - type: "file
        match: "test.txt"
        weight: 10
EOF

  if parse_yaml "$yaml_file" 2>/dev/null; then
    test_fail "parse_yaml accepted malformed YAML"
  else
    test_pass
  fi
}

# Test 7: discover_pattern_files() finding files
test_discover_pattern_files() {
  test_start "discover_pattern_files() finding pattern files"

  local patterns_dir="${TEST_DIR}/patterns"
  mkdir -p "$patterns_dir"

  # Create test pattern files
  touch "${patterns_dir}/test1.yml"
  touch "${patterns_dir}/test2.yaml"
  touch "${patterns_dir}/test3.txt"  # Should not be discovered

  local files
  files=$(discover_pattern_files "$patterns_dir" 2>/dev/null)

  local file_count
  file_count=$(echo "$files" | wc -l | xargs)

  if [[ "$file_count" -eq 2 ]]; then
    test_pass
  else
    test_fail "Expected 2 files, found $file_count"
  fi
}

# Test 8: check_dependencies()
test_check_dependencies() {
  test_start "check_dependencies() verifying dependencies"

  if check_dependencies 2>/dev/null; then
    test_pass
  else
    test_fail "Dependencies check failed (jq and yaml parser required)"
  fi
}

# Test 9: setup_patterns_directory() with default location
test_setup_patterns_directory() {
  test_start "setup_patterns_directory() finding default directory"

  local patterns_dir
  if patterns_dir=$(setup_patterns_directory 2>/dev/null); then
    if [[ -d "$patterns_dir" ]]; then
      test_pass
    else
      test_fail "Returned directory does not exist: $patterns_dir"
    fi
  else
    test_fail "setup_patterns_directory failed"
  fi
}

# Test 10: safe_load_patterns() with fallback
test_safe_load_patterns() {
  test_start "safe_load_patterns() executing without error"

  # Clear patterns
  AGENT_PATTERNS=()

  if safe_load_patterns 2>/dev/null; then
    # Check that some patterns were loaded (either from YAML or fallback)
    if [[ ${#AGENT_PATTERNS[@]} -gt 0 ]]; then
      test_pass
    else
      test_fail "No patterns loaded"
    fi
  else
    test_fail "safe_load_patterns failed"
  fi
}

# Run all tests
echo "================================"
echo "Pattern Loading Unit Tests"
echo "================================"
echo ""

test_parse_yaml_valid
test_validate_schema_valid
test_validate_schema_missing_version
test_validate_schema_invalid_type
test_load_pattern_file
test_malformed_yaml
test_discover_pattern_files
test_check_dependencies
test_setup_patterns_directory
test_safe_load_patterns

# Summary
echo ""
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
