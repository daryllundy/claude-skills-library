#!/usr/bin/env bash

# Integration tests for update operations in recommend_agents.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/recommend_agents.sh"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR" 2>/dev/null || true' EXIT

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

source_script_functions() {
  export AGENTS_DIR="$TEST_DIR/.claude/skills"
  export CACHE_DIR="$TEST_DIR/cache"
  export CACHE_EXPIRY_SECONDS=3600
  export FORCE_REFRESH=false
  export VERBOSE=false
  export BASE_URL="https://raw.githubusercontent.com/daryllundy/claude-agents/main/.claude/skills"
  export REGISTRY_FILENAME="SKILLS_REGISTRY.md"
  export ENTRYPOINT_FILENAME="skill.md"
  export MANIFEST_FILENAME="manifest.txt"

  eval "$(awk '/^log\(\) \{/,/^}/' "$SCRIPT")"
  eval "$(awk '/^init_cache\(\) \{/,/^}/' "$SCRIPT")"
  eval "$(awk '/^get_cache_path\(\) \{/,/^}/' "$SCRIPT")"
  eval "$(awk '/^is_cache_fresh\(\) \{/,/^}/' "$SCRIPT")"
  eval "$(awk '/^fetch_with_retry\(\) \{/,/^}/' "$SCRIPT")"
  eval "$(awk '/^fetch_with_cache\(\) \{/,/^}/' "$SCRIPT")"
  eval "$(awk '/^get_skill_dir\(\) \{/,/^}/' "$SCRIPT")"
  eval "$(awk '/^get_skill_entrypoint_path\(\) \{/,/^}/' "$SCRIPT")"
  eval "$(awk '/^get_skill_entrypoint_url\(\) \{/,/^}/' "$SCRIPT")"
  eval "$(awk '/^get_skill_manifest_url\(\) \{/,/^}/' "$SCRIPT")"
  eval "$(awk '/^download_skill\(\) \{/,/^}/' "$SCRIPT")"
  eval "$(awk '/^list_local_agents\(\) \{/,/^}/' "$SCRIPT")"
  eval "$(awk '/^check_updates\(\) \{/,/^}/' "$SCRIPT")"
  eval "$(awk '/^update_all_agents\(\) \{/,/^}/' "$SCRIPT")"
  eval "$(awk '/^parse_agent_registry\(\) \{/,/^}/' "$SCRIPT")"

  declare -gA AGENT_CATEGORIES
  declare -gA AGENT_DESCRIPTIONS
  declare -gA AGENT_USE_CASES
}

make_local_skill() {
  local name="$1"
  local content="${2:-# Skill}"
  mkdir -p "$AGENTS_DIR/$name/references" "$AGENTS_DIR/$name/scripts" "$AGENTS_DIR/$name/assets/templates"
  printf '%s\n' "$content" > "$AGENTS_DIR/$name/skill.md"
  printf 'skill.md\nreferences/.gitkeep\nscripts/.gitkeep\nassets/templates/.gitkeep\n' > "$AGENTS_DIR/$name/manifest.txt"
  : > "$AGENTS_DIR/$name/references/.gitkeep"
  : > "$AGENTS_DIR/$name/scripts/.gitkeep"
  : > "$AGENTS_DIR/$name/assets/templates/.gitkeep"
}

source_script_functions

test_check_updates_uses_cache() {
  run_test "check_updates should use fetch_with_cache for remote skill entrypoints"

  rm -rf "$AGENTS_DIR"
  mkdir -p "$AGENTS_DIR"
  make_local_skill "cache-test" "# Version 1"

  local marker_file="$TEST_DIR/fetch_cache_called"
  rm -f "$marker_file"

  fetch_with_cache() {
    echo "1" > "$marker_file"
    local output="$2"
    echo "# Version 2" > "$output"
    return 0
  }

  local output
  output=$(check_updates 2>/dev/null)

  if [[ -f "$marker_file" ]] && [[ "$(echo "$output" | tail -1)" == "1" ]]; then
    log_pass "check_updates used cached fetch path and detected the update"
  else
    log_fail "check_updates did not use fetch_with_cache as expected"
  fi

  source_script_functions
}

test_update_all_creates_backup_directory() {
  run_test "update_all_agents should back up skill directories before replacement"

  rm -rf "$AGENTS_DIR"
  mkdir -p "$AGENTS_DIR"
  make_local_skill "backup-test" "# Original Content"

  fetch_with_retry() {
    local url="$1"
    local output="$2"
    case "$url" in
      */manifest.txt) printf 'skill.md\n' > "$output" ;;
      */skill.md) printf '# Updated Content\n' > "$output" ;;
      *) return 1 ;;
    esac
    return 0
  }

  update_all_agents >/dev/null 2>&1

  local backup_dir
  backup_dir=$(find "$AGENTS_DIR" -type d -name ".backup_*" | head -n 1)

  if [[ -n "$backup_dir" ]] && [[ -f "$backup_dir/backup-test/skill.md" ]] && grep -q "Original Content" "$backup_dir/backup-test/skill.md"; then
    log_pass "Backup directory contains the original skill content"
  else
    log_fail "Backup directory was not created correctly"
  fi

  source_script_functions
}

