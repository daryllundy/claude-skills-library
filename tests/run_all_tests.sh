#!/usr/bin/env bash
if [[ -x /opt/homebrew/bin/bash ]]; then
  export PATH="/opt/homebrew/bin:$PATH"
fi
set -uo pipefail

# Master test runner for all skill recommendation tests
# Runs both unit and integration tests

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test suite counters
SUITES_RUN=0
SUITES_PASSED=0
SUITES_FAILED=0

echo "========================================="
echo "Claude Skills Library - Test Suite"
echo "========================================="
echo ""

# Function to run a test suite
run_suite() {
  local suite_name="$1"
  local suite_script="$2"
  
  ((SUITES_RUN++))
  
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}Running: $suite_name${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  if bash "$suite_script"; then
    ((SUITES_PASSED++))
    echo ""
    echo -e "${GREEN}✓ $suite_name PASSED${NC}"
  else
    ((SUITES_FAILED++))
    echo ""
    echo -e "${RED}✗ $suite_name FAILED${NC}"
  fi
  
  echo ""
}

# Run unit tests
echo -e "${YELLOW}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}UNIT TESTS${NC}"
echo -e "${YELLOW}═══════════════════════════════════════${NC}"
echo ""

run_suite "Detection Functions" "$SCRIPT_DIR/unit/test_detection_functions.sh"
run_suite "Confidence Scoring" "$SCRIPT_DIR/unit/test_confidence_scoring.sh"
run_suite "Profile Management" "$SCRIPT_DIR/unit/test_profile_management.sh"
run_suite "Update Detection" "$SCRIPT_DIR/unit/test_update_detection.sh"
run_suite "Selection State Management" "$SCRIPT_DIR/unit/test_selection_state.sh"
run_suite "Rendering Functions" "$SCRIPT_DIR/unit/test_rendering.sh"
run_suite "Confidence Normalization" "$SCRIPT_DIR/unit/test_confidence_normalization.sh"
run_suite "Caching Functions" "$SCRIPT_DIR/unit/test_caching_functions.sh"
run_suite "Fetch with Retry" "$SCRIPT_DIR/unit/test_fetch_with_retry.sh"
run_suite "YAML Parser" "$SCRIPT_DIR/unit/test_yaml_parser.sh"

# Run integration tests
echo -e "${YELLOW}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}INTEGRATION TESTS${NC}"
echo -e "${YELLOW}═══════════════════════════════════════${NC}"
echo ""

run_suite "End-to-End Detection" "$SCRIPT_DIR/integration/test_detection.sh"
run_suite "Update Operations" "$SCRIPT_DIR/integration/test_update_operations.sh"
run_suite "Pattern Loading" "$SCRIPT_DIR/integration/test_pattern_loading.sh"
run_suite "Use Case Metadata" "$SCRIPT_DIR/integration/test_use_case_metadata.sh"
run_suite "Use Case Simple" "$SCRIPT_DIR/integration/test_use_case_simple.sh"
run_suite "CLI Compatibility" "$SCRIPT_DIR/integration/test_cli_compatibility.sh"

# Run interactive tests if expect is available
if command -v expect &> /dev/null; then
  run_suite "Interactive Mode" "$SCRIPT_DIR/integration/test_interactive.sh"
else
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}SKIP: Interactive Mode Tests${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Interactive tests require 'expect' to be installed."
  echo "To install: brew install expect (macOS) or apt-get install expect (Linux)"
  echo ""
fi

# Final summary
echo ""
echo "========================================="
echo "FINAL TEST SUMMARY"
echo "========================================="
echo "Test suites run:    $SUITES_RUN"
echo -e "${GREEN}Test suites passed: $SUITES_PASSED${NC}"

if [[ $SUITES_FAILED -gt 0 ]]; then
  echo -e "${RED}Test suites failed: $SUITES_FAILED${NC}"
  echo ""
  echo -e "${RED}❌ SOME TESTS FAILED${NC}"
  exit 1
else
  echo ""
  echo -e "${GREEN}✅ ALL TESTS PASSED!${NC}"
  exit 0
fi
