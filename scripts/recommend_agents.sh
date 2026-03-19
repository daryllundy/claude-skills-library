#!/usr/bin/env bash
if [[ -z "${BASH_VERSINFO:-}" || "${BASH_VERSINFO[0]}" -lt 4 ]]; then
  if [[ -x /opt/homebrew/bin/bash ]]; then
    exec /opt/homebrew/bin/bash "$0" "$@"
  fi
  echo "Error: recommend_agents.sh requires bash 4+." >&2
  exit 1
fi
set -euo pipefail

# Script to scan a project and download recommended Claude Code skills.
# Intended usage:
#   curl -sSL https://raw.githubusercontent.com/daryllundy/claude-agents/main/scripts/recommend_agents.sh | bash
# If you clone the claude-agents repository locally you can also run the script directly.

REPO_SLUG="daryllundy/claude-agents"
DEFAULT_BRANCH="main"

CLAUDE_AGENTS_BRANCH="${CLAUDE_AGENTS_BRANCH:-$DEFAULT_BRANCH}"
CLAUDE_AGENTS_REPO="${CLAUDE_AGENTS_REPO:-https://raw.githubusercontent.com/${REPO_SLUG}}"
BASE_URL="${CLAUDE_AGENTS_REPO}/${CLAUDE_AGENTS_BRANCH}/.claude/skills"

AGENTS_DIR=".claude/skills"
REGISTRY_FILENAME="SKILLS_REGISTRY.md"
ENTRYPOINT_FILENAME="skill.md"
MANIFEST_FILENAME="manifest.txt"
DRY_RUN=false

# Agent metadata storage
declare -A AGENT_CATEGORIES
declare -A AGENT_DESCRIPTIONS
declare -A AGENT_USE_CASES

# Detection pattern storage (format: "type:pattern:weight" per line)
declare -A AGENT_PATTERNS

print_help() {
  cat <<'USAGE'
Claude Code Skill Recommender
=============================

Scans the current project and downloads Claude Code skill directories that
match the detected technologies.

Usage:
  recommend_agents.sh [options]

Options:
  --dry-run              Only print recommended skills without downloading.
  --force                Redownload skill files even if they already exist locally.
  --min-confidence NUM   Only recommend skills with confidence >= NUM (0-100).
  --verbose              Display detailed detection results with all patterns checked.
  --debug-confidence [SKILL]  Show detailed confidence calculation for skill(s).
  --show-max-weights     Display maximum possible weights for all detected skills.
  --interactive          Enter interactive mode to manually select skills.
  --export FILE          Export detection profile to JSON file.
  --import FILE          Import and install skills from a profile JSON file.
  --check-updates        Check for updates to locally installed skills.
  --update-all           Update all locally installed skills to latest versions.
  --force-refresh        Bypass cache and fetch fresh content from network.
  --clear-cache          Remove all cached files and exit.
  --cache-dir DIR        Specify custom cache directory location.
  --cache-expiry SECS    Set cache expiry time in seconds (default: 86400).
  --branch NAME          Override the claude-agents branch to download from.
  --repo URL             Override the base raw URL for the claude-agents repository.
  --patterns-dir DIR     Specify custom pattern directory location.
  -h, --help             Show this help message.

Environment variables:
  CLAUDE_AGENTS_BRANCH    Override the branch (default: main).
  CLAUDE_AGENTS_REPO      Override the raw content base URL.
  AGENT_PATTERNS_DIR      Override the pattern directory location.

USAGE
}

