# Skill Recommendation Tests

Comprehensive test suite for the skill recommendation script enhancements.

## Test Structure

```
tests/
├── run_all_tests.sh           # Master test runner
├── unit/                      # Unit tests for individual functions
│   ├── test_detection_functions.sh
│   ├── test_confidence_scoring.sh
│   ├── test_profile_management.sh
│   └── test_update_detection.sh
├── integration/               # End-to-end integration tests
│   └── test_detection.sh
└── fixtures/                  # Test project fixtures
    ├── aws-terraform-project/
    ├── kubernetes-project/
    ├── multi-cloud-project/
    ├── react-frontend-project/
    └── empty-project/
```

## Running Tests

### Run All Tests
```bash
bash tests/run_all_tests.sh
```

### Run Specific Test Suite
```bash
# Unit tests
bash tests/unit/test_detection_functions.sh
bash tests/unit/test_confidence_scoring.sh
bash tests/unit/test_profile_management.sh
bash tests/unit/test_update_detection.sh

# Integration tests
bash tests/integration/test_detection.sh
```

## Test Coverage

### Unit Tests

#### Detection Functions (`test_detection_functions.sh`)
Tests the core detection functions used for pattern matching:
- `has_file()` - File existence detection with wildcards
- `has_path()` - Directory existence detection
- `file_contains()` - Content search within specific files
- `search_contents()` - Content search across all project files
- Git directory exclusion
- Nested path detection
- Case sensitivity
- Special character handling

**15 tests total**

#### Confidence Scoring (`test_confidence_scoring.sh`)
Tests the confidence calculation and scoring engine:
- Zero confidence for empty projects
- High confidence for strong pattern matches
- Confidence-based sorting (descending order)
- Threshold filtering
- Pattern weight accumulation
- Confidence capping at 100%
- DevOps orchestrator boost logic
- Recommendation tier categorization (✓ vs ~)
- Pattern weight display
- Consistency across multiple runs

**10 tests total**

#### Profile Management (`test_profile_management.sh`)
Tests export/import functionality:
- Valid JSON generation
- Required schema fields (version, timestamp, project_name, etc.)
- Agent metadata inclusion (confidence, category, patterns)
- Overwrite protection without --force
- Force overwrite functionality
- Import file validation
- Agent installation from profiles
- Directory creation
- Confidence threshold respect
- ISO 8601 timestamp format

**10 tests total**

#### Update Detection (`test_update_detection.sh`)
Tests update checking and installation:
- No skills installed handling
- Up-to-date agent detection
- Modified agent detection
- Backup directory creation
- Skipping current agents
- Update count reporting
- SKILLS_REGISTRY exclusion
- Network error handling
- Backup directory timestamp naming
- Content comparison accuracy

**10 tests total**

### Integration Tests

#### End-to-End Detection (`test_detection.sh`)
Tests complete detection workflows:
- AWS + Terraform project detection
- React frontend project detection
- Kubernetes project detection
- Multi-cloud orchestrator detection
- Empty project core skill recommendation
- Confidence filtering behavior
- Export functionality
- Verbose mode output
- Min-confidence validation
- Enhanced output formatting

**10 tests total**

#### Update Operations (`test_update_operations.sh`)
Tests update operations with retry and caching:
- check_updates using fetch_with_cache
- Network failure handling
- Backup creation before updates
- Rollback on update failure
- Update count reporting
- parse_agent_registry with caching
- Cache hit scenarios
- Cache miss scenarios
- Force refresh bypassing cache
- Retry logic with exponential backoff

**10 tests total**

## Test Fixtures

### aws-terraform-project
Simulates an AWS infrastructure project with Terraform:
- `main.tf` - Terraform configuration with AWS provider
- `variables.tf` - Terraform variables
- `terraform.tfvars` - Variable values

**Expected Detections**: aws-specialist, terraform-specialist

### kubernetes-project
Simulates a Kubernetes deployment project:
- `k8s/` directory with deployment manifests
- `Chart.yaml` - Helm chart definition
- `values.yaml` - Helm values
- `Dockerfile` - Container definition

**Expected Detections**: kubernetes-specialist, docker-specialist

### multi-cloud-project
Simulates a complex multi-cloud infrastructure:
- `.github/workflows/` - CI/CD pipelines
- `terraform/` - Multi-cloud Terraform configs
- `prometheus.yml` - Monitoring configuration

**Expected Detections**: devops-orchestrator, aws-specialist, azure-specialist, gcp-specialist, terraform-specialist, cicd-specialist, monitoring-specialist

### react-frontend-project
Simulates a React frontend application:
- `package.json` - NPM dependencies with React
- `src/components/` - React components
- `vitest.config.ts` - Test configuration

**Expected Detections**: frontend-specialist, test-specialist

### empty-project
Empty project directory for testing fallback behavior:
- `.gitkeep` - Empty marker file

**Expected Detections**: code-review-specialist, refactoring-specialist, test-specialist (core agents)

## Test Output

Tests use color-coded output for clarity:
- 🟡 **YELLOW** - Test name being executed
- 🟢 **GREEN** - Test passed
- 🔴 **RED** - Test failed
- 🔵 **BLUE** - Test suite headers

Example output:
```
[TEST] has_file should detect existing files
[PASS] Detected main.tf

[TEST] Confidence threshold should filter agents correctly
[PASS] Higher threshold filters more agents (8 agents at 15% vs 3 at 60%)
```

## Adding New Tests

### Unit Test Template
```bash
test_new_feature() {
  run_test "Description of what is being tested"
  
  # Setup
  cd "$FIXTURES/appropriate-fixture"
  
  # Execute
  local output=$(bash "$SCRIPT" --flags 2>&1)
  
  # Assert
  if echo "$output" | grep -q "expected-pattern"; then
    log_pass "Success message"
  else
    log_fail "Failure message"
  fi
}
```

### Integration Test Template
```bash
test_new_workflow() {
  run_test "End-to-end workflow description"
  
  cd "$FIXTURES/appropriate-fixture"
  local output=$(bash "$SCRIPT" --dry-run --flags 2>&1)
  
  if echo "$output" | grep -q "expected-agent"; then
    log_pass "Workflow completed successfully"
  else
    log_fail "Workflow did not complete as expected"
    echo "Output: $output"
  fi
}
```

### New Fixture
1. Create directory: `tests/fixtures/new-project-type/`
2. Add representative files for the technology
3. Document expected detections in this README
4. Add tests that use the fixture

## Continuous Integration

These tests are designed to run in CI/CD environments:
- No external dependencies required (except curl for network tests)
- Graceful handling of network failures
- Exit code 0 for success, 1 for failure
- Detailed output for debugging

## Troubleshooting

### Tests fail with "command not found"
Ensure scripts are executable:
```bash
chmod +x tests/**/*.sh
```

### Network-dependent tests fail
Some tests require internet access to fetch remote skill files. These tests gracefully skip if network is unavailable.

### Permission errors
Ensure you have write permissions in `/tmp/` directory where test artifacts are created.

### Fixture modifications
If you modify fixtures, ensure they still represent realistic project structures for accurate detection testing.

## Test Maintenance

- **Update fixtures** when adding new detection patterns
- **Add tests** for new features before implementation (TDD)
- **Run full suite** before committing changes
- **Document** expected behavior in test names and comments
- **Keep tests isolated** - each test should be independent

## Performance

Full test suite typically completes in:
- **Unit tests**: ~10-15 seconds
- **Integration tests**: ~5-10 seconds
- **Total**: ~15-25 seconds

Network-dependent tests may take longer depending on connection speed.
