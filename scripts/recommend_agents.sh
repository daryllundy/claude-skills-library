#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Warning: scripts/recommend_agents.sh is deprecated; use scripts/recommend_skills.sh instead." >&2
exec "$SCRIPT_DIR/recommend_skills.sh" "$@"
