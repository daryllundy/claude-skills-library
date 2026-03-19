#!/usr/bin/env bash

# Unit tests for fetch_with_retry function in recommend_agents.sh
# Tests retry logic, timeout handling, and error reporting

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test directory
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR" 2>/dev/null || true' EXIT

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

# Mock log function
log() {
  echo "[LOG] $*" >&2
}

# Source the fetch_with_retry function
source_fetch_function() {
  eval "$(sed -n '/^fetch_with_retry() {/,/^}/p' "$REPO_ROOT/scripts/recommend_agents.sh")"
}

source_fetch_function

# Test 1: Successful download on first attempt
test_successful_first_attempt() {
  run_test "fetch_with_retry should succeed on first attempt"
  
  local output="$TEST_DIR/output1.txt"
  local test_content="test content"
  
  # Mock curl to succeed immediately
  curl() {
    if [[ "$*" == *"-o"* ]]; then
      # Extract output file
      local out_file=""
      local next_is_output=false
      for arg in "$@"; do
        if [[ $next_is_output == true ]]; then
          out_file="$arg"
          break
        fi
        if [[ "$arg" == "-o" ]]; then
          next_is_output=true
        fi
      done
      echo "$test_content" > "$out_file"
      return 0
    fi
    return 0
  }
  export -f curl
  
  if fetch_with_retry "http://example.com/file" "$output" 3 30; then
    if [[ -f "$output" ]] && [[ "$(cat "$output")" == "$test_content" ]]; then
      log_pass "Successfully downloaded on first attempt"
    else
      log_fail "File not created or content incorrect"
    fi
  else
    log_fail "fetch_with_retry returned failure"
  fi
  
  unset -f curl
}

# Test 2: Retry on failure then succeed
test_retry_on_failure() {
  run_test "fetch_with_retry should retry on failure and eventually succeed"
  
  local output="$TEST_DIR/output2.txt"
  local test_content="retry success"
  local attempt_count=0
  
  # Mock curl to fail twice then succeed
  curl() {
    ((attempt_count++))
    
    if [[ "$*" == *"-o"* ]]; then
      if [[ $attempt_count -lt 3 ]]; then
        return 1  # Fail first two attempts
      fi
      
      # Extract output file
      local out_file=""
      local next_is_output=false
      for arg in "$@"; do
        if [[ $next_is_output == true ]]; then
          out_file="$arg"
          break
        fi
        if [[ "$arg" == "-o" ]]; then
          next_is_output=true
        fi
      done
      echo "$test_content" > "$out_file"
      return 0
    fi
    
    # For HTTP code check
    if [[ "$*" == *"%{http_code}"* ]]; then
      echo "503"
      return 0
    fi
    
    return 1
  }
  export -f curl
  export attempt_count
  
  if fetch_with_retry "http://example.com/file" "$output" 3 30 2>/dev/null; then
    if [[ $attempt_count -eq 3 ]] && [[ -f "$output" ]]; then
      log_pass "Retried and succeeded on attempt 3"
    else
      log_fail "Unexpected attempt count: $attempt_count"
    fi
  else
    log_fail "fetch_with_retry failed after retries"
  fi
  
  unset -f curl
  unset attempt_count
}

# Test 3: Exhausted retries
test_exhausted_retries() {
  run_test "fetch_with_retry should fail after exhausting all retries"
  
  local output="$TEST_DIR/output3.txt"
  local attempt_count=0
  
  # Mock curl to always fail
  curl() {
    ((attempt_count++))
    
    if [[ "$*" == *"%{http_code}"* ]]; then
      echo "500"
      return 0
    fi
    
    return 1
  }
  export -f curl
  export attempt_count
  
  if fetch_with_retry "http://example.com/file" "$output" 3 30 2>/dev/null; then
    log_fail "fetch_with_retry should have failed"
  else
    if [[ $attempt_count -ge 3 ]]; then
      log_pass "Failed after 3 attempts as expected"
    else
      log_fail "Did not attempt enough times: $attempt_count"
    fi
  fi
  
  unset -f curl
  unset attempt_count
}