test_update_all_rolls_forward_on_success() {
  run_test "update_all_agents should replace the local skill directory on success"

  rm -rf "$AGENTS_DIR"
  mkdir -p "$AGENTS_DIR"
  make_local_skill "success-test" "# Original Content"

  fetch_with_retry() {
    local url="$1"
    local output="$2"
    case "$url" in
      */manifest.txt) printf 'skill.md\n' > "$output" ;;
      */skill.md) printf '# Updated Content\n' > "$output" ;;
      *) return 1 ;;
    esac
    return 0
  }

  update_all_agents >/dev/null 2>&1

  if grep -q "Updated Content" "$AGENTS_DIR/success-test/skill.md"; then
    log_pass "Local skill directory was updated"
  else
    log_fail "Local skill directory was not updated"
  fi

  source_script_functions
}

test_parse_registry_fetches_skills_registry() {
  run_test "parse_agent_registry should fetch SKILLS_REGISTRY.md when missing"

  rm -rf "$AGENTS_DIR"
  mkdir -p "$AGENTS_DIR"

  fetch_with_cache() {
    local output="$2"
    cat > "$output" <<'EOF'
# Claude Skills Registry

## Available Skills

#### 1. test-specialist
- **Category**: Quality
- **Description**: Test skill
- **Use for**: Testing purposes
EOF
    return 0
  }

  if parse_agent_registry >/dev/null 2>&1 && [[ -f "$AGENTS_DIR/SKILLS_REGISTRY.md" ]] && [[ "${AGENT_DESCRIPTIONS[test-specialist]:-}" == "Test skill" ]]; then
    log_pass "Fetched and parsed the skills registry"
  else
    log_fail "Failed to fetch or parse the skills registry"
  fi

  source_script_functions
}

test_cache_hit_prevents_network_fetch() {
  run_test "Fresh cache should prevent a network fetch during update checks"

  rm -rf "$AGENTS_DIR" "$CACHE_DIR"
  mkdir -p "$AGENTS_DIR"
  make_local_skill "cache-hit-test" "# Local Skill"
  init_cache

  local url="${BASE_URL}/cache-hit-test/skill.md"
  local cache_file
  cache_file=$(get_cache_path "$url")
  echo "# Local Skill" > "$cache_file"
  touch "$cache_file"

  local retry_marker="$TEST_DIR/retry_called"
  rm -f "$retry_marker"

  fetch_with_retry() {
    echo "1" > "$retry_marker"
    return 1
  }

  check_updates >/dev/null 2>&1 || true

  if [[ ! -f "$retry_marker" ]]; then
    log_pass "Cache hit avoided a network retry"
  else
    log_fail "Cache hit still triggered fetch_with_retry"
  fi

  source_script_functions
}

test_force_refresh_bypasses_cache() {
  run_test "Force refresh should bypass the cache"

  rm -rf "$AGENTS_DIR" "$CACHE_DIR"
  mkdir -p "$AGENTS_DIR"
  make_local_skill "force-refresh-test" "# Local Skill"
  init_cache

  local url="${BASE_URL}/force-refresh-test/skill.md"
  local cache_file
  cache_file=$(get_cache_path "$url")
  echo "# Cached Skill" > "$cache_file"
  touch "$cache_file"

  export FORCE_REFRESH=true
  local retry_marker="$TEST_DIR/force_retry_called"
  rm -f "$retry_marker"

  fetch_with_retry() {
    echo "1" > "$retry_marker"
    local output="$2"
    echo "# Fresh Skill" > "$output"
    return 0
  }

  check_updates >/dev/null 2>&1 || true

  if [[ -f "$retry_marker" ]]; then
    log_pass "Force refresh bypassed the cache"
  else
    log_fail "Force refresh did not bypass the cache"
  fi

  export FORCE_REFRESH=false
  source_script_functions
}

echo "========================================="
echo "Update Operations Integration Tests"
echo "========================================="
echo ""

test_check_updates_uses_cache
test_update_all_creates_backup_directory
test_update_all_rolls_forward_on_success
test_parse_registry_fetches_skills_registry
test_cache_hit_prevents_network_fetch
test_force_refresh_bypasses_cache

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
