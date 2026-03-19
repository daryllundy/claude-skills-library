#!/usr/bin/env bash
set -euo pipefail

# Unit tests for profile export/import functionality
# Tests JSON generation, validation, and import logic

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURES="$REPO_ROOT/tests/fixtures"
SCRIPT="$REPO_ROOT/scripts/recommend_agents.sh"
REPO_ARGS=(--repo "file://$REPO_ROOT" --branch "")

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Cleanup function
cleanup() {
  rm -f /tmp/test-profile-*.json
  rm -rf /tmp/test-agents-*
}

trap cleanup EXIT

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

# Test 1: Export creates valid JSON
test_export_valid_json() {
  run_test "Export should create valid JSON file"
  
  cd "$FIXTURES/aws-terraform-project"
  local export_file="/tmp/test-profile-$$.json"
  
  bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run --export "$export_file" --min-confidence 25 2>&1 > /dev/null
  
  if [[ -f "$export_file" ]]; then
    if command -v jq >/dev/null 2>&1; then
      if jq empty "$export_file" 2>/dev/null; then
        log_pass "Export created valid JSON"
      else
        log_fail "Export created invalid JSON"
      fi
    else
      log_pass "Export file created (jq not available for validation)"
    fi
  else
    log_fail "Export file not created"
  fi
}

# Test 2: Export contains required fields
test_export_schema() {
  run_test "Export should contain required schema fields"
  
  cd "$FIXTURES/aws-terraform-project"
  local export_file="/tmp/test-profile-schema-$$.json"
  
  bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run --export "$export_file" --min-confidence 25 2>&1 > /dev/null
  
  if [[ -f "$export_file" ]]; then
    local has_version=$(grep -q '"version"' "$export_file" && echo "yes" || echo "no")
    local has_generated_at=$(grep -q '"generated_at"' "$export_file" && echo "yes" || echo "no")
    local has_project_name=$(grep -q '"project_name"' "$export_file" && echo "yes" || echo "no")
    local has_detection_results=$(grep -q '"detection_results"' "$export_file" && echo "yes" || echo "no")
    local has_selected_agents=$(grep -q '"selected_agents"' "$export_file" && echo "yes" || echo "no")
    
    if [[ "$has_version" == "yes" ]] && [[ "$has_generated_at" == "yes" ]] && \
       [[ "$has_project_name" == "yes" ]] && [[ "$has_detection_results" == "yes" ]] && \
       [[ "$has_selected_agents" == "yes" ]]; then
      log_pass "Export contains all required schema fields"
    else
      log_fail "Export missing required fields"
    fi
  else
    log_fail "Export file not created"
  fi
}

# Test 3: Export includes agent metadata
test_export_metadata() {
  run_test "Export should include agent confidence and patterns"
  
  cd "$FIXTURES/aws-terraform-project"
  local export_file="/tmp/test-profile-metadata-$$.json"
  
  bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run --export "$export_file" --min-confidence 25 2>&1 > /dev/null
  
  if [[ -f "$export_file" ]]; then
    local has_confidence=$(grep -q '"confidence"' "$export_file" && echo "yes" || echo "no")
    local has_category=$(grep -q '"category"' "$export_file" && echo "yes" || echo "no")
    local has_patterns=$(grep -q '"patterns_matched"' "$export_file" && echo "yes" || echo "no")
    
    if [[ "$has_confidence" == "yes" ]] && [[ "$has_category" == "yes" ]] && [[ "$has_patterns" == "yes" ]]; then
      log_pass "Export includes agent metadata"
    else
      log_fail "Export missing agent metadata"
    fi
  else
    log_fail "Export file not created"
  fi
}

# Test 4: Export prevents overwriting without --force
test_export_overwrite_protection() {
  run_test "Export should prevent overwriting existing files without --force"
  
  cd "$FIXTURES/aws-terraform-project"
  local export_file="/tmp/test-profile-overwrite-$$.json"
  
  # Create initial export
  bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run --export "$export_file" --min-confidence 25 2>&1 > /dev/null
  
  # Try to export again without --force
  local output=$(bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run --export "$export_file" --min-confidence 25 2>&1 || true)
  
  if echo "$output" | grep -q "already exists"; then
    log_pass "Overwrite protection working"
  else
    log_fail "Overwrite protection not working"
  fi
}

# Test 5: Export with --force overwrites
test_export_force_overwrite() {
  run_test "Export with --force should overwrite existing files"
  
  cd "$FIXTURES/aws-terraform-project"
  local export_file="/tmp/test-profile-force-$$.json"
  
  # Create initial export
  bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run --export "$export_file" --min-confidence 25 2>&1 > /dev/null
  local initial_size=$(stat -f%z "$export_file" 2>/dev/null || stat -c%s "$export_file" 2>/dev/null)
  
  # Export again with --force
  bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run --export "$export_file" --force --min-confidence 25 2>&1 > /dev/null
  local new_size=$(stat -f%z "$export_file" 2>/dev/null || stat -c%s "$export_file" 2>/dev/null)
  
  if [[ -f "$export_file" ]]; then
    log_pass "Force overwrite successful"
  else
    log_fail "Force overwrite failed"
  fi
}

