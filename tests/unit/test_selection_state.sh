#!/usr/bin/env bash
# Unit tests for selection state management functions

set -o pipefail

# Define the functions we're testing (extracted from recommend_skills.sh)

# Global selection state
declare -A SELECTION_STATE

# Initialize selection state with default selections based on confidence threshold
init_selection_state() {
  local -n agents_ref=$1
  local -n confidence_ref=$2
  local threshold=${3:-50}
  
  SELECTION_STATE=()
  
  for agent in "${agents_ref[@]}"; do
    local confidence="${confidence_ref[$agent]:-0}"
    if [[ $confidence -ge $threshold ]]; then
      SELECTION_STATE[$agent]=1
    else
      SELECTION_STATE[$agent]=0
    fi
  done
}

# Toggle agent selection
toggle_agent_selection() {
  local agent="$1"
  
  if [[ ${SELECTION_STATE[$agent]:-0} -eq 1 ]]; then
    SELECTION_STATE[$agent]=0
    return 1  # Now unselected
  else
    SELECTION_STATE[$agent]=1
    return 0  # Now selected
  fi
}

# Select all agents
select_all_agents() {
  local -n agents_ref=$1
  
  for agent in "${agents_ref[@]}"; do
    SELECTION_STATE[$agent]=1
  done
}

# Select none
select_none_agents() {
  local -n agents_ref=$1
  
  for agent in "${agents_ref[@]}"; do
    SELECTION_STATE[$agent]=0
  done
}

# Get selected agents
get_selected_agents() {
  local -a selected=()
  
  for agent in "${!SELECTION_STATE[@]}"; do
    if [[ ${SELECTION_STATE[$agent]} -eq 1 ]]; then
      selected+=("$agent")
    fi
  done
  
  printf '%s\n' "${selected[@]}"
}

# Get selection count
get_selection_count() {
  local count=0
  
  for agent in "${!SELECTION_STATE[@]}"; do
    if [[ ${SELECTION_STATE[$agent]} -eq 1 ]]; then
      ((count++))
    fi
  done
  
  echo "$count"
}

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if [[ "$expected" == "$actual" ]]; then
    echo "✓ PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "✗ FAIL: $test_name"
    echo "  Expected: $expected"
    echo "  Actual:   $actual"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_true() {
  local condition="$1"
  local test_name="$2"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if [[ $condition -eq 1 ]] || [[ $condition == "true" ]]; then
    echo "✓ PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "✗ FAIL: $test_name"
    echo "  Expected: true"
    echo "  Actual:   false"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

echo "========================================"
echo "Selection State Management Tests"
echo "========================================"
echo ""

# Test 1: init_selection_state with threshold 50
echo "Test Suite: init_selection_state"
echo "----------------------------------------"

declare -a test_agents=("agent1" "agent2" "agent3")
declare -A test_confidence=(
  ["agent1"]=75
  ["agent2"]=45
  ["agent3"]=90
)

init_selection_state test_agents test_confidence 50

assert_equals "1" "${SELECTION_STATE[agent1]}" "agent1 selected (75% >= 50%)"
assert_equals "0" "${SELECTION_STATE[agent2]}" "agent2 not selected (45% < 50%)"
assert_equals "1" "${SELECTION_STATE[agent3]}" "agent3 selected (90% >= 50%)"

echo ""

# Test 2: init_selection_state with threshold 80
echo "Test Suite: init_selection_state with high threshold"
echo "----------------------------------------"

init_selection_state test_agents test_confidence 80

assert_equals "0" "${SELECTION_STATE[agent1]}" "agent1 not selected (75% < 80%)"
assert_equals "0" "${SELECTION_STATE[agent2]}" "agent2 not selected (45% < 80%)"
assert_equals "1" "${SELECTION_STATE[agent3]}" "agent3 selected (90% >= 80%)"

echo ""

# Test 3: toggle_agent_selection
echo "Test Suite: toggle_agent_selection"
echo "----------------------------------------"

SELECTION_STATE[agent1]=0

toggle_agent_selection "agent1"
assert_equals "1" "${SELECTION_STATE[agent1]}" "agent1 toggled from 0 to 1"

toggle_agent_selection "agent1"
assert_equals "0" "${SELECTION_STATE[agent1]}" "agent1 toggled from 1 to 0"

echo ""

# Test 4: select_all_agents
echo "Test Suite: select_all_agents"
echo "----------------------------------------"

init_selection_state test_agents test_confidence 50
select_all_agents test_agents

assert_equals "1" "${SELECTION_STATE[agent1]}" "agent1 selected after select_all"
assert_equals "1" "${SELECTION_STATE[agent2]}" "agent2 selected after select_all"
assert_equals "1" "${SELECTION_STATE[agent3]}" "agent3 selected after select_all"

echo ""

# Test 5: select_none_agents
echo "Test Suite: select_none_agents"
echo "----------------------------------------"

select_all_agents test_agents
select_none_agents test_agents

assert_equals "0" "${SELECTION_STATE[agent1]}" "agent1 unselected after select_none"
assert_equals "0" "${SELECTION_STATE[agent2]}" "agent2 unselected after select_none"
assert_equals "0" "${SELECTION_STATE[agent3]}" "agent3 unselected after select_none"

echo ""

# Test 6: get_selection_count
echo "Test Suite: get_selection_count"
echo "----------------------------------------"

SELECTION_STATE[agent1]=1
SELECTION_STATE[agent2]=0
SELECTION_STATE[agent3]=1

count=$(get_selection_count)
assert_equals "2" "$count" "get_selection_count returns 2"

select_all_agents test_agents
count=$(get_selection_count)
assert_equals "3" "$count" "get_selection_count returns 3 after select_all"

select_none_agents test_agents
count=$(get_selection_count)
assert_equals "0" "$count" "get_selection_count returns 0 after select_none"

echo ""

# Test 7: get_selected_agents
echo "Test Suite: get_selected_agents"
echo "----------------------------------------"

SELECTION_STATE[agent1]=1
SELECTION_STATE[agent2]=0
SELECTION_STATE[agent3]=1

selected=$(get_selected_agents | sort)
expected=$(printf "agent1\nagent3" | sort)

assert_equals "$expected" "$selected" "get_selected_agents returns agent1 and agent3"

select_all_agents test_agents
selected=$(get_selected_agents | sort)
expected=$(printf "agent1\nagent2\nagent3" | sort)

assert_equals "$expected" "$selected" "get_selected_agents returns all agents after select_all"

echo ""

# Summary
echo "========================================"
echo "Test Summary"
echo "========================================"
echo "Tests run:    $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
