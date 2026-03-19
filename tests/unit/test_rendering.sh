#!/usr/bin/env bash

# Unit tests for rendering functions

# Define the functions we're testing (extracted from recommend_agents.sh)

draw_progress_bar() {
  local confidence="$1"
  local bar_length=20
  local filled=$((confidence * bar_length / 100))
  local empty=$((bar_length - filled))

  printf "["
  for ((i=0; i<filled; i++)); do printf "█"; done
  for ((i=0; i<empty; i++)); do printf "░"; done
  printf "]"
}

render_category_header() {
  local category="$1"
  local count="$2"
  
  echo ""
  echo "━━ $category ($count agent(s)) ━━"
  echo ""
}

render_confidence_bar() {
  draw_progress_bar "$@"
}

render_agent_item() {
  local agent="$1"
  local confidence="$2"
  local description="$3"
  local is_selected="$4"
  local is_current="$5"
  
  # Determine cursor
  local cursor=" "
  if [[ $is_current -eq 1 ]]; then
    cursor=">"
  fi
  
  # Determine checkbox
  local checkbox="[ ]"
  if [[ $is_selected -eq 1 ]]; then
    checkbox="[✓]"
  fi
  
  # Display the agent with confidence bar
  printf "%s %s %s (%d%%)\n" "$cursor" "$checkbox" "$agent" "$confidence"
  
  # Show description if it's the current selection
  if [[ $is_current -eq 1 ]] && [[ -n "$description" ]]; then
    printf "      %s\n" "$description"
  fi
}

render_navigation_footer() {
  local selected_count="$1"
  local total_count="$2"
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Selected: $selected_count / $total_count agents"
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
  
  ((++TESTS_RUN))
  
  if [[ "$expected" == "$actual" ]]; then
    echo "✓ PASS: $test_name"
    ((++TESTS_PASSED))
    return 0
  else
    echo "✗ FAIL: $test_name"
    echo "  Expected: $expected"
    echo "  Actual:   $actual"
    ((++TESTS_FAILED))
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local test_name="$3"
  
  ((++TESTS_RUN))
  
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "✓ PASS: $test_name"
    ((++TESTS_PASSED))
    return 0
  else
    echo "✗ FAIL: $test_name"
    echo "  Expected to contain: $needle"
    echo "  Actual: $haystack"
    ((++TESTS_FAILED))
    return 1
  fi
}

assert_matches() {
  local actual="$1"
  local pattern="$2"
  local test_name="$3"
  
  ((++TESTS_RUN))
  
  if [[ "$actual" =~ $pattern ]]; then
    echo "✓ PASS: $test_name"
    ((++TESTS_PASSED))
    return 0
  else
    echo "✗ FAIL: $test_name"
    echo "  Expected to match: $pattern"
    echo "  Actual: $actual"
    ((++TESTS_FAILED))
    return 1
  fi
}

# Test render_confidence_bar
test_render_confidence_bar_width() {
  local bar=$(render_confidence_bar 50)
  local length=${#bar}
  
  # Should have 20 characters + 2 brackets = 22 total
  assert_equals "22" "$length" "render_confidence_bar generates correct width"
}

test_render_confidence_bar_format() {
  local bar=$(render_confidence_bar 50)
  
  # Should start with [ and end with ]
  assert_matches "$bar" '^\[.*\]$' "render_confidence_bar has correct format"
}

test_render_confidence_bar_zero() {
  local bar=$(render_confidence_bar 0)
  
  # Should be all empty
  assert_contains "$bar" "░" "render_confidence_bar handles 0% confidence"
}

test_render_confidence_bar_full() {
  local bar=$(render_confidence_bar 100)
  
  # Should be all filled
  assert_contains "$bar" "█" "render_confidence_bar handles 100% confidence"
}

# Test render_category_header
test_render_category_header_format() {
  local output=$(render_category_header "Infrastructure" 5)
  
  assert_contains "$output" "Infrastructure" "render_category_header includes category name"
  assert_contains "$output" "5" "render_category_header includes count"
}

test_render_category_header_single_agent() {
  local output=$(render_category_header "Development" 1)
  
  assert_contains "$output" "1 agent" "render_category_header handles singular agent"
}

# Test render_agent_item
test_render_agent_item_unselected() {
  local output=$(render_agent_item "test-agent" 75 "Test description" 0 0)
  
  assert_contains "$output" "[ ]" "render_agent_item shows unchecked box when unselected"
  assert_contains "$output" "test-agent" "render_agent_item includes agent name"
  assert_contains "$output" "75%" "render_agent_item includes confidence percentage"
}

test_render_agent_item_selected() {
  local output=$(render_agent_item "test-agent" 75 "Test description" 1 0)
  
  assert_contains "$output" "[✓]" "render_agent_item shows checked box when selected"
}

test_render_agent_item_current() {
  local output=$(render_agent_item "test-agent" 75 "Test description" 0 1)
  
  assert_contains "$output" ">" "render_agent_item shows cursor when current"
  assert_contains "$output" "Test description" "render_agent_item shows description when current"
}

test_render_agent_item_not_current() {
  local output=$(render_agent_item "test-agent" 75 "Test description" 0 0)
  
  # Should not show description when not current
  if [[ "$output" != *"Test description"* ]]; then
    echo "✓ PASS: render_agent_item hides description when not current"
    ((++TESTS_PASSED))
  else
    echo "✗ FAIL: render_agent_item hides description when not current"
    ((++TESTS_FAILED))
  fi
  ((++TESTS_RUN))
}

# Test render_navigation_footer
test_render_navigation_footer_format() {
  local output=$(render_navigation_footer 5 10)
  
  assert_contains "$output" "5" "render_navigation_footer includes selected count"
  assert_contains "$output" "10" "render_navigation_footer includes total count"
}

test_render_navigation_footer_zero_selected() {
  local output=$(render_navigation_footer 0 10)
  
  assert_contains "$output" "0" "render_navigation_footer handles zero selections"
}

test_render_navigation_footer_all_selected() {
  local output=$(render_navigation_footer 10 10)
  
  assert_contains "$output" "10" "render_navigation_footer handles all selected"
}

# Run all tests
echo "Running rendering function tests..."
echo ""

test_render_confidence_bar_width
test_render_confidence_bar_format
test_render_confidence_bar_zero
test_render_confidence_bar_full

test_render_category_header_format
test_render_category_header_single_agent

test_render_agent_item_unselected
test_render_agent_item_selected
test_render_agent_item_current
test_render_agent_item_not_current

test_render_navigation_footer_format
test_render_navigation_footer_zero_selected
test_render_navigation_footer_all_selected

# Print summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Summary:"
echo "  Total:  $TESTS_RUN"
echo "  Passed: $TESTS_PASSED"
echo "  Failed: $TESTS_FAILED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