# Test 4: Timeout handling
test_timeout_handling() {
  run_test "fetch_with_retry should respect timeout parameter"
  
  local output="$TEST_DIR/output4.txt"
  local timeout_used=0
  
  # Mock curl to check timeout parameter
  curl() {
    local has_timeout=false
    local timeout_value=""
    
    for i in "${!@}"; do
      local arg="${!i}"
      if [[ "$arg" == "--max-time" ]]; then
        has_timeout=true
        local next_idx=$((i + 1))
        timeout_value="${!next_idx}"
        break
      fi
    done
    
    if [[ $has_timeout == true ]] && [[ "$timeout_value" == "15" ]]; then
      timeout_used=1
    fi
    
    if [[ "$*" == *"-o"* ]]; then
      local out_file=""
      local next_is_output=false
      for arg in "$@"; do
        if [[ $next_is_output == true ]]; then
          out_file="$arg"
          break
        fi
        if [[ "$arg" == "-o" ]]; then
          next_is_output=true
        fi
      done
      echo "content" > "$out_file"
      return 0
    fi
    
    return 0
  }
  export -f curl
  export timeout_used
  
  fetch_with_retry "http://example.com/file" "$output" 3 15 2>/dev/null
  
  if [[ $timeout_used -eq 1 ]]; then
    log_pass "Timeout parameter was correctly passed to curl"
  else
    log_fail "Timeout parameter was not used"
  fi
  
  unset -f curl
  unset timeout_used
}

# Test 5: Verbose logging
test_verbose_logging() {
  run_test "fetch_with_retry should log details in verbose mode"
  
  local output="$TEST_DIR/output5.txt"
  local log_output="$TEST_DIR/log5.txt"
  
  # Enable verbose mode
  export VERBOSE=true
  
  # Mock curl to succeed
  curl() {
    if [[ "$*" == *"-o"* ]]; then
      local out_file=""
      local next_is_output=false
      for arg in "$@"; do
        if [[ $next_is_output == true ]]; then
          out_file="$arg"
          break
        fi
        if [[ "$arg" == "-o" ]]; then
          next_is_output=true
        fi
      done
      echo "content" > "$out_file"
      return 0
    fi
    return 0
  }
  export -f curl
  
  # Capture log output
  fetch_with_retry "http://example.com/test.txt" "$output" 3 30 2>"$log_output"
  
  if grep -q "Successfully downloaded" "$log_output"; then
    log_pass "Verbose logging is working"
  else
    log_fail "Verbose logging not found in output"
  fi
  
  unset VERBOSE
  unset -f curl
}

# Test 6: HTTP status code logging
test_http_status_logging() {
  run_test "fetch_with_retry should log HTTP status codes on failure"
  
  local output="$TEST_DIR/output6.txt"
  local log_output="$TEST_DIR/log6.txt"
  local attempt_count=0
  
  # Mock curl to fail with 404
  curl() {
    ((attempt_count++))
    
    if [[ "$*" == *"%{http_code}"* ]]; then
      echo "404"
      return 0
    fi
    
    return 1
  }
  export -f curl
  export attempt_count
  
  fetch_with_retry "http://example.com/file" "$output" 2 30 2>"$log_output"
  
  if grep -q "HTTP 404" "$log_output"; then
    log_pass "HTTP status code logged correctly"
  else
    log_fail "HTTP status code not found in logs"
  fi
  
  unset -f curl
  unset attempt_count
}

