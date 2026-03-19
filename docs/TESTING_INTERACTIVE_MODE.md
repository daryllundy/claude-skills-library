# Testing Interactive Mode

This document describes how to test the interactive selection mode of the skill recommendation script.

## Overview

The interactive mode allows users to browse and select agents through a text-based user interface (TUI). Testing this mode requires both unit tests for individual components and integration tests that simulate user interactions.

## Test Structure

```
tests/
├── unit/
│   ├── test_selection_state.sh      # Selection state management tests
│   └── test_rendering.sh            # UI rendering function tests
└── integration/
    ├── test_interactive.sh          # Bash wrapper for expect tests
    ├── test_interactive_navigation.exp
    ├── test_interactive_toggle.exp
    ├── test_interactive_select_all.exp
    ├── test_interactive_select_none.exp
    ├── test_interactive_confirm.exp
    └── test_interactive_quit.exp
```

## Prerequisites

### Required Tools

- **bash** (4.0+): For running the script and unit tests
- **expect**: For simulating interactive user input (integration tests only)

### Installing expect

**macOS:**
```bash
brew install expect
```

**Ubuntu/Debian:**
```bash
sudo apt-get install expect
```

**Fedora/RHEL:**
```bash
sudo dnf install expect
```

## Running Tests

### Run All Tests

To run the complete test suite including interactive tests:

```bash
bash tests/run_all_tests.sh
```

This will:
- Run all unit tests
- Run all integration tests
- Run interactive tests (if expect is installed)
- Display a summary of results

### Run Only Interactive Tests

To run just the interactive mode tests:

```bash
bash tests/integration/test_interactive.sh
```

### Run Individual Test Suites

**Selection State Tests:**
```bash
bash tests/unit/test_selection_state.sh
```

**Rendering Tests:**
```bash
bash tests/unit/test_rendering.sh
```

**Specific Interactive Test:**
```bash
expect tests/integration/test_interactive_navigation.exp
```

## Test Coverage

### Unit Tests

#### Selection State Management (`test_selection_state.sh`)

Tests the core selection logic:
- ✓ Initializing selection state with confidence threshold
- ✓ Toggling individual skill selection
- ✓ Selecting all agents
- ✓ Selecting none
- ✓ Getting selected agents list
- ✓ Counting selected agents

#### Rendering Functions (`test_rendering.sh`)

Tests UI rendering components:
- ✓ Confidence bar generation and formatting
- ✓ Category header display
- ✓ Agent item rendering (selected/unselected states)
- ✓ Navigation footer display
- ✓ Terminal width handling

### Integration Tests

#### Interactive Mode Tests (`.exp` files)

Tests complete user workflows:
- ✓ **Navigation**: Arrow key movement (up/down)
- ✓ **Toggle**: Space bar selection toggle
- ✓ **Select All**: 'a' key command
- ✓ **Select None**: 'n' key command
- ✓ **Confirm**: Enter key to accept selections
- ✓ **Quit**: 'q' key to cancel

## Writing New Tests

### Adding Unit Tests

1. Create a new test file in `tests/unit/`
2. Source or define the functions you're testing
3. Use the test helper functions:
   - `assert_equals expected actual test_name`
   - `assert_contains haystack needle test_name`
   - `assert_matches actual pattern test_name`
4. Track test results and print summary

Example:
```bash
#!/usr/bin/env bash

# Define function to test
my_function() {
  echo "result"
}

# Test it
TESTS_RUN=0
TESTS_PASSED=0

test_my_function() {
  local result=$(my_function)
  ((TESTS_RUN++))
  
  if [[ "$result" == "result" ]]; then
    echo "✓ PASS: my_function returns correct value"
    ((TESTS_PASSED++))
  else
    echo "✗ FAIL: my_function returns correct value"
  fi
}

test_my_function

echo "Tests: $TESTS_RUN, Passed: $TESTS_PASSED"
```

### Adding Integration Tests

1. Create a new `.exp` file in `tests/integration/`
2. Set timeout and test name
3. Spawn the script with appropriate flags
4. Use `expect` to wait for output
5. Use `send` to simulate user input
6. Check exit code and report results

Example:
```tcl
#!/usr/bin/expect -f

set timeout 5
set test_name "my_test"

spawn bash scripts/recommend_agents.sh --interactive --dry-run

expect "Interactive Mode"
send "a"  # Select all
send "\r" # Confirm

expect eof

catch wait result
set exit_code [lindex $result 3]

if {$exit_code == 0} {
    send_user "\n✓ PASS: $test_name\n"
    exit 0
} else {
    send_user "\n✗ FAIL: $test_name\n"
    exit 1
}
```

3. Make the file executable: `chmod +x tests/integration/my_test.exp`
4. The test will be automatically picked up by `test_interactive.sh`

## Troubleshooting

### Tests Fail in CI

If interactive tests fail in CI but pass locally:
- Check that expect is installed in the CI environment
- Verify terminal emulation is available
- Consider using `--dry-run` flag to avoid actual downloads
- Check timeout values (CI may be slower)

### Terminal Size Warnings

If you see warnings about terminal size:
- Resize your terminal to at least 60x20 (columns x rows)
- Or run in non-interactive mode for testing

### Expect Not Found

If you see "SKIP: Interactive tests require 'expect'":
- Install expect using your package manager
- Tests will automatically run once expect is available
- Unit tests will still run without expect

### Tests Hang

If tests appear to hang:
- Check timeout values in `.exp` files
- Verify the script isn't waiting for user input
- Use `--dry-run` to avoid network operations
- Check for infinite loops in the script

## CI Integration

The test suite is designed to work in CI environments:

- **Automatic Skipping**: Interactive tests are skipped if expect is unavailable
- **Exit Codes**: Proper exit codes for pass/fail/skip
- **No User Input**: All tests are fully automated
- **Fast Execution**: Tests complete in under 30 seconds

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install expect
        run: sudo apt-get install -y expect
      
      - name: Run tests
        run: bash tests/run_all_tests.sh
```

## Best Practices

1. **Keep Tests Fast**: Each test should complete in < 5 seconds
2. **Use Dry Run**: Use `--dry-run` flag to avoid network calls
3. **Test Edge Cases**: Include tests for empty lists, single items, etc.
4. **Clear Output**: Use descriptive test names and clear pass/fail messages
5. **Handle Failures**: Tests should clean up even when they fail
6. **Document Changes**: Update this doc when adding new test types

## Contributing

When adding new interactive features:

1. Write unit tests for new functions
2. Add integration tests for new user workflows
3. Update this documentation
4. Ensure all tests pass before submitting PR
5. Add tests to `run_all_tests.sh` if needed

## Support

For issues with testing:
- Check this documentation first
- Review existing test files for examples
- Open an issue with test output and environment details
