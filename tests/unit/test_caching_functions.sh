#!/usr/bin/env bash

# Unit tests for caching functions in recommend_agents.sh
# Tests cache path generation, freshness checking, and fetch_with_cache

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

# Source the caching functions
source_cache_functions() {
  # Set cache directory for tests
  export CACHE_DIR="$TEST_DIR/cache"
  export CACHE_EXPIRY_SECONDS=3600
  
  # Source init_cache
  eval "$(sed -n '/^init_cache() {/,/^}/p' "$REPO_ROOT/scripts/recommend_agents.sh")"
  
  # Source get_cache_path
  eval "$(sed -n '/^get_cache_path() {/,/^}/p' "$REPO_ROOT/scripts/recommend_agents.sh")"
  
  # Source is_cache_fresh
  eval "$(sed -n '/^is_cache_fresh() {/,/^}/p' "$REPO_ROOT/scripts/recommend_agents.sh")"
  
  # Source fetch_with_cache
  eval "$(sed -n '/^fetch_with_cache() {/,/^}/p' "$REPO_ROOT/scripts/recommend_agents.sh")"
  
  # Source fetch_with_retry (needed by fetch_with_cache)
  eval "$(sed -n '/^fetch_with_retry() {/,/^}/p' "$REPO_ROOT/scripts/recommend_agents.sh")"
}

source_cache_functions