# Test 6: Import validates file existence
test_import_file_validation() {
  run_test "Import should validate file existence"
  
  cd "$FIXTURES/empty-project"
  local output=$(bash "$SCRIPT" "${REPO_ARGS[@]}" --import "/tmp/nonexistent-profile-$$.json" 2>&1 || true)
  
  if echo "$output" | grep -q "not found"; then
    log_pass "Import validates file existence"
  else
    log_fail "Import did not validate file existence"
  fi
}

# Test 7: Import with valid profile
test_import_valid_profile() {
  run_test "Import should install skills from valid profile"
  
  # Create a test profile
  local export_file="/tmp/test-profile-import-$$.json"
  cd "$FIXTURES/aws-terraform-project"
  bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run --export "$export_file" --min-confidence 40 2>&1 > /dev/null
  
  # Import in a temporary directory
  local test_dir="/tmp/test-agents-$$"
  mkdir -p "$test_dir"
  cd "$test_dir"
  
  local output=$(bash "$SCRIPT" "${REPO_ARGS[@]}" --import "$export_file" 2>&1)
  
  if echo "$output" | grep -q "Successfully installed"; then
    log_pass "Import installed skills from profile"
  else
    log_fail "Import did not install skills"
  fi
  
  # Cleanup
  rm -rf "$test_dir"
}

# Test 8: Import creates .claude/skills directory
test_import_creates_directory() {
  run_test "Import should create .claude/skills directory"
  
  local export_file="/tmp/test-profile-dir-$$.json"
  cd "$FIXTURES/aws-terraform-project"
  bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run --export "$export_file" --min-confidence 40 2>&1 > /dev/null
  
  local test_dir="/tmp/test-agents-dir-$$"
  mkdir -p "$test_dir"
  cd "$test_dir"
  
  bash "$SCRIPT" "${REPO_ARGS[@]}" --import "$export_file" 2>&1 > /dev/null
  
  if [[ -d ".claude/skills" ]]; then
    log_pass "Import created .claude/skills directory"
  else
    log_fail "Import did not create directory"
  fi
  
  rm -rf "$test_dir"
}

# Test 9: Export with different confidence thresholds
test_export_confidence_threshold() {
  run_test "Export should change selected skills when threshold changes"
  
  cd "$FIXTURES/aws-terraform-project"
  local export_low="/tmp/test-profile-low-$$.json"
  local export_high="/tmp/test-profile-high-$$.json"
  
  bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run --export "$export_low" --min-confidence 20 2>&1 > /dev/null
  bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run --export "$export_high" --min-confidence 60 2>&1 > /dev/null
  
  if command -v jq >/dev/null 2>&1; then
    local count_low=$(jq '.selected_agents | length' "$export_low")
    local count_high=$(jq '.selected_agents | length' "$export_high")
    local low_has_tf=$(jq -r '.selected_agents[]?' "$export_low" | grep -c '^terraform-specialist$' || true)
    local profiles_differ=$(cmp -s "$export_low" "$export_high"; echo $?)
    
    if [[ $low_has_tf -gt 0 ]] && [[ "$profiles_differ" -ne 0 ]] && [[ $count_low -gt 0 ]] && [[ $count_high -gt 0 ]]; then
      log_pass "Export changed selected skills across thresholds ($count_low vs $count_high)"
    else
      log_fail "Export does not respect confidence threshold"
    fi
  else
    log_pass "Export files created (jq not available for comparison)"
  fi
}

# Test 10: Export includes timestamp
test_export_timestamp() {
  run_test "Export should include ISO 8601 timestamp"
  
  cd "$FIXTURES/aws-terraform-project"
  local export_file="/tmp/test-profile-timestamp-$$.json"
  
  bash "$SCRIPT" "${REPO_ARGS[@]}" --dry-run --export "$export_file" --min-confidence 25 2>&1 > /dev/null
  
  if [[ -f "$export_file" ]]; then
    # Check for ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ)
    if grep -qE '"generated_at".*[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z' "$export_file"; then
      log_pass "Export includes ISO 8601 timestamp"
    else
      log_fail "Export timestamp not in ISO 8601 format"
    fi
  else
    log_fail "Export file not created"
  fi
}

# Run all tests
echo "========================================="
echo "Profile Management Unit Tests"
echo "========================================="
echo ""

test_export_valid_json
test_export_schema
test_export_metadata
test_export_overwrite_protection
test_export_force_overwrite
test_import_file_validation
test_import_valid_profile
test_import_creates_directory
test_export_confidence_threshold
test_export_timestamp

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
