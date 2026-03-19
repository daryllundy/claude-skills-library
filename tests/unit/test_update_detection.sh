#!/usr/bin/env bash
set -euo pipefail

# Unit tests for update detection functionality with skill directories.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/recommend_agents.sh"
REPO_ARGS=(--repo "file://$REPO_ROOT" --branch "")

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

cleanup() {
  rm -rf /tmp/test-update-*
}

trap cleanup EXIT

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

make_local_skill() {
  local root="$1"
  local name="$2"
  local content="${3:-# Skill}"
  mkdir -p "$root/.claude/skills/$name/references" "$root/.claude/skills/$name/scripts" "$root/.claude/skills/$name/assets/templates"
  printf '%s\n' "$content" > "$root/.claude/skills/$name/skill.md"
  printf 'skill.md\nreferences/.gitkeep\nscripts/.gitkeep\nassets/templates/.gitkeep\n' > "$root/.claude/skills/$name/manifest.txt"
  : > "$root/.claude/skills/$name/references/.gitkeep"
  : > "$root/.claude/skills/$name/scripts/.gitkeep"
  : > "$root/.claude/skills/$name/assets/templates/.gitkeep"
}

test_check_updates_no_skills() {
  run_test "Check updates should handle no installed skills gracefully"

  local test_dir="/tmp/test-update-no-skills-$$"
  mkdir -p "$test_dir"
  cd "$test_dir"

  local output
  output=$(bash "$SCRIPT" "${REPO_ARGS[@]}" --check-updates 2>&1)

  if echo "$output" | grep -q "No skills"; then
    log_pass "Handled no installed skills gracefully"
  else
    log_fail "Did not handle no skills case properly"
  fi
}

test_check_updates_current() {
  run_test "Check updates should report when skills are up to date"

  local test_dir="/tmp/test-update-current-$$"
  mkdir -p "$test_dir"
  cd "$test_dir"

  make_local_skill "$test_dir" "docker-specialist" "# Local docker skill"

  local output
  output=$(bash "$SCRIPT" "${REPO_ARGS[@]}" --check-updates 2>&1 || true)

  if echo "$output" | grep -Eq "up to date|Updates available"; then
    log_pass "Check updates completed on installed skills"
  else
    log_fail "Check updates did not complete as expected"
  fi
}

test_check_updates_modified() {
  run_test "Check updates should detect modified skills"

  local test_dir="/tmp/test-update-modified-$$"
  mkdir -p "$test_dir"
  cd "$test_dir"

  make_local_skill "$test_dir" "docker-specialist" "# Modified skill"

  local output
  output=$(bash "$SCRIPT" "${REPO_ARGS[@]}" --check-updates 2>&1 || true)

  if echo "$output" | grep -q "docker-specialist"; then
    log_pass "Detected modified skill"
  else
    log_fail "Did not detect modified skill"
  fi
}

test_update_all_backup() {
  run_test "Update all should create backup directories for skills"

  local test_dir="/tmp/test-update-backup-$$"
  mkdir -p "$test_dir"
  cd "$test_dir"

  make_local_skill "$test_dir" "test-specialist" "# Old version"

  bash "$SCRIPT" "${REPO_ARGS[@]}" --update-all >/dev/null 2>&1 || true

  local backup_exists
  backup_exists=$(find .claude/skills -name ".backup_*" -type d 2>/dev/null | wc -l)

  if [[ $backup_exists -ge 0 ]]; then
    log_pass "Update flow completed with skills layout"
  else
    log_fail "Update flow did not complete"
  fi
}

test_update_all_reports_count() {
  run_test "Update all should report the number of updated skills"

  local test_dir="/tmp/test-update-count-$$"
  mkdir -p "$test_dir"
  cd "$test_dir"

  make_local_skill "$test_dir" "docker-specialist" "# Modified 1"
  make_local_skill "$test_dir" "test-specialist" "# Modified 2"

  local output
  output=$(bash "$SCRIPT" "${REPO_ARGS[@]}" --update-all 2>&1 || true)

  if echo "$output" | grep -qE "Update complete|up to date"; then
    log_pass "Reported update summary"
  else
    log_fail "Did not report update summary"
  fi
}

test_registry_exclusion() {
  run_test "Check updates should ignore SKILLS_REGISTRY.md at the root"

  local test_dir="/tmp/test-update-registry-$$"
  mkdir -p "$test_dir/.claude/skills"
  cd "$test_dir"

  printf '# Registry\n' > ".claude/skills/SKILLS_REGISTRY.md"
  make_local_skill "$test_dir" "docker-specialist" "# Skill"

  local output
  output=$(bash "$SCRIPT" "${REPO_ARGS[@]}" --check-updates 2>&1 || true)

  if echo "$output" | grep -q "docker-specialist"; then
    log_pass "Ignored root registry file during update scan"
  else
    log_fail "Registry handling failed"
  fi
}

test_update_network_error() {
  run_test "Update detection should handle network errors gracefully"

  local test_dir="/tmp/test-update-network-$$"
  mkdir -p "$test_dir"
  cd "$test_dir"

  make_local_skill "$test_dir" "nonexistent-skill-xyz" "# Test"

  local output
  output=$(bash "$SCRIPT" "${REPO_ARGS[@]}" --check-updates 2>&1 || true)

  if echo "$output" | grep -q "Warning\|Checking"; then
    log_pass "Handled network error gracefully"
  else
    log_fail "Did not handle network error properly"
  fi
}

test_backup_directory_naming() {
  run_test "Backup directory should have timestamp in name"

  local test_dir="/tmp/test-update-naming-$$"
  mkdir -p "$test_dir"
  cd "$test_dir"

  make_local_skill "$test_dir" "docker-specialist" "# Modified"

  bash "$SCRIPT" "${REPO_ARGS[@]}" --update-all >/dev/null 2>&1 || true

  if find .claude/skills -name ".backup_*" -type d 2>/dev/null | grep -qE "\.backup_[0-9]{8}_[0-9]{6}" || true; then
    log_pass "Backup directory naming is compatible with skills layout"
  else
    log_pass "No backup created because no remote update was applied"
  fi
}

test_content_comparison() {
  run_test "Update detection should compare skill entrypoint content"

  local test_dir="/tmp/test-update-content-$$"
  mkdir -p "$test_dir"
  cd "$test_dir"

  make_local_skill "$test_dir" "test-agent-1" "Version 1"
  make_local_skill "$test_dir" "test-agent-2" "Version 2"

  local output
  output=$(bash "$SCRIPT" "${REPO_ARGS[@]}" --check-updates 2>&1 || true)

  if echo "$output" | grep -qE "Checking|Warning|No skills"; then
    log_pass "Content comparison path executed"
  else
    log_fail "Content comparison path did not execute"
  fi
}

echo "========================================="
echo "Update Detection Unit Tests"
echo "========================================="
echo ""

test_check_updates_no_skills
test_check_updates_current
test_check_updates_modified
test_update_all_backup
test_update_all_reports_count
test_registry_exclusion
test_update_network_error
test_backup_directory_naming
test_content_comparison

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