# Test 1: Cache path generation with md5
test_cache_path_generation() {
  run_test "get_cache_path should generate consistent hash-based paths"
  
  local url="http://example.com/test-file.txt"
  local cache_path1
  local cache_path2
  
  cache_path1=$(get_cache_path "$url")
  cache_path2=$(get_cache_path "$url")
  
  # Same URL should produce same path
  if [[ "$cache_path1" == "$cache_path2" ]]; then
    # Path should be in cache directory
    if [[ "$cache_path1" == "$CACHE_DIR"/* ]]; then
      log_pass "Cache path generation is consistent and uses cache directory"
    else
      log_fail "Cache path not in cache directory: $cache_path1"
    fi
  else
    log_fail "Cache path generation is inconsistent"
  fi
}

# Test 2: Different URLs produce different cache paths
test_different_urls_different_paths() {
  run_test "get_cache_path should generate different paths for different URLs"
  
  local url1="http://example.com/file1.txt"
  local url2="http://example.com/file2.txt"
  
  local cache_path1
  local cache_path2
  
  cache_path1=$(get_cache_path "$url1")
  cache_path2=$(get_cache_path "$url2")
  
  if [[ "$cache_path1" != "$cache_path2" ]]; then
    log_pass "Different URLs produce different cache paths"
  else
    log_fail "Different URLs produced same cache path"
  fi
}

# Test 3: Cache freshness with fresh file
test_cache_freshness_fresh_file() {
  run_test "is_cache_fresh should return true for fresh files"
  
  init_cache
  
  local cache_file="$CACHE_DIR/test_fresh"
  echo "test content" > "$cache_file"
  touch "$cache_file"
  
  if is_cache_fresh "$cache_file" 3600; then
    log_pass "Fresh file correctly identified as fresh"
  else
    log_fail "Fresh file incorrectly identified as stale"
  fi
}

# Test 4: Cache freshness with stale file
test_cache_freshness_stale_file() {
  run_test "is_cache_fresh should return false for stale files"
  
  init_cache
  
  local cache_file="$CACHE_DIR/test_stale"
  echo "old content" > "$cache_file"
  
  # Set file modification time to 2 hours ago (7200 seconds)
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS: use touch with -t flag
    local old_time=$(date -v-2H +"%Y%m%d%H%M.%S")
    touch -t "$old_time" "$cache_file"
  else
    # Linux: use touch with -d flag
    touch -d "2 hours ago" "$cache_file"
  fi
  
  # Check with 1 hour expiry (3600 seconds)
  if is_cache_fresh "$cache_file" 3600; then
    log_fail "Stale file incorrectly identified as fresh"
  else
    log_pass "Stale file correctly identified as stale"
  fi
}

# Test 5: Cache freshness with non-existent file
test_cache_freshness_nonexistent() {
  run_test "is_cache_fresh should return false for non-existent files"
  
  local cache_file="$CACHE_DIR/nonexistent"
  
  if is_cache_fresh "$cache_file" 3600; then
    log_fail "Non-existent file incorrectly identified as fresh"
  else
    log_pass "Non-existent file correctly identified as not fresh"
  fi
}

# Test 6: fetch_with_cache using cached data
test_fetch_with_cache_uses_cache() {
  run_test "fetch_with_cache should use cached data when fresh"
  
  init_cache
  
  local url="http://example.com/cached-file.txt"
  local output="$TEST_DIR/output_cached.txt"
  local cache_file
  cache_file=$(get_cache_path "$url")
  
  # Create fresh cache file
  echo "cached content" > "$cache_file"
  touch "$cache_file"
  
  # Mock fetch_with_retry to fail (should not be called)
  fetch_with_retry() {
    echo "ERROR: fetch_with_retry should not be called when cache is fresh" >&2
    return 1
  }
  export -f fetch_with_retry
  
  # Disable force refresh
  export FORCE_REFRESH=false
  
  if fetch_with_cache "$url" "$output" 3600 2>/dev/null; then
    if [[ -f "$output" ]] && [[ "$(cat "$output")" == "cached content" ]]; then
      log_pass "fetch_with_cache correctly used cached data"
    else
      log_fail "Output file incorrect or missing"
    fi
  else
    log_fail "fetch_with_cache failed when cache was fresh"
  fi
  
  # Restore function
  source_cache_functions
}

# Test 7: fetch_with_cache with stale cache
test_fetch_with_cache_stale_cache() {
  run_test "fetch_with_cache should fetch fresh data when cache is stale"
  
  init_cache
  
  local url="http://example.com/stale-file.txt"
  local output="$TEST_DIR/output_stale.txt"
  local cache_file
  cache_file=$(get_cache_path "$url")
  
  # Create stale cache file
  echo "old content" > "$cache_file"
  if [[ "$(uname)" == "Darwin" ]]; then
    local old_time=$(date -v-2H +"%Y%m%d%H%M.%S")
    touch -t "$old_time" "$cache_file"
  else
    touch -d "2 hours ago" "$cache_file"
  fi
  
  # Mock fetch_with_retry to return new content
  fetch_with_retry() {
    local url="$1"
    local output="$2"
    echo "new content" > "$output"
    return 0
  }
  export -f fetch_with_retry
  
  export FORCE_REFRESH=false
  
  if fetch_with_cache "$url" "$output" 3600 2>/dev/null; then
    if [[ "$(cat "$output")" == "new content" ]]; then
      # Check that cache was updated
      if [[ "$(cat "$cache_file")" == "new content" ]]; then
        log_pass "fetch_with_cache fetched fresh data and updated cache"
      else
        log_fail "Cache was not updated with new content"
      fi
    else
      log_fail "Output does not contain new content"
    fi
  else
    log_fail "fetch_with_cache failed"
  fi
  
  # Restore function
  source_cache_functions
}

# Test 8: fetch_with_cache with force refresh
test_fetch_with_cache_force_refresh() {
  run_test "fetch_with_cache should bypass cache when force refresh is enabled"
  
  init_cache
  
  local url="http://example.com/force-refresh.txt"
  local output="$TEST_DIR/output_force.txt"
  local cache_file
  cache_file=$(get_cache_path "$url")
  
  # Create fresh cache file
  echo "cached content" > "$cache_file"
  touch "$cache_file"
  
  # Mock fetch_with_retry to return different content
  local fetch_called=0
  fetch_with_retry() {
    fetch_called=1
    local url="$1"
    local output="$2"
    echo "fresh content" > "$output"
    return 0
  }
  export -f fetch_with_retry
  export fetch_called
  
  # Enable force refresh
  export FORCE_REFRESH=true
  
  if fetch_with_cache "$url" "$output" 3600 2>/dev/null; then
    if [[ $fetch_called -eq 1 ]] && [[ "$(cat "$output")" == "fresh content" ]]; then
      log_pass "fetch_with_cache bypassed cache with force refresh"
    else
      log_fail "Cache was not bypassed or content incorrect"
    fi
  else
    log_fail "fetch_with_cache failed"
  fi
  
  # Restore
  export FORCE_REFRESH=false
  source_cache_functions
  unset fetch_called
}

# Test 9: fetch_with_cache with cache miss
test_fetch_with_cache_cache_miss() {
  run_test "fetch_with_cache should fetch data when cache doesn't exist"
  
  init_cache
  
  local url="http://example.com/new-file.txt"
  local output="$TEST_DIR/output_miss.txt"
  local cache_file
  cache_file=$(get_cache_path "$url")
  
  # Ensure cache file doesn't exist
  rm -f "$cache_file"
  
  # Mock fetch_with_retry
  fetch_with_retry() {
    local url="$1"
    local output="$2"
    echo "fetched content" > "$output"
    return 0
  }
  export -f fetch_with_retry
  
  export FORCE_REFRESH=false
  
  if fetch_with_cache "$url" "$output" 3600 2>/dev/null; then
    if [[ "$(cat "$output")" == "fetched content" ]]; then
      # Check that cache was created
      if [[ -f "$cache_file" ]] && [[ "$(cat "$cache_file")" == "fetched content" ]]; then
        log_pass "fetch_with_cache fetched data and created cache"
      else
        log_fail "Cache was not created"
      fi
    else
      log_fail "Output content incorrect"
    fi
  else
    log_fail "fetch_with_cache failed"
  fi
  
  # Restore function
  source_cache_functions
}

# Test 10: fetch_with_cache handles fetch failure
test_fetch_with_cache_fetch_failure() {
  run_test "fetch_with_cache should return failure when fetch fails"
  
  init_cache
  
  local url="http://example.com/fail.txt"
  local output="$TEST_DIR/output_fail.txt"
  
  # Mock fetch_with_retry to fail
  fetch_with_retry() {
    return 1
  }
  export -f fetch_with_retry
  
  export FORCE_REFRESH=false
  
  if fetch_with_cache "$url" "$output" 3600 2>/dev/null; then
    log_fail "fetch_with_cache should have failed"
  else
    log_pass "fetch_with_cache correctly returned failure"
  fi
  
  # Restore function
  source_cache_functions
}

# Test 11: init_cache creates directory
test_init_cache_creates_directory() {
  run_test "init_cache should create cache directory if it doesn't exist"
  
  local new_cache_dir="$TEST_DIR/new_cache"
  export CACHE_DIR="$new_cache_dir"
  
  # Ensure directory doesn't exist
  rm -rf "$new_cache_dir"
  
  if init_cache; then
    if [[ -d "$new_cache_dir" ]]; then
      log_pass "init_cache created cache directory"
    else
      log_fail "Cache directory was not created"
    fi
  else
    log_fail "init_cache failed"
  fi
  
  # Restore
  export CACHE_DIR="$TEST_DIR/cache"
}

# Test 12: Custom cache expiry
test_custom_cache_expiry() {
  run_test "is_cache_fresh should respect custom expiry parameter"
  
  init_cache
  
  local cache_file="$CACHE_DIR/test_expiry"
  echo "test content" > "$cache_file"
  
  # Set file to 30 seconds old
  if [[ "$(uname)" == "Darwin" ]]; then
    local old_time=$(date -v-30S +"%Y%m%d%H%M.%S")
    touch -t "$old_time" "$cache_file"
  else
    touch -d "30 seconds ago" "$cache_file"
  fi
  
  # Should be stale with 10 second expiry
  if is_cache_fresh "$cache_file" 10; then
    log_fail "File should be stale with 10 second expiry"
    return
  fi
  
  # Should be fresh with 60 second expiry
  if is_cache_fresh "$cache_file" 60; then
    log_pass "Custom cache expiry works correctly"
  else
    log_fail "File should be fresh with 60 second expiry"
  fi
}

# Run all tests
echo "========================================="
echo "Caching Functions Unit Tests"
echo "========================================="
echo ""

test_cache_path_generation
test_different_urls_different_paths
test_cache_freshness_fresh_file
test_cache_freshness_stale_file
test_cache_freshness_nonexistent
test_fetch_with_cache_uses_cache
test_fetch_with_cache_stale_cache
test_fetch_with_cache_force_refresh
test_fetch_with_cache_cache_miss
test_fetch_with_cache_fetch_failure
test_init_cache_creates_directory
test_custom_cache_expiry

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