FORCE=false
MIN_CONFIDENCE=25  # Default minimum confidence threshold
VERBOSE=false
INTERACTIVE=false
EXPORT_FILE=""
IMPORT_FILE=""
CHECK_UPDATES=false
UPDATE_ALL=false
DEBUG_CONFIDENCE=""
SHOW_MAX_WEIGHTS=false
FORCE_REFRESH=false
CLEAR_CACHE_FLAG=false
PATTERNS_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --force)
      FORCE=true
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --debug-confidence)
      shift
      if [[ $# -gt 0 ]] && [[ ! "$1" =~ ^-- ]]; then
        DEBUG_CONFIDENCE="$1"
        shift
      else
        DEBUG_CONFIDENCE="all"
      fi
      ;;
    --show-max-weights)
      SHOW_MAX_WEIGHTS=true
      shift
      ;;
    --interactive)
      INTERACTIVE=true
      shift
      ;;
    --export)
      shift
      [[ $# -gt 0 ]] || { echo "Missing value for --export" >&2; exit 1; }
      EXPORT_FILE="$1"
      shift
      ;;
    --import)
      shift
      [[ $# -gt 0 ]] || { echo "Missing value for --import" >&2; exit 1; }
      IMPORT_FILE="$1"
      shift
      ;;
    --check-updates)
      CHECK_UPDATES=true
      shift
      ;;
    --update-all)
      UPDATE_ALL=true
      shift
      ;;
    --force-refresh)
      FORCE_REFRESH=true
      shift
      ;;
    --clear-cache)
      CLEAR_CACHE_FLAG=true
      shift
      ;;
    --cache-dir)
      shift
      [[ $# -gt 0 ]] || { echo "Missing value for --cache-dir" >&2; exit 1; }
      CACHE_DIR="$1"
      shift
      ;;
    --cache-dir=*)
      CACHE_DIR="${1#*=}"
      shift
      ;;
    --cache-expiry)
      shift
      [[ $# -gt 0 ]] || { echo "Missing value for --cache-expiry" >&2; exit 1; }
      if ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "Error: --cache-expiry must be a positive number" >&2
        exit 1
      fi
      CACHE_EXPIRY_SECONDS="$1"
      shift
      ;;
    --cache-expiry=*)
      CACHE_EXPIRY_SECONDS="${1#*=}"
      if ! [[ "$CACHE_EXPIRY_SECONDS" =~ ^[0-9]+$ ]]; then
        echo "Error: --cache-expiry must be a positive number" >&2
        exit 1
      fi
      shift
      ;;
    --min-confidence)
      shift
      [[ $# -gt 0 ]] || { echo "Missing value for --min-confidence" >&2; exit 1; }
      if ! [[ "$1" =~ ^[0-9]+$ ]] || [[ "$1" -lt 0 ]] || [[ "$1" -gt 100 ]]; then
        echo "Error: --min-confidence must be a number between 0 and 100" >&2
        exit 1
      fi
      MIN_CONFIDENCE="$1"
      shift
      ;;
    --branch)
      shift
      [[ $# -gt 0 ]] || { echo "Missing value for --branch" >&2; exit 1; }
      CLAUDE_AGENTS_BRANCH="$1"
      BASE_URL="${CLAUDE_AGENTS_REPO}/${CLAUDE_AGENTS_BRANCH}/.claude/skills"
      shift
      ;;
    --repo)
      shift
      [[ $# -gt 0 ]] || { echo "Missing value for --repo" >&2; exit 1; }
      CLAUDE_AGENTS_REPO="$1"
      BASE_URL="${CLAUDE_AGENTS_REPO}/${CLAUDE_AGENTS_BRANCH}/.claude/skills"
      shift
      ;;
    --patterns-dir)
      shift
      [[ $# -gt 0 ]] || { echo "Missing value for --patterns-dir" >&2; exit 1; }
      PATTERNS_DIR="$1"
      shift
      ;;
    --patterns-dir=*)
      PATTERNS_DIR="${1#*=}"
      shift
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      print_help >&2
      exit 1
      ;;
  esac
done

log() {
  printf '[agent-setup] %s\n' "$*"
}

# Handle --clear-cache flag early (before other operations)
if [[ $CLEAR_CACHE_FLAG == true ]]; then
  # Cache directory for downloaded files (use default if not overridden)
  CACHE_DIR="${CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/claude-agents}"
  
  if [[ ! -d "$CACHE_DIR" ]]; then
    log "Cache directory does not exist: $CACHE_DIR"
    exit 0
  fi
  
  log "Clearing cache directory: $CACHE_DIR"
  
  # Count files before clearing
  file_count=0
  if [[ -n "$(ls -A "$CACHE_DIR" 2>/dev/null)" ]]; then
    file_count=$(find "$CACHE_DIR" -type f | wc -l | xargs)
  fi
  
  # Remove all files in cache directory
  if rm -rf "${CACHE_DIR:?}"/* 2>/dev/null; then
    if [[ $file_count -gt 0 ]]; then
      log "Successfully cleared $file_count cached file(s)"
    else
      log "Cache directory was already empty"
    fi
    exit 0
  else
    echo "Error: Failed to clear cache directory: $CACHE_DIR" >&2
    exit 1
  fi
fi

# Enhanced error handling (Task 11)

# Cache directory for downloaded files
CACHE_DIR="${CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/claude-agents}"
CACHE_EXPIRY_SECONDS="${CACHE_EXPIRY_SECONDS:-$((24 * 60 * 60))}"  # 24 hours default

# Initialize cache directory
init_cache() {
  if [[ ! -d "$CACHE_DIR" ]]; then
    mkdir -p "$CACHE_DIR" 2>/dev/null || {
      echo "Warning: Could not create cache directory: $CACHE_DIR" >&2
      return 1
    }
  fi
  return 0
}

# Get cache path for a URL
get_cache_path() {
  local url="$1"
  local url_hash
  
  if command -v md5 &> /dev/null; then
    url_hash=$(echo -n "$url" | md5)
  elif command -v md5sum &> /dev/null; then
    url_hash=$(echo -n "$url" | md5sum | cut -d' ' -f1)
  else
    # Fallback: use simple hash
    url_hash=$(echo -n "$url" | cksum | cut -d' ' -f1)
  fi
  
  echo "$CACHE_DIR/$url_hash"
}

# Check if cache is fresh
is_cache_fresh() {
  local cache_file="$1"
  local expiry="${2:-$CACHE_EXPIRY_SECONDS}"
  
  if [[ ! -f "$cache_file" ]]; then
    return 1
  fi
  
  local current_time=$(date +%s)
  local file_time
  
  # Platform-specific stat command
  if [[ "$(uname)" == "Darwin" ]]; then
    file_time=$(stat -f %m "$cache_file" 2>/dev/null || echo "0")
  else
    file_time=$(stat -c %Y "$cache_file" 2>/dev/null || echo "0")
  fi
  
  local age=$((current_time - file_time))
  
  [[ $age -lt $expiry ]]
}

# Fetch with caching support
fetch_with_cache() {
  local url="$1"
  local output="$2"
  local expiry="${3:-$CACHE_EXPIRY_SECONDS}"
  
  # Use global FORCE_REFRESH flag if set
  local force_refresh="${FORCE_REFRESH:-false}"
  
  init_cache || return 1
  
  local cache_file
  cache_file=$(get_cache_path "$url")
  
  # Use cache if fresh and not forcing refresh
  if [[ $force_refresh == false ]] && is_cache_fresh "$cache_file" "$expiry"; then
    if [[ ${VERBOSE:-false} == true ]]; then
      log "Using cached version of $(basename "$url")"
    fi
    cp "$cache_file" "$output"
    return 0
  fi
  
  # Fetch and cache
  if [[ ${VERBOSE:-false} == true ]] && [[ $force_refresh == true ]]; then
    log "Force refresh enabled, bypassing cache for $(basename "$url")"
  fi
  
  if fetch_with_retry "$url" "$output"; then
    cp "$output" "$cache_file" 2>/dev/null || true
    return 0
  fi
  
  return 1
}

# Network error handling with retry and exponential backoff
fetch_with_retry() {
  local url="$1"
  local output="$2"
  local max_attempts="${3:-3}"
  local timeout="${4:-30}"
  local attempt=1
  local backoff=2

  while [[ $attempt -le $max_attempts ]]; do
    # Try to fetch with timeout
    if curl -fsSL --max-time "$timeout" "$url" -o "$output" 2>/dev/null; then
      if [[ ${VERBOSE:-false} == true ]]; then
        log "Successfully downloaded $(basename "$url")"
      fi
      return 0
    fi

    # Get HTTP status code for better error messages
    local http_code=$(curl -fsSL -w "%{http_code}" --max-time "$timeout" -o /dev/null "$url" 2>/dev/null || echo "000")

    if [[ $attempt -lt $max_attempts ]]; then
      log "Attempt $attempt/$max_attempts failed (HTTP $http_code). Retrying in ${backoff}s..."
      sleep $backoff
      ((backoff *= 2))  # Exponential backoff
      ((++attempt))
    else
      echo "Error: Failed to download from $url after $max_attempts attempts (HTTP $http_code)" >&2

      # Provide troubleshooting suggestions based on error code
      case "$http_code" in
        000)
          echo "Troubleshooting: Check your internet connection and try again" >&2
          ;;
        404)
          echo "Troubleshooting: The agent file was not found. It may have been removed or renamed" >&2
          ;;
        403|401)
          echo "Troubleshooting: Access denied. Check if the repository is accessible" >&2
          ;;
        500|502|503|504)
          echo "Troubleshooting: Server error. The repository may be temporarily unavailable" >&2
          ;;
        *)
          echo "Troubleshooting: Unexpected error. Please check the repository URL and try again" >&2
          ;;
      esac

      return 1
    fi
  done

  return 1
}

# Input validation
validate_arguments() {
  # Check for mutually exclusive flags
  local mode_count=0
  [[ -n "$IMPORT_FILE" ]] && ((++mode_count))
  [[ $CHECK_UPDATES == true ]] && ((++mode_count))
  [[ $UPDATE_ALL == true ]] && ((++mode_count))

  if [[ $mode_count -gt 1 ]]; then
    echo "Error: --import, --check-updates, and --update-all are mutually exclusive" >&2
    echo "Use only one of these flags at a time" >&2
    exit 1
  fi

  # Validate min-confidence already done in argument parsing

  # Validate export file path
  if [[ -n "$EXPORT_FILE" ]]; then
    local export_dir=$(dirname "$EXPORT_FILE")
    if [[ ! -d "$export_dir" ]] && [[ "$export_dir" != "." ]]; then
      echo "Error: Export directory does not exist: $export_dir" >&2
      echo "Please create the directory first or specify a valid path" >&2
      exit 1
    fi
  fi

  # Validate import file existence
  if [[ -n "$IMPORT_FILE" ]] && [[ ! -f "$IMPORT_FILE" ]]; then
    echo "Error: Import file not found: $IMPORT_FILE" >&2
    echo "Please check the file path and try again" >&2
    exit 1
  fi
}

# Call validation after argument parsing
validate_arguments

has_file() {
  local pattern="$1"
  find . -path './.git' -prune -o -name "$pattern" -print -quit | grep -q .
}

has_path() {
  local path="$1"
  if [[ -d "$path" ]]; then
    return 0
  fi
  if [[ "$path" == */* ]]; then
    find . -path './.git' -prune -o -path "./$path" -print -quit | grep -q .
  else
    find . -path './.git' -prune -o -type d -name "$path" -print -quit | grep -q .
  fi
}

file_contains() {
  local file="$1"
  local pattern="$2"
  if [[ -f "$file" ]]; then
    if command -v rg >/dev/null 2>&1; then
      rg --quiet --fixed-strings "$pattern" "$file"
      return $?
    else
      grep -qF "$pattern" "$file"
      return $?
    fi
  fi
  return 1
}

search_contents() {
  local pattern="$1"
  if command -v rg >/dev/null 2>&1; then
    rg --quiet --fixed-strings "$pattern" --glob '!*.git/*' .
    return $?
  else
    grep -Rqs --exclude-dir='.git' "$pattern" .
    return $?
  fi
}

# Enhanced output formatting functions (Task 6)

# Draw a progress bar for confidence visualization
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

# Get recommendation symbol based on confidence
get_recommendation_symbol() {
  local confidence="$1"
  if [[ $confidence -ge 50 ]]; then
    echo "✓"  # Recommended
  else
    echo "~"  # Suggested
  fi
}

# Display agent with details
display_agent_details() {
  local agent="$1"
  local confidence="${agent_confidence[$agent]:-0}"
  local symbol=$(get_recommendation_symbol "$confidence")
  local description="${AGENT_DESCRIPTIONS[$agent]:-No description available}"
  local matched_patterns="${agent_matched_patterns[$agent]:-}"
  local use_case=$(get_use_case_safe "$agent")

  printf "  %s %s " "$symbol" "$agent"
  draw_progress_bar "$confidence"
  printf " %d%%\n" "$confidence"

  # Show description
  if [[ -n "$description" ]]; then
    printf "    %s\n" "$description"
  fi

  # Show use case
  if [[ -n "$use_case" ]] && [[ "$use_case" != "No use case information available" ]]; then
    printf "    Use for: %s\n" "$use_case"
  fi

  # Show matched patterns if not verbose (verbose shows all patterns later)
  if [[ ! $VERBOSE == true ]] && [[ -n "$matched_patterns" ]]; then
    printf "    Detected: %s\n" "$matched_patterns"
  fi

  echo ""
}

# Display categorized results
display_categorized_results() {
  # Define category order
  local -a categories=(
    "Infrastructure (Cloud)"
    "Infrastructure (IaC)"
    "Infrastructure (Platform)"
    "Infrastructure (Containers)"
    "Infrastructure (Monitoring)"
    "Development"
    "Quality"
    "Operations"
    "Productivity"
    "Business"
    "Specialized"
  )

  echo ""
  echo "═══════════════════════════════════════════════════════════════════════"
  echo "                     Agent Recommendation Results"
  echo "═══════════════════════════════════════════════════════════════════════"
  echo ""
  echo "Found ${#recommended_agents[@]} recommended agents"
  echo ""

  # Group agents by category
  declare -A category_agents
  for agent in "${recommended_agents[@]}"; do
    local category="${AGENT_CATEGORIES[$agent]:-Uncategorized}"
    if [[ -z "${category_agents[$category]:-}" ]]; then
      category_agents[$category]="$agent"
    else
      category_agents[$category]="${category_agents[$category]} $agent"
    fi
  done

  # Display agents by category
  for category in "${categories[@]}"; do
    if [[ -n "${category_agents[$category]:-}" ]]; then
      # Split agents string into array
      IFS=' ' read -ra agents <<< "${category_agents[$category]}"

      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "$category (${#agents[@]} skill(s))"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""

      for agent in "${agents[@]}"; do
        display_agent_details "$agent"
      done
    fi
  done

  # Display uncategorized agents if any
  if [[ -n "${category_agents[Uncategorized]:-}" ]]; then
    IFS=' ' read -ra agents <<< "${category_agents[Uncategorized]}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Other (${#agents[@]} skill(s))"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    for agent in "${agents[@]}"; do
      display_agent_details "$agent"
    done
  fi

  echo "═══════════════════════════════════════════════════════════════════════"
  echo ""
  echo "Legend:"
  echo "  ✓ = Recommended (50%+)    ~ = Suggested (25-49%)"
  echo ""
}

# Task 16: Performance optimization with caching
declare -A USE_CASE_WRAP_CACHE

# Format use case with caching
format_use_case_cached() {
  local text="$1"
  local width="${2:-60}"
  local indent="${3:-0}"

  # Generate cache key
  local cache_key="${text}:${width}:${indent}"

  # Check if cached result exists
  if [[ -n "${USE_CASE_WRAP_CACHE[$cache_key]:-}" ]]; then
    echo "${USE_CASE_WRAP_CACHE[$cache_key]}"
    return 0
  fi

  # Format and cache the result
  local formatted
  formatted=$(format_use_case "$text" "$width" "$indent")
  USE_CASE_WRAP_CACHE[$cache_key]="$formatted"

  echo "$formatted"
}

# UI Rendering functions (Task 2)

# Get terminal width
get_terminal_width() {
  local width=80
  
  if command -v tput &> /dev/null; then
    width=$(tput cols 2>/dev/null || echo "80")
  elif command -v stty &> /dev/null; then
    width=$(stty size 2>/dev/null | cut -d' ' -f2 || echo "80")
  fi
  
  echo "$width"
}

# Format use case text with wrapping
format_use_case() {
  local text="$1"
  local width="${2:-60}"
  local indent="${3:-0}"
  
  if [[ -z "$text" ]]; then
    echo ""
    return
  fi
  
  # Simple word wrapping
  local indent_str=$(printf "%${indent}s" "")
  echo "$text" | fold -s -w "$width" | sed "s/^/$indent_str/"
}

# Format use case with automatic width detection
format_use_case_auto() {
  local text="$1"
  local indent="${2:-0}"
  
  local term_width
  term_width=$(get_terminal_width)
  
  # Use 80% of terminal width, minimum 40
  local wrap_width=$((term_width * 80 / 100))
  [[ $wrap_width -lt 40 ]] && wrap_width=40
  
  format_use_case "$text" "$wrap_width" "$indent"
}

# Get use case safely with fallback
get_use_case_safe() {
  local agent="$1"
  local use_case="${AGENT_USE_CASES[$agent]:-}"
  
  if [[ -z "$use_case" ]]; then
    if [[ ${VERBOSE:-false} == true ]]; then
      log "  Warning: No use case defined for $agent"
    fi
    echo "No use case information available"
  else
    echo "$use_case"
  fi
}

# Task 10: Validate use cases for all agents
# Returns: 0 if all agents have use cases, 1 if some are missing
validate_use_cases() {
  local missing_count=0
  local total_count=0
  local -a missing_agents=()

  # Check all agents that have patterns
  for agent in "${!AGENT_PATTERNS[@]}"; do
    ((++total_count))
    local use_case="${AGENT_USE_CASES[$agent]:-}"

    if [[ -z "$use_case" ]]; then
      ((++missing_count))
      missing_agents+=("$agent")
    fi
  done

  if [[ $missing_count -gt 0 ]]; then
    if [[ ${VERBOSE:-false} == true ]]; then
      log "Warning: $missing_count of $total_count agents are missing use case metadata:"
      for agent in "${missing_agents[@]}"; do
        log "  - $agent"
      done
    fi
    return 1
  else
    if [[ ${VERBOSE:-false} == true ]]; then
      log "✓ All $total_count agents have use case metadata"
    fi
    return 0
  fi
}

# Render category header
render_category_header() {
  local category="$1"
  local count="$2"

  echo ""
  echo "━━ $category ($count skill(s)) ━━"
  echo ""
}

# Render confidence bar (alias to existing function for consistency)
render_confidence_bar() {
  draw_progress_bar "$@"
}

# Render agent item
render_agent_item() {
  local agent="$1"
  local confidence="$2"
  local description="$3"
  local is_selected="$4"
  local is_current="$5"
  local use_case="${6:-}"
  
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
  
  # Show description and use case if it's the current selection
  if [[ $is_current -eq 1 ]]; then
    if [[ -n "$description" ]]; then
      printf "      %s\n" "$description"
    fi
    if [[ -n "$use_case" ]] && [[ "$use_case" != "No use case information available" ]]; then
      printf "      Use for: %s\n" "$use_case"
    fi
  fi
}

# Render navigation footer
render_navigation_footer() {
  local selected_count="$1"
  local total_count="$2"
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Selected: $selected_count / $total_count agents"
}

# Render complete agent list
render_agent_list() {
  local current_index="$1"
  local -n agents_ref=$2
  local -n confidence_ref=$3
  local -n descriptions_ref=$4
  local -n categories_ref=$5
  local -n use_cases_ref=$6
  
  clear
  echo "═══════════════════════════════════════════════════════════════════════"
  echo "            Agent Recommendation - Interactive Mode"
  echo "═══════════════════════════════════════════════════════════════════════"
  echo ""
  echo "Use arrow keys to navigate, SPACE to toggle, ENTER to confirm"
  echo "Commands: a=select all, n=select none, q=quit"
  
  # Group agents by category for display
  declare -A category_agents
  for agent in "${agents_ref[@]}"; do
    local category="${categories_ref[$agent]:-Uncategorized}"
    if [[ -z "${category_agents[$category]}" ]]; then
      category_agents[$category]="$agent"
    else
      category_agents[$category]="${category_agents[$category]} $agent"
    fi
  done
  
  local display_index=0
  local -a categories=("Infrastructure (Cloud)" "Infrastructure (IaC)" "Infrastructure (Platform)" "Infrastructure (Containers)" "Infrastructure (Monitoring)" "Development" "Quality" "Operations" "Productivity" "Business" "Specialized" "Uncategorized")
  
  for category in "${categories[@]}"; do
    if [[ -n "${category_agents[$category]}" ]]; then
      # Count agents in category
      IFS=' ' read -ra agents <<< "${category_agents[$category]}"
      local category_count=${#agents[@]}
      
      render_category_header "$category" "$category_count"
      
      for agent in "${agents[@]}"; do
        local confidence="${confidence_ref[$agent]:-0}"
        local description="${descriptions_ref[$agent]:-}"
        local use_case="${use_cases_ref[$agent]:-}"
        
        # Determine if this is the current selection
        local is_current=0
        if [[ $display_index -eq $current_index ]]; then
          is_current=1
        fi
        
        # Determine if this agent is selected
        local is_selected=${SELECTION_STATE[$agent]:-0}
        
        render_agent_item "$agent" "$confidence" "$description" "$is_selected" "$is_current" "$use_case"
        
        ((++display_index))
      done
    fi
  done
  
  local selected_count=$(get_selection_count)
  render_navigation_footer "$selected_count" "${#agents_ref[@]}"
}

# Selection state management functions (Task 1)

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
      ((++count))
    fi
  done
  
  echo "$count"
}

# Check terminal capabilities for interactive mode
check_terminal_capabilities() {
  # Check if terminal supports required features
  if [[ ! -t 0 ]] || [[ ! -t 1 ]]; then
    echo "Error: Interactive mode requires a terminal (stdin and stdout must be TTY)" >&2
    return 1
  fi
  
  # Check terminal size
  local rows cols
  if command -v stty &> /dev/null; then
    read rows cols < <(stty size 2>/dev/null || echo "24 80")
  else
    rows=24
    cols=80
  fi
  
  if [[ $rows -lt 20 ]] || [[ $cols -lt 60 ]]; then
    echo "Warning: Terminal size (${rows}x${cols}) may be too small for optimal display" >&2
    echo "Recommended minimum: 20 rows x 60 columns" >&2
    echo ""
  fi
  
  return 0
}

# Cleanup terminal state
cleanup_terminal() {
  # Restore terminal settings
  if command -v stty &> /dev/null; then
    stty sane 2>/dev/null || true
  fi
  
  # Show cursor
  if command -v tput &> /dev/null; then
    tput cnorm 2>/dev/null || true
  else
    printf '\033[?25h' # ANSI escape code to show cursor
  fi
  
  # Clear screen on exit
  clear 2>/dev/null || true
}

# Safe wrapper for interactive selection with fallback
safe_interactive_selection() {
  if ! check_terminal_capabilities; then
    echo "Falling back to automatic selection (confidence >= 50%)" >&2
    echo ""
    
    # Auto-select agents with confidence >= 50%
    recommended_agents=()
    for agent in "${!agent_confidence[@]}"; do
      if [[ ${agent_confidence[$agent]} -ge 50 ]]; then
        recommended_agents+=("$agent")
      fi
    done
    
    log "Auto-selected ${#recommended_agents[@]} agents based on confidence threshold"
    return 0
  fi
  
  # Set up signal handlers for terminal cleanup
  trap cleanup_terminal EXIT INT TERM
  
  # Terminal is capable, proceed with interactive mode
  interactive_selection
  
  # Clean up after successful completion
  cleanup_terminal
}

# Handle keyboard input and return new state
# Returns: new_index action
# action can be: continue, confirm, quit
handle_keyboard_input() {
  local key="$1"
  local current_index="$2"
  local -n agents_ref=$3
  local max_index=$((${#agents_ref[@]} - 1))
  
  local action="continue"
  
  # Handle special keys (arrow keys start with escape sequence)
  if [[ $key == $'\x1b' ]]; then
    read -rsn2 key
    case "$key" in
      '[A')  # Up arrow
        if [[ $current_index -gt 0 ]]; then
          ((current_index--))
        fi
        ;;
      '[B')  # Down arrow
        if [[ $current_index -lt $max_index ]]; then
          ((++current_index))
        fi
        ;;
    esac
  else
    case "$key" in
      ' ')  # Space - toggle selection
        local agent="${agents_ref[$current_index]}"
        toggle_agent_selection "$agent"
        ;;
      '')  # Enter - confirm selection
        action="confirm"
        ;;
      'a'|'A')  # Select all
        select_all_agents agents_ref
        ;;
      'n'|'N')  # Select none
        select_none_agents agents_ref
        ;;
      'q'|'Q')  # Quit
        action="quit"
        ;;
    esac
  fi
  
  echo "$current_index $action"
}