# Test 7: Exponential backoff
test_exponential_backoff() {
  run_test "fetch_with_retry should use exponential backoff"
  
  local output="$TEST_DIR/output7.txt"
  local log_output="$TEST_DIR/log7.txt"
  
  # Mock curl to fail
  curl() {
    if [[ "$*" == *"%{http_code}"* ]]; then
      echo "503"
      return 0
    fi
    return 1
  }
  export -f curl
  
  # Mock sleep to track backoff times
  declare -a sleep_times=()
  sleep() {
    sleep_times+=("$1")
  }
  export -f sleep
  export sleep_times
  
  fetch_with_retry "http://example.com/file" "$output" 3 30 2>"$log_output"
  
  # Check if backoff times are exponential (2, 4)
  if [[ ${#sleep_times[@]} -eq 2 ]] && [[ ${sleep_times[0]} -eq 2 ]] && [[ ${sleep_times[1]} -eq 4 ]]; then
    log_pass "Exponential backoff working correctly (2s, 4s)"
  else
    log_fail "Exponential backoff not working: ${sleep_times[*]}"
  fi
  
  unset -f curl
  unset -f sleep
  unset sleep_times
}

# Test 8: Troubleshooting guidance on final failure
test_troubleshooting_guidance() {
  run_test "fetch_with_retry should provide troubleshooting guidance on final failure"
  
  local output="$TEST_DIR/output8.txt"
  local error_output="$TEST_DIR/error8.txt"
  
  # Mock curl to fail with 404
  curl() {
    if [[ "$*" == *"%{http_code}"* ]]; then
      echo "404"
      return 0
    fi
    return 1
  }
  export -f curl
  
  fetch_with_retry "http://example.com/file" "$output" 2 30 2>"$error_output"
  
  if grep -q "Troubleshooting" "$error_output"; then
    log_pass "Troubleshooting guidance provided"
  else
    log_fail "No troubleshooting guidance found"
  fi
  
  unset -f curl
}

# Test 9: Custom max attempts parameter
test_custom_max_attempts() {
  run_test "fetch_with_retry should respect custom max_attempts parameter"
  
  local output="$TEST_DIR/output9.txt"
  local attempt_count=0
  
  # Mock curl to always fail
  curl() {
    ((attempt_count++))
    
    if [[ "$*" == *"%{http_code}"* ]]; then
      echo "500"
      return 0
    fi
    
    return 1
  }
  export -f curl
  export attempt_count
  
  fetch_with_retry "http://example.com/file" "$output" 5 30 2>/dev/null
  
  if [[ $attempt_count -eq 5 ]]; then
    log_pass "Custom max_attempts (5) respected"
  else
    log_fail "Expected 5 attempts, got $attempt_count"
  fi
  
  unset -f curl
  unset attempt_count
}

# Test 10: Default parameters
test_default_parameters() {
  run_test "fetch_with_retry should use default parameters when not specified"
  
  local output="$TEST_DIR/output10.txt"
  local max_attempts_used=0
  local timeout_used=0
  
  # Mock curl to check default parameters
  curl() {
    # Check for default timeout (30)
    for i in "${!@}"; do
      local arg="${!i}"
      if [[ "$arg" == "--max-time" ]]; then
        local next_idx=$((i + 1))
        local timeout_value="${!next_idx}"
        if [[ "$timeout_value" == "30" ]]; then
          timeout_used=1
        fi
        break
      fi
    done
    
    if [[ "$*" == *"-o"* ]]; then
      local out_file=""
      local next_is_output=false
      for arg in "$@"; do
        if [[ $next_is_output == true ]]; then
          out_file="$arg"
          break
        fi
        if [[ "$arg" == "-o" ]]; then
          next_is_output=true
        fi
      done
      echo "content" > "$out_file"
      return 0
    fi
    
    return 0
  }
  export -f curl
  export timeout_used
  
  # Call without optional parameters
  fetch_with_retry "http://example.com/file" "$output" 2>/dev/null
  
  if [[ $timeout_used -eq 1 ]]; then
    log_pass "Default timeout (30s) used correctly"
  else
    log_fail "Default timeout not used"
  fi
  
  unset -f curl
  unset timeout_used
}

# Run all tests
echo "========================================="
echo "fetch_with_retry Unit Tests"
echo "========================================="
echo ""

test_successful_first_attempt
test_retry_on_failure
test_exhausted_retries
test_timeout_handling
test_verbose_logging
test_http_status_logging
test_exponential_backoff
test_troubleshooting_guidance
test_custom_max_attempts
test_default_parameters

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