# Interactive selection mode (Task 7)
interactive_selection() {
  local -a agent_list=("${recommended_agents[@]}")
  local current_index=0

  # Initialize selection state using new function
  init_selection_state agent_list agent_confidence 50

  # Main interactive loop
  while true; do
    # Render UI using extracted function
    render_agent_list "$current_index" agent_list agent_confidence AGENT_DESCRIPTIONS AGENT_CATEGORIES AGENT_USE_CASES

    # Read single character
    read -rsn1 key

    # Handle input and get new state
    read new_index action < <(handle_keyboard_input "$key" "$current_index" agent_list)
    current_index=$new_index
    
    # Check action
    case "$action" in
      confirm)
        break
        ;;
      quit)
        echo ""
        log "Cancelled by user"
        exit 0
        ;;
    esac
  done

  clear

  # Return selected agents by updating recommended_agents array using new function
  recommended_agents=()
  while IFS= read -r agent; do
    [[ -n "$agent" ]] && recommended_agents+=("$agent")
  done < <(get_selected_agents)

  log "Selected ${#recommended_agents[@]} agents for installation"
}

# Profile export functionality (Task 8)
export_profile() {
  local output_file="$1"

  # Check if file exists (unless --force is used)
  if [[ -f "$output_file" ]] && [[ $FORCE == false ]]; then
    echo "Error: File already exists: $output_file (use --force to overwrite)" >&2
    exit 1
  fi

  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local project_name=$(basename "$PWD")

  # Start JSON
  cat > "$output_file" <<EOF
{
  "version": "1.0",
  "generated_at": "$timestamp",
  "project_name": "$project_name",
  "detection_results": {
    "agents_recommended": [
EOF

  # Add agents
  local first=true
  for agent in "${recommended_agents[@]}"; do
    [[ $first == false ]] && echo "," >> "$output_file"
    first=false

    local confidence="${agent_confidence[$agent]:-0}"
    local category="${AGENT_CATEGORIES[$agent]:-Uncategorized}"
    local matched_patterns="${agent_matched_patterns[$agent]:-}"
    local use_case="${AGENT_USE_CASES[$agent]:-}"

    # Convert matched patterns to JSON array
    local patterns_json="[]"
    if [[ -n "$matched_patterns" ]]; then
      patterns_json="["
      local first_pattern=true
      for pattern in $matched_patterns; do
        [[ $first_pattern == false ]] && patterns_json="$patterns_json,"
        first_pattern=false
        # Escape quotes in pattern
        pattern=$(echo "$pattern" | sed 's/"/\\"/g')
        patterns_json="$patterns_json\"$pattern\""
      done
      patterns_json="$patterns_json]"
    fi

    # Escape use case for JSON
    local use_case_escaped=$(echo "$use_case" | sed 's/"/\\"/g' | sed 's/\\/\\\\/g')

    cat >> "$output_file" <<EOF
      {
        "name": "$agent",
        "confidence": $confidence,
        "category": "$category",
        "use_case": "$use_case_escaped",
        "patterns_matched": $patterns_json
      }
EOF
  done

  # Close agents array and add selected agents
  cat >> "$output_file" <<EOF

    ]
  },
  "selected_agents": [
EOF

  # Add selected agents list
  first=true
  for agent in "${recommended_agents[@]}"; do
    [[ $first == false ]] && echo "," >> "$output_file"
    first=false
    echo -n "    \"$agent\"" >> "$output_file"
  done

  # Close JSON
  cat >> "$output_file" <<EOF

  ]
}
EOF

  log "Profile exported to $output_file"
}

# Profile import functionality (Task 9)
import_profile() {
  local input_file="$1"

  # Validate file exists
  if [[ ! -f "$input_file" ]]; then
    echo "Error: Profile file not found: $input_file" >&2
    exit 1
  fi

  log "Importing profile from $input_file"

  # Check if we have jq for JSON parsing, otherwise use grep/sed
  if ! command -v jq >/dev/null 2>&1; then
    # Basic JSON parsing without jq
    log "Warning: jq not found, using basic JSON parsing"

    # Extract selected_agents array (simple parsing)
    local agents_json=$(grep -A 100 '"selected_agents"' "$input_file" | sed -n '/\[/,/\]/p' | grep '"' | sed 's/.*"\([^"]*\)".*/\1/')

    if [[ -z "$agents_json" ]]; then
      echo "Error: Could not parse selected_agents from profile" >&2
      exit 1
    fi

    # Download each skill
    local count=0
    while IFS= read -r agent; do
      [[ -z "$agent" ]] && continue
      log "Installing skill: $agent"
      fetch_agent "$agent"
      ((++count))
    done <<< "$agents_json"

    log "Successfully installed $count skills from profile"
  else
    # Use jq for proper JSON parsing
    # Validate JSON
    if ! jq empty "$input_file" 2>/dev/null; then
      echo "Error: Invalid JSON in profile file" >&2
      exit 1
    fi

    # Extract selected agents
    local -a agents
    mapfile -t agents < <(jq -r '.selected_agents[]?' "$input_file")

    if [[ ${#agents[@]} -eq 0 ]]; then
      echo "Error: No skills found in profile" >&2
      exit 1
    fi

    log "Found ${#agents[@]} skills in profile"

    # Fetch skills registry to validate skills exist
    parse_agent_registry

    # Download skills
    local count=0
    for agent in "${agents[@]}"; do
      [[ -z "$agent" ]] && continue

      # Validate skill exists in registry (if registry was parsed)
      if [[ ${#AGENT_DESCRIPTIONS[@]} -gt 0 ]] && [[ -z "${AGENT_DESCRIPTIONS[$agent]}" ]]; then
        log "Warning: Skill '$agent' not found in registry, attempting to download anyway"
      fi

      log "Installing skill: $agent"
      fetch_agent "$agent"
      ((++count))
    done

    log "Successfully installed $count skills from profile"
  fi
}

# Update detection functionality (Task 10)
get_skill_dir() {
  local agent="$1"
  echo "${AGENTS_DIR}/${agent}"
}

get_skill_entrypoint_path() {
  local agent="$1"
  echo "$(get_skill_dir "$agent")/${ENTRYPOINT_FILENAME}"
}

get_skill_entrypoint_url() {
  local agent="$1"
  echo "${BASE_URL}/${agent}/${ENTRYPOINT_FILENAME}"
}

get_skill_manifest_url() {
  local agent="$1"
  echo "${BASE_URL}/${agent}/${MANIFEST_FILENAME}"
}

download_skill() {
  local agent="$1"
  local destination_root="$2"
  local fetch_function="${3:-fetch_with_retry}"
  local skill_dir="${destination_root}/${agent}"
  local manifest_file
  manifest_file=$(mktemp)
  mkdir -p "$skill_dir"

  if ! "$fetch_function" "$(get_skill_manifest_url "$agent")" "$manifest_file"; then
    echo "${ENTRYPOINT_FILENAME}" > "$manifest_file"
  fi

  while IFS= read -r relative_path; do
    [[ -z "$relative_path" ]] && continue
    local destination="${skill_dir}/${relative_path}"
    mkdir -p "$(dirname "$destination")"
    if ! "$fetch_function" "${BASE_URL}/${agent}/${relative_path}" "$destination"; then
      rm -f "$manifest_file"
      return 1
    fi
  done < "$manifest_file"

  cp "$manifest_file" "${skill_dir}/${MANIFEST_FILENAME}"
  rm -f "$manifest_file"
  return 0
}

list_local_agents() {
  local -a local_agents=()
  if [[ -d "$AGENTS_DIR" ]]; then
    while IFS= read -r dir; do
      [[ -z "$dir" ]] && continue
      local agent
      agent=$(basename "$dir")
      [[ "$agent" == .* ]] && continue
      [[ -f "${dir}/${ENTRYPOINT_FILENAME}" ]] || continue
      local_agents+=("$agent")
    done < <(find "$AGENTS_DIR" -mindepth 1 -maxdepth 1 -type d | sort)
  fi
  printf '%s\n' "${local_agents[@]}"
}

check_updates() {
  local -a local_agents
  if [[ ! -d "$AGENTS_DIR" ]]; then
    log "No skills directory found. No skills to check."
    return 0
  fi

  while IFS= read -r agent; do
    [[ -n "$agent" ]] && local_agents+=("$agent")
  done < <(list_local_agents)

  if [[ ${#local_agents[@]} -eq 0 ]]; then
    log "No skills installed locally"
    return 0
  fi

  log "Checking for updates to ${#local_agents[@]} locally installed skills..."

  local -a updates_available=()

  for agent in "${local_agents[@]}"; do
    local local_file
    local_file=$(get_skill_entrypoint_path "$agent")
    local temp_file
    temp_file=$(mktemp)

    if fetch_with_cache "$(get_skill_entrypoint_url "$agent")" "$temp_file" 3600; then
      local local_content
      local_content=$(cat "$local_file")
      local remote_content
      remote_content=$(cat "$temp_file")

      if [[ "$remote_content" != "$local_content" ]]; then
        updates_available+=("$agent")
      fi
      
      rm -f "$temp_file"
    else
      log "Warning: Could not fetch remote version of $agent"
      rm -f "$temp_file"
      continue
    fi
  done

  if [[ ${#updates_available[@]} -eq 0 ]]; then
    log "All skills are up to date ✓"
  else
    log "Updates available for ${#updates_available[@]} skill(s):"
    for agent in "${updates_available[@]}"; do
      log "  - $agent"
    done
    log ""
    log "Run with --update-all to update all skills"
  fi

  echo "${#updates_available[@]}"
}

update_all_agents() {
  local -a local_agents
  if [[ ! -d "$AGENTS_DIR" ]]; then
    log "No skills directory found. No skills to update."
    return 0
  fi

  while IFS= read -r agent; do
    [[ -n "$agent" ]] && local_agents+=("$agent")
  done < <(list_local_agents)

  if [[ ${#local_agents[@]} -eq 0 ]]; then
    log "No skills installed locally"
    return 0
  fi

  log "Checking and updating ${#local_agents[@]} skills..."

  local updated_count=0
  local failed_count=0
  local backup_dir="${AGENTS_DIR}/.backup_$(date +%Y%m%d_%H%M%S)"

  for agent in "${local_agents[@]}"; do
    local local_dir
    local_dir=$(get_skill_dir "$agent")
    local local_file
    local_file=$(get_skill_entrypoint_path "$agent")
    local temp_root
    temp_root=$(mktemp -d)

    if ! download_skill "$agent" "$temp_root" fetch_with_retry; then
      log "✗ Failed to fetch remote version of $agent"
      rm -rf "$temp_root"
      ((++failed_count))
      continue
    fi

    local local_content
    local_content=$(cat "$local_file")
    local remote_content
    remote_content=$(cat "${temp_root}/${agent}/${ENTRYPOINT_FILENAME}")

    if [[ "$remote_content" != "$local_content" ]]; then
      if [[ ! -d "$backup_dir" ]]; then
        mkdir -p "$backup_dir"
      fi

      if ! cp -R "$local_dir" "${backup_dir}/${agent}"; then
        log "✗ Failed to create backup for $agent"
        rm -rf "$temp_root"
        ((++failed_count))
        continue
      fi

      log "Updating $agent..."

      rm -rf "$local_dir"
      if cp -R "${temp_root}/${agent}" "$local_dir"; then
        log "✓ Updated $agent"
        ((++updated_count))
      else
        log "✗ Failed to update $agent"
        rm -rf "$local_dir"
        if [[ -d "${backup_dir}/${agent}" ]]; then
          cp -R "${backup_dir}/${agent}" "$local_dir"
          log "Restored $agent from backup"
        fi
        ((++failed_count))
      fi
    fi

    rm -rf "$temp_root"
  done

  log ""
  if [[ $updated_count -eq 0 ]] && [[ $failed_count -eq 0 ]]; then
    log "All skills were already up to date ✓"
  else
    log "Update complete: $updated_count updated, $failed_count failed"
    if [[ -d "$backup_dir" ]]; then
      log "Backups saved to $backup_dir"
    fi
  fi

  # Return success if no failures
  [[ $failed_count -eq 0 ]]
}

# Parse SKILLS_REGISTRY.md to extract skill metadata
parse_agent_registry() {
  local registry_file="${AGENTS_DIR}/${REGISTRY_FILENAME}"

  if [[ ! -f "$registry_file" ]]; then
    log "Skills registry not found locally, attempting to fetch..."
    mkdir -p "$AGENTS_DIR"
    local registry_url="${BASE_URL}/${REGISTRY_FILENAME}"

    if fetch_with_cache "$registry_url" "$registry_file" 3600; then
      log "✓ Successfully fetched skills registry"
    else
      log "✗ Failed to fetch skills registry. Using built-in metadata."
      return 1
    fi
  fi

  local current_agent=""
  local in_agent_section=false

  while IFS= read -r line; do
    if [[ $line =~ ^####[[:space:]]+[0-9]+\.[[:space:]]+(.+)$ ]]; then
      current_agent="${BASH_REMATCH[1]}"
      in_agent_section=true
      continue
    fi

    if [[ $line =~ ^##[[:space:]]+ ]] && [[ ! $line =~ ^####[[:space:]]+ ]]; then
      in_agent_section=false
      current_agent=""
      continue
    fi

    if [[ -n "$current_agent" ]] && [[ "$in_agent_section" == true ]]; then
      if [[ $line =~ ^\*\*Category\*\*:[[:space:]]+(.+)$ ]]; then
        AGENT_CATEGORIES[$current_agent]="${BASH_REMATCH[1]}"
      fi

      if [[ $line =~ ^\*\*Description\*\*:[[:space:]]+(.+)$ ]]; then
        AGENT_DESCRIPTIONS[$current_agent]="${BASH_REMATCH[1]}"
      fi

      if [[ $line =~ ^\*\*Use\ for\*\*:[[:space:]]+(.+)$ ]]; then
        AGENT_USE_CASES[$current_agent]="${BASH_REMATCH[1]}"
      fi
    fi
  done < "$registry_file"
  
  return 0
}

# Check for YAML parser availability
# Returns: "yq", "python3", or exits with error
check_yaml_parser() {
  if command -v yq &> /dev/null; then
    echo "yq"
    return 0
  elif command -v python3 &> /dev/null; then
    # Check if PyYAML is available
    if python3 -c "import yaml" &> /dev/null; then
      echo "python3"
      return 0
    else
      echo "Error: python3 found but PyYAML module is not installed" >&2
      echo "Install with: pip3 install pyyaml" >&2
      return 1
    fi
  else
    echo "Error: No YAML parser found. Install yq or python3 with PyYAML" >&2
    echo "Install with: brew install yq  (or)  pip3 install pyyaml" >&2
    return 1
  fi
}

# Parse YAML using yq
# Args: $1 - YAML file path
# Returns: JSON output on stdout
parse_yaml_with_yq() {
  local file="$1"
  
  if [[ ! -f "$file" ]]; then
    echo "Error: File not found: $file" >&2
    return 1
  fi
  
  # Use yq to convert YAML to JSON
  if ! yq eval -o=json "$file" 2>/dev/null; then
    echo "Error: Failed to parse YAML file with yq: $file" >&2
    return 1
  fi
  
  return 0
}

# Parse YAML using Python
# Args: $1 - YAML file path
# Returns: JSON output on stdout
parse_yaml_with_python() {
  local file="$1"
  
  if [[ ! -f "$file" ]]; then
    echo "Error: File not found: $file" >&2
    return 1
  fi
  
  # Use Python with PyYAML to convert YAML to JSON
  python3 -c "
import yaml
import json
import sys

try:
    with open('$file', 'r') as f:
        data = yaml.safe_load(f)
        if data is None:
            print('Error: Empty or invalid YAML file', file=sys.stderr)
            sys.exit(1)
        print(json.dumps(data))
except yaml.YAMLError as e:
    print(f'Error: YAML parsing failed: {e}', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: Failed to parse YAML file: {e}', file=sys.stderr)
    sys.exit(1)
"
  
  return $?
}

# Parse YAML file to JSON (wrapper function)
# Args: $1 - YAML file path
# Returns: JSON output on stdout
parse_yaml() {
  local file="$1"
  local parser
  
  # Detect available parser
  parser=$(check_yaml_parser) || return 1
  
  # Use appropriate parser
  case "$parser" in
    yq)
      parse_yaml_with_yq "$file"
      ;;
    python3)
      parse_yaml_with_python "$file"
      ;;
    *)
      echo "Error: Unknown parser: $parser" >&2
      return 1
      ;;
  esac
}

# Task 10: Check dependencies for pattern loading
# Returns: 0 if all dependencies available, 1 if missing dependencies
check_dependencies() {
  local missing_deps=()
  local platform=$(uname -s)

  # Check for jq (required for schema validation and JSON parsing)
  if ! command -v jq &> /dev/null; then
    missing_deps+=("jq")
  fi

  # Check for YAML parser (yq or python3 with PyYAML)
  local yaml_parser_available=false

  if command -v yq &> /dev/null; then
    yaml_parser_available=true
  elif command -v python3 &> /dev/null; then
    if python3 -c "import yaml" &> /dev/null; then
      yaml_parser_available=true
    fi
  fi

  if [[ $yaml_parser_available == false ]]; then
    missing_deps+=("yaml-parser")
  fi

  # If dependencies are missing, show installation instructions
  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    echo "Error: Missing required dependencies for pattern loading" >&2
    echo "" >&2

    for dep in "${missing_deps[@]}"; do
      case "$dep" in
        jq)
          echo "  • jq - Required for JSON processing and schema validation" >&2
          echo "" >&2
          case "$platform" in
            Darwin)
              echo "    Install with: brew install jq" >&2
              ;;
            Linux)
              echo "    Install with: sudo apt-get install jq  (Debian/Ubuntu)" >&2
              echo "                  sudo yum install jq      (RHEL/CentOS)" >&2
              ;;
            *)
              echo "    Install from: https://stedolan.github.io/jq/download/" >&2
              ;;
          esac
          echo "" >&2
          ;;
        yaml-parser)
          echo "  • YAML parser - Required for parsing pattern files" >&2
          echo "" >&2
          echo "    Option 1: Install yq" >&2
          case "$platform" in
            Darwin)
              echo "      brew install yq" >&2
              ;;
            Linux)
              echo "      Download from: https://github.com/mikefarah/yq/releases" >&2
              ;;
            *)
              echo "      Download from: https://github.com/mikefarah/yq/releases" >&2
              ;;
          esac
          echo "" >&2
          echo "    Option 2: Install Python 3 with PyYAML" >&2
          echo "      pip3 install pyyaml" >&2
          echo "" >&2
          ;;
      esac
    done

    return 1
  fi

  return 0
}

# Task 9: Setup patterns directory with priority resolution
# Priority: CLI flag > environment variable > default location
# Returns: patterns directory path on stdout, exits on error if directory invalid
setup_patterns_directory() {
  local patterns_dir=""
  local script_dir
  local source_file="${BASH_SOURCE[0]:-}"
  [[ -z "$source_file" ]] && source_file="$0"
  script_dir="$(cd "$(dirname "$source_file")" && pwd)"

  # Priority 1: CLI flag
  if [[ -n "${PATTERNS_DIR}" ]]; then
    patterns_dir="$PATTERNS_DIR"
    if [[ ! -d "$patterns_dir" ]]; then
      echo "Error: Pattern directory specified via --patterns-dir does not exist: $patterns_dir" >&2
      echo "Please create the directory or specify a valid path" >&2
      return 1
    fi
    if [[ ${VERBOSE:-false} == true ]]; then
      log "Using pattern directory from CLI: $patterns_dir" >&2
    fi
  # Priority 2: Environment variable
  elif [[ -n "${AGENT_PATTERNS_DIR:-}" ]]; then
    patterns_dir="$AGENT_PATTERNS_DIR"
    if [[ ! -d "$patterns_dir" ]]; then
      echo "Error: Pattern directory specified via AGENT_PATTERNS_DIR does not exist: $patterns_dir" >&2
      echo "Please create the directory or set a valid path" >&2
      return 1
    fi
    if [[ ${VERBOSE:-false} == true ]]; then
      log "Using pattern directory from environment: $patterns_dir" >&2
    fi
  # Priority 3: Default locations
  else
    # Try multiple default locations
    for candidate in \
      "${script_dir}/../data/patterns" \
      "${script_dir}/data/patterns" \
      "data/patterns" \
      ".claude/patterns"
    do
      if [[ -d "$candidate" ]]; then
        patterns_dir="$candidate"
        break
      fi
    done

    if [[ -z "$patterns_dir" ]]; then
      # No default directory found
      if [[ ${VERBOSE:-false} == true ]]; then
        log "No pattern directory found in default locations" >&2
      fi
      return 1
    fi

    if [[ ${VERBOSE:-false} == true ]]; then
      log "Using default pattern directory: $patterns_dir" >&2
    fi
  fi

  echo "$patterns_dir"
  return 0
}

# Task 5: Discover pattern files in directory
# Args: $1 - patterns directory path
# Returns: List of YAML files (one per line) on stdout
discover_pattern_files() {
  local patterns_dir="$1"

  if [[ ! -d "$patterns_dir" ]]; then
    echo "Error: Pattern directory not found: $patterns_dir" >&2
    return 1
  fi

  # Find all .yml and .yaml files in the patterns directory
  local -a pattern_files=()

  while IFS= read -r file; do
    [[ -n "$file" ]] && pattern_files+=("$file")
  done < <(find "$patterns_dir" -maxdepth 1 -type f \( -name "*.yml" -o -name "*.yaml" \) 2>/dev/null | sort)

  if [[ ${#pattern_files[@]} -eq 0 ]]; then
    if [[ ${VERBOSE:-false} == true ]]; then
      log "No pattern files found in $patterns_dir" >&2
    fi
    return 1
  fi

  if [[ ${VERBOSE:-false} == true ]]; then
    log "Discovered ${#pattern_files[@]} pattern file(s) in $patterns_dir" >&2
  fi

  # Output files one per line
  printf '%s\n' "${pattern_files[@]}"
  return 0
}

# Task 6: Validate pattern schema using jq
# Args: $1 - JSON string to validate
# Returns: 0 if valid, 1 if invalid
validate_pattern_schema() {
  local json_data="$1"

  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    echo "Error: jq is required for schema validation but not found" >&2
    return 1
  fi

  # Validate top-level structure
  if ! echo "$json_data" | jq -e '.version' &> /dev/null; then
    echo "Error: Missing required field 'version'" >&2
    return 1
  fi

  if ! echo "$json_data" | jq -e '.agents' &> /dev/null; then
    echo "Error: Missing required field 'agents'" >&2
    return 1
  fi

  # Validate agents is an array
  if ! echo "$json_data" | jq -e '.agents | type == "array"' &> /dev/null; then
    echo "Error: Field 'agents' must be an array" >&2
    return 1
  fi

  # Validate each agent has required fields
  local agent_count
  agent_count=$(echo "$json_data" | jq '.agents | length')

  for ((i=0; i<agent_count; i++)); do
    # Check for name field
    if ! echo "$json_data" | jq -e ".agents[$i].name" &> /dev/null; then
      echo "Error: Agent at index $i missing required field 'name'" >&2
      return 1
    fi

    # Check for patterns field
    if ! echo "$json_data" | jq -e ".agents[$i].patterns" &> /dev/null; then
      local agent_name
      agent_name=$(echo "$json_data" | jq -r ".agents[$i].name")
      echo "Error: Agent '$agent_name' missing required field 'patterns'" >&2
      return 1
    fi

    # Validate patterns is an array
    if ! echo "$json_data" | jq -e ".agents[$i].patterns | type == \"array\"" &> /dev/null; then
      local agent_name
      agent_name=$(echo "$json_data" | jq -r ".agents[$i].name")
      echo "Error: Agent '$agent_name' field 'patterns' must be an array" >&2
      return 1
    fi

    # Validate each pattern
    local pattern_count
    pattern_count=$(echo "$json_data" | jq ".agents[$i].patterns | length")

    for ((j=0; j<pattern_count; j++)); do
      # Check pattern has required fields
      if ! echo "$json_data" | jq -e ".agents[$i].patterns[$j].type" &> /dev/null; then
        local agent_name
        agent_name=$(echo "$json_data" | jq -r ".agents[$i].name")
        echo "Error: Agent '$agent_name' pattern at index $j missing required field 'type'" >&2
        return 1
      fi

      if ! echo "$json_data" | jq -e ".agents[$i].patterns[$j].match" &> /dev/null; then
        local agent_name
        agent_name=$(echo "$json_data" | jq -r ".agents[$i].name")
        echo "Error: Agent '$agent_name' pattern at index $j missing required field 'match'" >&2
        return 1
      fi

      if ! echo "$json_data" | jq -e ".agents[$i].patterns[$j].weight" &> /dev/null; then
        local agent_name
        agent_name=$(echo "$json_data" | jq -r ".agents[$i].name")
        echo "Error: Agent '$agent_name' pattern at index $j missing required field 'weight'" >&2
        return 1
      fi

      # Validate pattern type
      local pattern_type
      pattern_type=$(echo "$json_data" | jq -r ".agents[$i].patterns[$j].type")

      if [[ "$pattern_type" != "file" ]] && [[ "$pattern_type" != "path" ]] && [[ "$pattern_type" != "content" ]]; then
        local agent_name
        agent_name=$(echo "$json_data" | jq -r ".agents[$i].name")
        echo "Error: Agent '$agent_name' pattern at index $j has invalid type '$pattern_type' (must be file, path, or content)" >&2
        return 1
      fi

      # Validate weight is a number
      if ! echo "$json_data" | jq -e ".agents[$i].patterns[$j].weight | type == \"number\"" &> /dev/null; then
        local agent_name
        agent_name=$(echo "$json_data" | jq -r ".agents[$i].name")
        echo "Error: Agent '$agent_name' pattern at index $j has non-numeric weight" >&2
        return 1
      fi
    done
  done

  return 0
}

# Task 7: Load pattern file and populate data structures
# Args: $1 - pattern file path
# Returns: 0 on success, 1 on failure
load_pattern_file() {
  local pattern_file="$1"

  if [[ ! -f "$pattern_file" ]]; then
    echo "Error: Pattern file not found: $pattern_file" >&2
    return 1
  fi

  if [[ ${VERBOSE:-false} == true ]]; then
    log "Loading pattern file: $(basename "$pattern_file")"
  fi

  # Parse YAML to JSON
  local json_data
  if ! json_data=$(parse_yaml "$pattern_file"); then
    echo "Error: Failed to parse YAML file: $pattern_file" >&2
    return 1
  fi

  # Validate schema
  if ! validate_pattern_schema "$json_data"; then
    echo "Error: Schema validation failed for: $pattern_file" >&2
    return 1
  fi

  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    echo "Error: jq is required for pattern loading but not found" >&2
    return 1
  fi

  # Extract and populate agent data
  local agent_count
  agent_count=$(echo "$json_data" | jq '.agents | length')

  local loaded_count=0

  for ((i=0; i<agent_count; i++)); do
    local agent_name
    agent_name=$(echo "$json_data" | jq -r ".agents[$i].name")

    # Extract description if present
    local description
    description=$(echo "$json_data" | jq -r ".agents[$i].description // empty")
    if [[ -n "$description" ]]; then
      AGENT_DESCRIPTIONS[$agent_name]="$description"
    fi

    # Extract category if present
    local category
    category=$(echo "$json_data" | jq -r ".agents[$i].category // empty")
    if [[ -n "$category" ]]; then
      AGENT_CATEGORIES[$agent_name]="$category"
    fi

    # Extract use_case if present
    local use_case
    use_case=$(echo "$json_data" | jq -r ".agents[$i].use_case // empty")
    if [[ -n "$use_case" ]]; then
      AGENT_USE_CASES[$agent_name]="$use_case"
    fi

    # Extract patterns and build pattern string
    local pattern_count
    pattern_count=$(echo "$json_data" | jq ".agents[$i].patterns | length")

    local pattern_buffer=""

    for ((j=0; j<pattern_count; j++)); do
      local type
      local match
      local weight

      type=$(echo "$json_data" | jq -r ".agents[$i].patterns[$j].type")
      match=$(echo "$json_data" | jq -r ".agents[$i].patterns[$j].match")
      weight=$(echo "$json_data" | jq -r ".agents[$i].patterns[$j].weight")

      # Append to pattern buffer in format "type:match:weight\n"
      pattern_buffer+="${type}:${match}:${weight}"$'\n'
    done

    # Store patterns for agent (merge with existing if any)
    if [[ -n "${AGENT_PATTERNS[$agent_name]:-}" ]]; then
      # Append to existing patterns
      AGENT_PATTERNS[$agent_name]="${AGENT_PATTERNS[$agent_name]}${pattern_buffer}"
    else
      # Set new patterns
      AGENT_PATTERNS[$agent_name]="$pattern_buffer"
    fi

    ((++loaded_count))
  done

  if [[ ${VERBOSE:-false} == true ]]; then
    log "  Loaded $loaded_count skill pattern set(s) from $(basename "$pattern_file")"
  fi

  return 0
}

# Task 8: Load all pattern files from directory
# Args: $1 - patterns directory path
# Returns: 0 on success, 1 if no files loaded
load_pattern_files() {
  local patterns_dir="$1"

  # Discover pattern files
  local -a pattern_files=()
  while IFS= read -r file; do
    [[ -n "$file" ]] && pattern_files+=("$file")
  done < <(discover_pattern_files "$patterns_dir" 2>/dev/null)

  if [[ ${#pattern_files[@]} -eq 0 ]]; then
    echo "Error: No pattern files found in directory: $patterns_dir" >&2
    return 1
  fi

  if [[ ${VERBOSE:-false} == true ]]; then
    log "Loading patterns from ${#pattern_files[@]} file(s)"
  fi

  # Load each pattern file
  local loaded_files=0
  local failed_files=0
  local total_agents=0

  for pattern_file in "${pattern_files[@]}"; do
    # Skip example files
    if [[ "$(basename "$pattern_file")" == "example.yml" ]] || [[ "$(basename "$pattern_file")" == "example.yaml" ]]; then
      if [[ ${VERBOSE:-false} == true ]]; then
        log "Skipping example file: $(basename "$pattern_file")"
      fi
      continue
    fi

    if load_pattern_file "$pattern_file"; then
      ((++loaded_files))
    else
      ((++failed_files))
      echo "Warning: Failed to load pattern file: $pattern_file" >&2
    fi
  done

  # Count total agents loaded
  if [[ -n "${!AGENT_PATTERNS[@]}" ]]; then
    total_agents="${#AGENT_PATTERNS[@]}"
  fi

  if [[ $loaded_files -eq 0 ]]; then
    echo "Error: Failed to load any pattern files" >&2
    return 1
  fi

  if [[ ${VERBOSE:-false} == true ]]; then
    log "Successfully loaded $loaded_files file(s), $failed_files failed"
    log "Total agents with patterns: $total_agents"
  else
    echo "✓ Loaded $total_agents agent detection patterns from $loaded_files file(s)" >&2
  fi

  return 0
}

# Parse YAML pattern file and populate AGENT_PATTERNS (LEGACY - used as fallback)
# Returns 0 on success, 1 if file not found or parse error
parse_yaml_patterns() {
  local yaml_file="$1"

  # Check if file exists
  if [[ ! -f "$yaml_file" ]]; then
    return 1
  fi

  local current_agent=""
  local in_patterns=false
  local pattern_buffer=""
  local current_type=""
  local current_pattern=""
  local current_weight=""

  while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue

    # Detect agent name (2-space indent, followed by colon)
    # Skip top-level keys like "version" and "agents"
    if [[ "$line" =~ ^[[:space:]]{2}([a-z0-9-]+):$ ]]; then
      local agent_name="${BASH_REMATCH[1]}"

      # Skip metadata keys
      if [[ "$agent_name" == "agents" || "$agent_name" == "version" ]]; then
        continue
      fi

      # Save previous agent's patterns if any
      if [[ -n "$current_agent" && -n "$pattern_buffer" ]]; then
        AGENT_PATTERNS["$current_agent"]="$pattern_buffer"
      fi

      # Start new agent
      current_agent="$agent_name"
      pattern_buffer=""
      in_patterns=false
      current_type=""
      current_pattern=""
      current_weight=""
      continue
    fi

    # Detect patterns section for current agent (4-space indent)
    if [[ -n "$current_agent" && "$line" =~ ^[[:space:]]{4}patterns:$ ]]; then
      in_patterns=true
      current_type=""
      current_pattern=""
      current_weight=""
      continue
    fi

    # Parse pattern fields when in patterns section
    if [[ "$in_patterns" == true ]]; then
      # Parse pattern array items (6-space indent, starting with "- type:")
      if [[ "$line" =~ ^[[:space:]]{6}-[[:space:]]+type:[[:space:]]*(.+)$ ]]; then
        # Save previous pattern if complete
        if [[ -n "$current_type" && -n "$current_pattern" && -n "$current_weight" ]]; then
          pattern_buffer+="${current_type}:${current_pattern}:${current_weight}"$'\n'
        fi
        # Start new pattern and extract type
        current_type="${BASH_REMATCH[1]}"
        current_pattern=""
        current_weight=""
        continue
      fi

      # Extract pattern (8-space indent, handle quoted and unquoted strings)
      if [[ "$line" =~ ^[[:space:]]{8}pattern:[[:space:]]*\"(.+)\"$ ]]; then
        current_pattern="${BASH_REMATCH[1]}"
        continue
      elif [[ "$line" =~ ^[[:space:]]{8}pattern:[[:space:]]*\'(.+)\'$ ]]; then
        current_pattern="${BASH_REMATCH[1]}"
        continue
      elif [[ "$line" =~ ^[[:space:]]{8}pattern:[[:space:]]*(.+)$ ]]; then
        current_pattern="${BASH_REMATCH[1]}"
        # Remove quotes if present
        current_pattern="${current_pattern%\"}"
        current_pattern="${current_pattern#\"}"
        current_pattern="${current_pattern%\'}"
        current_pattern="${current_pattern#\'}"
        continue
      fi

      # Extract weight (8-space indent)
      if [[ "$line" =~ ^[[:space:]]{8}weight:[[:space:]]*([0-9]+)$ ]]; then
        current_weight="${BASH_REMATCH[1]}"
        # Pattern is complete, save it
        if [[ -n "$current_type" && -n "$current_pattern" ]]; then
          pattern_buffer+="${current_type}:${current_pattern}:${current_weight}"$'\n'
          current_type=""
          current_pattern=""
          current_weight=""
        fi
        continue
      fi

      # Check if we're leaving patterns section
      if [[ "$line" =~ ^[[:space:]]{4}[a-z] && ! "$line" =~ ^[[:space:]]{6}- ]]; then
        # Save last pattern if complete
        if [[ -n "$current_type" && -n "$current_pattern" && -n "$current_weight" ]]; then
          pattern_buffer+="${current_type}:${current_pattern}:${current_weight}"$'\n'
        fi
        in_patterns=false
        current_type=""
        current_pattern=""
        current_weight=""
      fi
    fi

  done < "$yaml_file"

  # Save last agent's patterns
  if [[ -n "$current_agent" && -n "$pattern_buffer" ]]; then
    AGENT_PATTERNS["$current_agent"]="$pattern_buffer"
  fi

  # Save last incomplete pattern if any
  if [[ "$in_patterns" == true && -n "$current_type" && -n "$current_pattern" && -n "$current_weight" ]]; then
    pattern_buffer+="${current_type}:${current_pattern}:${current_weight}"$'\n'
    AGENT_PATTERNS["$current_agent"]="$pattern_buffer"
  fi

  return 0
}

# Task 11: Safe pattern loading with error handling and fallback
# Returns: 0 on success (patterns loaded from YAML or fallback), 1 on critical error
safe_load_patterns() {
  # Step 1: Check dependencies
  if ! check_dependencies 2>/dev/null; then
    if [[ ${VERBOSE:-false} == true ]]; then
      log "Dependencies missing for YAML pattern loading, falling back to hardcoded patterns"
    else
      echo "⚠ Dependencies missing for YAML pattern loading, using hardcoded patterns" >&2
    fi
    initialize_detection_patterns_hardcoded
    return 0
  fi

  # Step 2: Setup patterns directory
  local patterns_dir
  if ! patterns_dir=$(setup_patterns_directory); then
    if [[ ${VERBOSE:-false} == true ]]; then
      log "Pattern directory not found, falling back to hardcoded patterns"
    else
      echo "⚠ Pattern directory not found, using hardcoded patterns" >&2
    fi
    initialize_detection_patterns_hardcoded
    return 0
  fi

  # Step 3: Load pattern files
  if ! load_pattern_files "$patterns_dir"; then
    if [[ ${VERBOSE:-false} == true ]]; then
      log "Failed to load pattern files, falling back to hardcoded patterns"
    else
      echo "⚠ Failed to load pattern files, using hardcoded patterns" >&2
    fi
    initialize_detection_patterns_hardcoded
    return 0
  fi

  # Step 4: Validate that patterns were loaded
  local pattern_count=0
  if [[ -n "${!AGENT_PATTERNS[@]}" ]]; then
    pattern_count="${#AGENT_PATTERNS[@]}"
  fi

  if [[ $pattern_count -eq 0 ]]; then
    if [[ ${VERBOSE:-false} == true ]]; then
      log "No patterns loaded from YAML files, falling back to hardcoded patterns"
    else
      echo "⚠ No patterns loaded from YAML files, using hardcoded patterns" >&2
    fi
    initialize_detection_patterns_hardcoded
    return 0
  fi

  # Success - patterns loaded from YAML
  return 0
}

# Load detection patterns from YAML file with fallback to hardcoded patterns (LEGACY)
# Pattern format: "type:pattern:weight" (one per line)
# Types: file, path, content
# Weight: 0-25 (contribution to confidence score)
load_detection_patterns() {
  # Determine YAML file location
  # Try in order: data/ directory, same directory as script, relative to working directory
  local yaml_file=""
  local script_dir
  local source_file="${BASH_SOURCE[0]:-}"
  [[ -z "$source_file" ]] && source_file="$0"
  script_dir="$(cd "$(dirname "$source_file")" && pwd)"

  # Try multiple locations
  for candidate in \
    "${script_dir}/../data/agent_patterns.yaml" \
    "${script_dir}/data/agent_patterns.yaml" \
    "data/agent_patterns.yaml" \
    ".claude/agent_patterns.yaml"
  do
    if [[ -f "$candidate" ]]; then
      yaml_file="$candidate"
      break
    fi
  done

  # Try to load from YAML
  if [[ -n "$yaml_file" ]]; then
    if parse_yaml_patterns "$yaml_file"; then
      # Check if any patterns were loaded (safe for nounset)
      local count=0
      if [[ -n "${!AGENT_PATTERNS[@]}" ]]; then
        count="${#AGENT_PATTERNS[@]}"
      fi
      if [[ "$count" -gt 0 ]]; then
        echo "✓ Loaded $count agent detection patterns from ${yaml_file##*/}" >&2
        return 0
      fi
    fi
  fi

  # Fallback to hardcoded patterns
  echo "⚠ YAML pattern file not found or failed to parse, using hardcoded patterns" >&2
  initialize_detection_patterns_hardcoded
  return 0
}

# Initialize detection patterns for all 30 agents (LEGACY/FALLBACK)
# This function is now used as a fallback when YAML file is not available
# Pattern format: "type:pattern:weight" (one per line)
# Types: file, path, content
# Weight: 0-25 (contribution to confidence score)
initialize_detection_patterns_hardcoded() {
  # Infrastructure Agents
  
  AGENT_PATTERNS["devops-orchestrator"]="
path:.github/workflows:5
path:.gitlab-ci:5
file:Jenkinsfile:5
path:terraform:5
file:*.tf:5
path:k8s:5
path:kubernetes:5
file:prometheus.yml:5
path:ansible:5
"

  AGENT_PATTERNS["aws-specialist"]="
file:*.tf:10
content:provider \"aws\":20
content:aws_:15
file:cloudformation.yaml:15
file:cloudformation.yml:15
file:cdk.json:15
file:cdk.context.json:15
path:.aws:10
path:cloudformation:15
content:AWS::CloudFormation:15
content:aws-cdk:10
content:@aws-cdk:10
"

  AGENT_PATTERNS["azure-specialist"]="
file:*.bicep:20
file:azuredeploy.json:15
file:azuredeploy.parameters.json:10
content:deploymentTemplate:15
content:\$schema.*deploymentTemplate:15
file:azure-pipelines.yml:15
file:azure-pipelines.yaml:15
content:provider \"azurerm\":20
content:azurerm_:15
content:Microsoft.Compute:10
content:Microsoft.Resources:10
path:.azure:10
"

  AGENT_PATTERNS["gcp-specialist"]="
file:app.yaml:15
path:.config/gcloud:10
content:provider \"google\":20
content:google_:15
file:deployment-manager.yaml:15
file:*.jinja:10
path:deployment:10
content:gcp.googleapis.com:10
content:googleapis.com:10
content:gcloud:10
file:cloudbuild.yaml:15
"

  AGENT_PATTERNS["terraform-specialist"]="
file:*.tf:20
file:*.tfvars:15
file:terraform.tfstate:25
file:terraform.tfstate.backup:20
file:.terraform.lock.hcl:15
path:.terraform:15
content:terraform:10
content:module:10
content:resource:5
"

  AGENT_PATTERNS["ansible-specialist"]="
file:ansible.cfg:20
file:playbook.yml:15
file:playbook.yaml:15
path:roles:15
path:inventory:10
file:requirements.yml:10
content:ansible.builtin:15
content:hosts::10
content:tasks::10
"

  AGENT_PATTERNS["cicd-specialist"]="
path:.github/workflows:20
file:.gitlab-ci.yml:20
file:Jenkinsfile:20
path:.circleci:20
file:circle.yml:15
file:azure-pipelines.yml:20
file:.travis.yml:15
file:buildspec.yml:15
content:pipeline:10
content:ci/cd:10
content:continuous integration:10
"

  AGENT_PATTERNS["kubernetes-specialist"]="
path:k8s:20
path:kubernetes:20
file:Chart.yaml:20
file:values.yaml:15
file:kustomization.yaml:20
content:apiVersion:10
content:kind: Deployment:15
content:kind: Service:10
content:kind: StatefulSet:10
content:kubectl:10
file:skaffold.yaml:15
"

  AGENT_PATTERNS["monitoring-specialist"]="
file:prometheus.yml:20
file:prometheus.yaml:20
path:prometheus:15
path:grafana:15
file:grafana.ini:15
file:elasticsearch.yml:15
file:logstash.conf:15
file:kibana.yml:15
content:metrics:10
content:observability:10
content:alertmanager:10
path:monitoring:15
"

  AGENT_PATTERNS["docker-specialist"]="
file:Dockerfile:25
file:docker-compose.yml:20
file:docker-compose.yaml:20
file:.dockerignore:10
file:Containerfile:20
content:FROM:10
"

  AGENT_PATTERNS["observability-specialist"]="
content:prometheus:15
content:grafana:15
content:opentelemetry:20
content:jaeger:15
content:zipkin:15
path:monitoring:10
"

  # Development Agents
  
  AGENT_PATTERNS["database-specialist"]="
file:schema.prisma:20
path:migrations:15
path:db/migrate:15
file:*.sql:10
content:CREATE TABLE:15
content:SELECT:5
content:prisma:10
"

  AGENT_PATTERNS["frontend-specialist"]="
content:react:15
content:vue:15
content:angular:15
content:next:15
path:src/components:15
path:components:10
path:frontend:10
file:package.json:5
"

  AGENT_PATTERNS["mobile-specialist"]="
path:android:20
path:ios:20
file:pubspec.yaml:20
content:ReactNative:20
content:Flutter:15
file:Podfile:15
file:build.gradle:10
"

  # Quality Agents
  
  AGENT_PATTERNS["test-specialist"]="
path:tests:15
path:__tests__:15
path:spec:15
file:pytest.ini:15
file:jest.config.js:15
file:vitest.config.ts:15
file:playwright.config.ts:15
content:describe(:10
"

  AGENT_PATTERNS["security-specialist"]="
content:jwt:10
content:bcrypt:10
content:helmet:10
content:csrf:10
content:authentication:10
content:authorization:10
file:security.yml:15
"

  AGENT_PATTERNS["code-review-specialist"]="
file:.codeclimate.yml:15
content:TODO::10
content:FIXME::10
content:refactor:10
file:.eslintrc:10
file:.prettierrc:10
"

  AGENT_PATTERNS["refactoring-specialist"]="
content:technical debt:15
content:legacy code:15
path:src/legacy:20
path:legacy:15
content:deprecated:10
content:refactor:10
"

  AGENT_PATTERNS["performance-specialist"]="
content:performance:15
content:profiling:15
content:latency:10
content:optimization:10
content:cache:10
file:lighthouse.config.js:15
"

  # Operations Agents
  
  AGENT_PATTERNS["migration-specialist"]="
path:migrations:20
path:db/migrate:20
path:prisma/migrations:20
file:*migration*.sql:15
content:ALTER TABLE:15
content:migration:10
"

  AGENT_PATTERNS["dependency-specialist"]="
file:package-lock.json:15
file:yarn.lock:15
file:pnpm-lock.yaml:15
file:requirements.txt:15
file:poetry.lock:15
file:Gemfile.lock:15
file:go.sum:15
"

  AGENT_PATTERNS["git-specialist"]="
file:.gitmodules:20
path:.git/hooks:15
file:.gitattributes:10
content:submodule:15
file:.gitmessage:10
"

  # Productivity Agents
  
  AGENT_PATTERNS["scaffolding-specialist"]="
path:scripts/scaffold:20
path:templates:15
content:plopfile:20
content:scaffold:15
file:generator.js:15
path:blueprints:15
"

  AGENT_PATTERNS["documentation-specialist"]="
path:docs:15
file:mkdocs.yml:20
file:docusaurus.config.js:20
file:README.md:5
path:documentation:15
file:.readthedocs.yml:15
"

  AGENT_PATTERNS["debugging-specialist"]="
content:sentry:15
content:bugsnag:15
content:logger.error:10
content:console.error:5
content:debugger:10
file:.sentryclirc:15
"

  # Business Agents
  
  AGENT_PATTERNS["validation-specialist"]="
content:validation:15
content:schema validation:15
content:yup:15
content:zod:15
content:joi:15
content:validator:10
"

  AGENT_PATTERNS["architecture-specialist"]="
file:architecture.md:20
content:architecture decision record:20
content:ADR:15
path:docs/architecture:15
path:adr:20
"

  AGENT_PATTERNS["localization-specialist"]="
path:i18n:20
path:locales:20
file:.i18nrc:15
content:react-intl:15
content:i18next:15
content:translation:10
"

  AGENT_PATTERNS["compliance-specialist"]="
content:gdpr:15
content:hipaa:15
content:pci-dss:15
content:soc 2:15
content:compliance:10
path:compliance:15
"

  # Specialized Agents
  
  AGENT_PATTERNS["data-science-specialist"]="
path:notebooks:20
file:environment.yml:15
content:pandas:15
content:scikit-learn:15
content:tensorflow:15
content:pytorch:15
file:*.ipynb:20
"
}

recommended_agents=()
add_agent() {
  local agent="$1"
  for existing in "${recommended_agents[@]:-}"; do
    [[ "$existing" == "$agent" ]] && return
  done
  recommended_agents+=("$agent")
}

# Calculate confidence score for an agent (0-100)
declare -A agent_confidence
declare -A agent_matched_patterns

# Calculate maximum possible weight for an agent
calculate_max_possible_weight() {
  local agent="$1"
  local max_weight=0
  
  local patterns="${AGENT_PATTERNS[$agent]}"
  
  while IFS= read -r pattern_line; do
    [[ -z "$pattern_line" ]] && continue
    
    pattern_line=$(echo "$pattern_line" | xargs)
    [[ -z "$pattern_line" ]] && continue
    
    # Parse pattern: type:pattern:weight
    local rest="${pattern_line#*:}"
    local weight="${rest##*:}"
    
    if [[ "$weight" =~ ^[0-9]+$ ]]; then
      max_weight=$((max_weight + weight))
    fi
  done <<< "$patterns"
  
  echo "$max_weight"
}

# Cache for max weights
declare -A AGENT_MAX_WEIGHTS_CACHE

# Get max possible weight with caching
get_max_possible_weight() {
  local agent="$1"

  # Check if agent is in cache (safe for nounset)
  if [[ -z "${AGENT_MAX_WEIGHTS_CACHE[$agent]+x}" ]]; then
    AGENT_MAX_WEIGHTS_CACHE[$agent]=$(calculate_max_possible_weight "$agent")
  fi

  echo "${AGENT_MAX_WEIGHTS_CACHE[$agent]}"
}

# Validate pattern weights
validate_pattern_weights() {
  local errors=0
  
  for agent in "${!AGENT_PATTERNS[@]}"; do
    local max_weight
    max_weight=$(calculate_max_possible_weight "$agent")
    
    if [[ $max_weight -eq 0 ]]; then
      echo "Warning: Agent '$agent' has zero total pattern weight" >&2
      ((++errors))
    elif [[ $max_weight -lt 0 ]]; then
      echo "Error: Agent '$agent' has negative total pattern weight: $max_weight" >&2
      ((++errors))
    fi
  done
  
  if [[ $errors -gt 0 ]]; then
    echo "Found $errors agents with invalid pattern weights" >&2
    return 1
  fi
  
  return 0
}

# Get max weights for all agents (debugging utility)
get_all_max_weights() {
  echo "Agent Max Possible Weights"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  printf "%-40s %10s\n" "Agent" "Max Weight"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  for agent in $(printf '%s\n' "${!AGENT_PATTERNS[@]}" | sort); do
    local max_weight
    max_weight=$(calculate_max_possible_weight "$agent")
    printf "%-40s %10d\n" "$agent" "$max_weight"
  done
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Debug confidence calculation for an agent
debug_confidence_calculation() {
  local agent="$1"
  
  echo "═══════════════════════════════════════════════════════════════════════"
  echo "Confidence Calculation Debug: $agent"
  echo "═══════════════════════════════════════════════════════════════════════"
  echo ""
  
  local patterns="${AGENT_PATTERNS[$agent]}"
  local accumulated_weight=0
  local max_possible_weight=0
  
  echo "Pattern Evaluation:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  printf "%-5s %-8s %-12s %-40s\n" "Match" "Weight" "Type" "Pattern"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  while IFS= read -r pattern_line; do
    [[ -z "$pattern_line" ]] && continue
    
    pattern_line=$(echo "$pattern_line" | xargs)
    [[ -z "$pattern_line" ]] && continue
    
    local type="${pattern_line%%:*}"
    local rest="${pattern_line#*:}"
    local weight="${rest##*:}"
    local pattern="${rest%:*}"
    
    [[ -z "$type" || -z "$pattern" || -z "$weight" ]] && continue
    [[ ! "$weight" =~ ^[0-9]+$ ]] && continue
    
    max_possible_weight=$((max_possible_weight + weight))
    
    local matches=false
    local match_symbol="✗"
    
    case "$type" in
      file)
        if has_file "$pattern"; then
          matches=true
          match_symbol="✓"
          accumulated_weight=$((accumulated_weight + weight))
        fi
        ;;
      path)
        if has_path "$pattern"; then
          matches=true
          match_symbol="✓"
          accumulated_weight=$((accumulated_weight + weight))
        fi
        ;;
      content)
        if search_contents "$pattern"; then
          matches=true
          match_symbol="✓"
          accumulated_weight=$((accumulated_weight + weight))
        fi
        ;;
    esac
    
    printf "%-5s %-8d %-12s %-40s\n" "$match_symbol" "$weight" "$type" "$pattern"
  done <<< "$patterns"
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Calculation:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  printf "%-30s %d\n" "Accumulated Weight:" "$accumulated_weight"
  printf "%-30s %d\n" "Max Possible Weight:" "$max_possible_weight"
  
  local confidence=0
  if [[ $max_possible_weight -gt 0 ]]; then
    confidence=$((accumulated_weight * 100 / max_possible_weight))
    [[ $confidence -gt 100 ]] && confidence=100
  fi
  
  printf "%-30s %d%%\n" "Confidence:" "$confidence"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

calculate_confidence() {
  local agent="$1"
  local accumulated_weight=0
  local matched_patterns=()
  
  # Get detection patterns for this agent
  local patterns="${AGENT_PATTERNS[$agent]}"
  
  # Handle empty patterns
  if [[ -z "$patterns" ]]; then
    if [[ ${VERBOSE:-false} == true ]]; then
      log "  $agent: no patterns defined, confidence=0%"
    fi
    agent_confidence[$agent]=0
    agent_matched_patterns[$agent]=""
    echo "0"
    return 0
  fi
  
  # Get max possible weight for this agent
  local max_possible_weight
  max_possible_weight=$(get_max_possible_weight "$agent")
  
  # Parse and execute each pattern
  while IFS= read -r pattern_line; do
    # Skip empty lines
    [[ -z "$pattern_line" ]] && continue
    
    # Trim whitespace from line
    pattern_line=$(echo "$pattern_line" | xargs)
    [[ -z "$pattern_line" ]] && continue
    
    # Parse pattern: type:pattern:weight
    # Extract type (first field before :)
    type="${pattern_line%%:*}"
    # Remove type and first colon
    rest="${pattern_line#*:}"
    # Extract weight (last field after last :)
    weight="${rest##*:}"
    # Extract pattern (everything between type and weight)
    pattern="${rest%:*}"
    
    # Skip if any field is empty
    [[ -z "$type" || -z "$pattern" || -z "$weight" ]] && continue
    
    # Validate weight is a number
    if ! [[ "$weight" =~ ^[0-9]+$ ]]; then
      continue
    fi
    
    # Execute detection based on type
    case "$type" in
      file)
        if has_file "$pattern"; then
          accumulated_weight=$((accumulated_weight + weight))
          matched_patterns+=("file:$pattern")
        fi
        ;;
      path)
        if has_path "$pattern"; then
          accumulated_weight=$((accumulated_weight + weight))
          matched_patterns+=("path:$pattern")
        fi
        ;;
      content)
        if search_contents "$pattern"; then
          accumulated_weight=$((accumulated_weight + weight))
          matched_patterns+=("content:$pattern")
        fi
        ;;
    esac
  done <<< "$patterns"
  
  # Calculate percentage score with dynamic max weight
  local confidence=0
  if [[ $max_possible_weight -gt 0 ]]; then
    # Use bc for large numbers if needed
    if [[ $max_possible_weight -gt 10000 ]]; then
      confidence=$(echo "scale=0; $accumulated_weight * 100 / $max_possible_weight" | bc)
    else
      confidence=$((accumulated_weight * 100 / max_possible_weight))
    fi
  else
    if [[ ${VERBOSE:-false} == true ]]; then
      log "  Warning: $agent has zero max possible weight"
    fi
  fi
  
  # Cap at 100
  [[ $confidence -gt 100 ]] && confidence=100
  
  # Verbose logging
  if [[ ${VERBOSE:-false} == true ]]; then
    log "  $agent: accumulated=$accumulated_weight, max=$max_possible_weight, confidence=$confidence%"
  fi
  
  # Store results
  agent_confidence[$agent]=$confidence
  agent_matched_patterns[$agent]="${matched_patterns[*]}"
  
  echo "$confidence"
}

# Guard to prevent execution when sourced (for testing)
if [[ -n "${BASH_SOURCE:-}" ]] && [[ "${BASH_SOURCE[0]:-}" != "${0}" ]]; then
  # Script is being sourced, don't execute main logic
  return 0 2>/dev/null || exit 0
fi

# Load detection patterns (from YAML or fallback to hardcoded)
safe_load_patterns

# Handle import mode - skip detection and install skills from profile (Task 9)
if [[ -n "$IMPORT_FILE" ]]; then
  mkdir -p "$AGENTS_DIR"

  # Define fetch_agent function here for import mode
  fetch_agent() {
    local agent="$1"
    local dest
    dest=$(get_skill_dir "$agent")

    if [[ -f "${dest}/${ENTRYPOINT_FILENAME}" && $FORCE == false ]]; then
      log "Skipping ${agent} (already exists). Use --force to redownload."
      return
    fi

    log "Downloading ${agent}"
    if ! download_skill "$agent" "$AGENTS_DIR" fetch_with_retry; then
      echo "Failed to download ${agent}" >&2
      return 1
    fi
  }

  # Parse skills registry before importing
  parse_agent_registry

  # Import and install skills from profile
  import_profile "$IMPORT_FILE"

  # Always include the registry for reference
  REGISTRY_DEST="${AGENTS_DIR}/${REGISTRY_FILENAME}"
  if [[ ! -f "$REGISTRY_DEST" || $FORCE == true ]]; then
    REGISTRY_URL="${BASE_URL}/${REGISTRY_FILENAME}"
    log "Downloading skills registry"
    curl -fsSL "$REGISTRY_URL" -o "$REGISTRY_DEST"
  fi

  log "All done! Skills are located in ${AGENTS_DIR}"
  exit 0
fi

# Handle update detection mode (Task 10)
if [[ $CHECK_UPDATES == true ]] || [[ $UPDATE_ALL == true ]]; then
  if [[ $CHECK_UPDATES == true ]]; then
    check_updates
    exit 0
  fi

  if [[ $UPDATE_ALL == true ]]; then
    update_all_agents
    exit 0
  fi
fi

# Parse skills registry for metadata
parse_agent_registry

# Run detection for all agents
log "Scanning project for technology signals..."

for agent in "${!AGENT_PATTERNS[@]}"; do
  # Calculate confidence (stores in agent_confidence array)
  calculate_confidence "$agent" > /dev/null

  # Get the stored confidence
  confidence="${agent_confidence[$agent]:-0}"

  # Add agents with confidence >= MIN_CONFIDENCE threshold
  if [[ $confidence -ge $MIN_CONFIDENCE ]]; then
    add_agent "$agent"
  fi
done

# DevOps Orchestrator Logic (Task 3.3)
# Boost devops-orchestrator confidence when multiple infrastructure components detected
detect_devops_orchestrator() {
  local infra_agents=()
  local cloud_detected=false
  local iac_detected=false
  local k8s_detected=false
  local cicd_detected=false

  # Check for cloud providers
  for cloud_agent in "aws-specialist" "azure-specialist" "gcp-specialist"; do
    if [[ ${agent_confidence[$cloud_agent]:-0} -ge $MIN_CONFIDENCE ]]; then
      cloud_detected=true
      infra_agents+=("$cloud_agent")
    fi
  done

  # Check for IaC tools
  for iac_agent in "terraform-specialist" "ansible-specialist"; do
    if [[ ${agent_confidence[$iac_agent]:-0} -ge $MIN_CONFIDENCE ]]; then
      iac_detected=true
      infra_agents+=("$iac_agent")
    fi
  done

  # Check for Kubernetes
  if [[ ${agent_confidence["kubernetes-specialist"]:-0} -ge $MIN_CONFIDENCE ]]; then
    k8s_detected=true
    infra_agents+=("kubernetes-specialist")
  fi

  # Check for CI/CD
  if [[ ${agent_confidence["cicd-specialist"]:-0} -ge $MIN_CONFIDENCE ]]; then
    cicd_detected=true
    infra_agents+=("cicd-specialist")
  fi

  # Check for monitoring
  if [[ ${agent_confidence["monitoring-specialist"]:-0} -ge $MIN_CONFIDENCE ]]; then
    infra_agents+=("monitoring-specialist")
  fi

  # Boost orchestrator confidence based on complexity
  local current_confidence=${agent_confidence["devops-orchestrator"]:-0}
  local boost=0

  # Condition 1: Multiple IaC tools (Terraform + Ansible)
  if [[ $iac_detected == true ]] && [[ ${agent_confidence["terraform-specialist"]:-0} -ge $MIN_CONFIDENCE ]] && [[ ${agent_confidence["ansible-specialist"]:-0} -ge $MIN_CONFIDENCE ]]; then
    boost=$((boost + 20))
  fi

  # Condition 2: Cloud + Terraform + Kubernetes all detected
  if [[ $cloud_detected == true ]] && [[ $iac_detected == true ]] && [[ $k8s_detected == true ]]; then
    boost=$((boost + 30))
  fi

  # Condition 3: IaC + CI/CD + Kubernetes + Monitoring (full DevOps stack)
  if [[ $iac_detected == true ]] && [[ $cicd_detected == true ]] && [[ $k8s_detected == true ]] && [[ ${agent_confidence["monitoring-specialist"]:-0} -ge $MIN_CONFIDENCE ]]; then
    boost=$((boost + 35))
  fi

  # Condition 4: 3+ infrastructure agents detected
  if [[ ${#infra_agents[@]} -ge 3 ]]; then
    boost=$((boost + 15))
  fi

  # Apply boost
  if [[ $boost -gt 0 ]]; then
    local new_confidence=$((current_confidence + boost))
    [[ $new_confidence -gt 100 ]] && new_confidence=100
    agent_confidence["devops-orchestrator"]=$new_confidence

    # Add to recommended agents if not already present and meets threshold
    if [[ $new_confidence -ge $MIN_CONFIDENCE ]]; then
      add_agent "devops-orchestrator"
    fi
  fi
}

# Run DevOps orchestrator detection logic
detect_devops_orchestrator

# If no agents detected, recommend core agents
if [[ ${#recommended_agents[@]} -eq 0 ]]; then
  log "No technology-specific signals found. Recommending core agents."
  recommended_agents=(
    'code-review-specialist'
    'refactoring-specialist'
    'test-specialist'
  )
  # Set default confidence for core agents
  agent_confidence['code-review-specialist']=50
  agent_confidence['refactoring-specialist']=50
  agent_confidence['test-specialist']=50
fi

# Sort agents by confidence score (descending)
IFS=$'\n' sorted_agents=($(
  for agent in "${recommended_agents[@]}"; do
    echo "${agent_confidence[$agent]:-0}:$agent"
  done | sort -rn | cut -d: -f2
))
unset IFS

recommended_agents=("${sorted_agents[@]}")

# Handle --show-max-weights flag
if [[ $SHOW_MAX_WEIGHTS == true ]]; then
  get_all_max_weights
  exit 0
fi

# Handle --debug-confidence flag
if [[ -n "$DEBUG_CONFIDENCE" ]]; then
  if [[ "$DEBUG_CONFIDENCE" == "all" ]]; then
    for agent in $(printf '%s\n' "${!AGENT_PATTERNS[@]}" | sort); do
      debug_confidence_calculation "$agent"
    done
  else
    debug_confidence_calculation "$DEBUG_CONFIDENCE"
  fi
  exit 0
fi

# Display results using enhanced formatting
if [[ ${#recommended_agents[@]} -gt 0 ]]; then
  # If interactive mode, let user select agents
  if [[ $INTERACTIVE == true ]]; then
    display_categorized_results
    echo ""
    log "Entering interactive mode..."
    sleep 1
    safe_interactive_selection
  else
    display_categorized_results
  fi
else
  log "No skills met the confidence threshold of ${MIN_CONFIDENCE}%"
fi

# Verbose mode: show detailed detection patterns
if [[ $VERBOSE == true ]]; then
  echo ""
  echo "═══════════════════════════════════════════════════════════════════════"
  echo "                     Detailed Detection Results (Verbose)"
  echo "═══════════════════════════════════════════════════════════════════════"
  echo ""

  for agent in "${recommended_agents[@]}"; do
    echo "Agent: $agent (Confidence: ${agent_confidence[$agent]:-0}%)"
    echo "Matched Patterns:"

    patterns="${AGENT_PATTERNS[$agent]}"
    while IFS= read -r pattern_line; do
      [[ -z "$pattern_line" ]] && continue
      pattern_line=$(echo "$pattern_line" | xargs)
      [[ -z "$pattern_line" ]] && continue

      type="${pattern_line%%:*}"
      rest="${pattern_line#*:}"
      weight="${rest##*:}"
      pattern="${rest%:*}"

      [[ -z "$type" || -z "$pattern" || -z "$weight" ]] && continue

      # Check if pattern matched
      matched=false
      case "$type" in
        file) has_file "$pattern" && matched=true ;;
        path) has_path "$pattern" && matched=true ;;
        content) search_contents "$pattern" && matched=true ;;
      esac

      if [[ $matched == true ]]; then
        echo "  ✓ $type:$pattern (weight: $weight)"
      else
        echo "  ✗ $type:$pattern (weight: $weight)"
      fi
    done <<< "$patterns"

    echo ""
  done

  echo "═══════════════════════════════════════════════════════════════════════"
  echo ""
fi

# Export profile if requested
if [[ -n "$EXPORT_FILE" ]]; then
  export_profile "$EXPORT_FILE"

  # If dry-run or only exporting, exit
  if $DRY_RUN; then
    exit 0
  fi
fi

if $DRY_RUN; then
  exit 0
fi

mkdir -p "$AGENTS_DIR"

fetch_agent() {
  local agent="$1"
  local dest
  dest=$(get_skill_dir "$agent")

  if [[ -f "${dest}/${ENTRYPOINT_FILENAME}" && $FORCE == false ]]; then
    log "Skipping ${agent} (already exists). Use --force to redownload."
    return
  fi

  log "Downloading ${agent}..."
  if ! download_skill "$agent" "$AGENTS_DIR" fetch_with_retry; then
    echo "Failed to download ${agent}" >&2
    echo "You can try again with --force to retry failed downloads" >&2
    return 1
  fi

  log "Successfully downloaded ${agent}"
}

for agent in "${recommended_agents[@]}"; do
  fetch_agent "$agent"
done

# Always include the registry for reference
REGISTRY_DEST="${AGENTS_DIR}/${REGISTRY_FILENAME}"
if [[ ! -f "$REGISTRY_DEST" || $FORCE == true ]]; then
  REGISTRY_URL="${BASE_URL}/${REGISTRY_FILENAME}"
  log "Downloading skills registry..."
  if ! fetch_with_retry "$REGISTRY_URL" "$REGISTRY_DEST"; then
    echo "Warning: Failed to download skills registry" >&2
  else
    log "Successfully downloaded skills registry"
  fi
else
  log "Skills registry already present. Use --force to redownload."
fi

log "All done! Skills are located in ${AGENTS_DIR}"
