# Network Operations Quick Reference

Quick reference for network operations, retry logic, and caching in the skill recommendation script.

## Common Commands

```bash
# Basic usage (uses cache automatically)
bash scripts/recommend_skills.sh

# Force fresh download (bypass cache)
bash scripts/recommend_skills.sh --force-refresh

# Clear all cached files
bash scripts/recommend_skills.sh --clear-cache

# Check for skill updates
bash scripts/recommend_skills.sh --check-updates

# Update all skills (with automatic backup)
bash scripts/recommend_skills.sh --update-all

# Verbose output (see network operations)
bash scripts/recommend_skills.sh --verbose
```

## Cache Control

```bash
# Custom cache directory
bash scripts/recommend_skills.sh --cache-dir=/tmp/my-cache

# Custom cache expiry
bash scripts/recommend_skills.sh --cache-expiry=3600    # 1 hour
bash scripts/recommend_skills.sh --cache-expiry=86400   # 1 day (default)
bash scripts/recommend_skills.sh --cache-expiry=604800  # 1 week

# View cache location
echo ${XDG_CACHE_HOME:-$HOME/.cache}/claude-skills-library

# Check cache size
du -sh ~/.cache/claude-skills-library

# List cached files
ls -lh ~/.cache/claude-skills-library
```

## Retry Behavior

- **Attempts**: 3 retries per download
- **Backoff**: 1s, 2s, 4s (exponential)
- **Timeout**: 30 seconds per attempt
- **Total Max Time**: ~97 seconds

## Cache Behavior

- **Default Location**: `~/.cache/claude-skills-library`
- **Default Expiry**: 24 hours
- **Update Checks**: 1 hour cache
- **Strategy**: Check cache → Validate freshness → Use or fetch

## Troubleshooting

### Network Failures
```bash
# Check connectivity
ping -c 5 raw.githubusercontent.com

# Test URL directly
curl -I https://raw.githubusercontent.com/daryllundy/claude-skills-library/main/.claude/skills/SKILLS_REGISTRY.md

# Use verbose mode
bash scripts/recommend_skills.sh --verbose
```

### Cache Issues
```bash
# Clear and rebuild cache
bash scripts/recommend_skills.sh --clear-cache
bash scripts/recommend_skills.sh --force-refresh

# Check cache age
ls -lh ~/.cache/claude-skills-library

# Use shorter expiry
bash scripts/recommend_skills.sh --cache-expiry=3600
```

### Offline Usage
```bash
# First run online (populates cache)
bash scripts/recommend_skills.sh

# Subsequent runs work offline (uses cache)
bash scripts/recommend_skills.sh
```

## HTTP Status Codes

| Code | Meaning | Action |
|------|---------|--------|
| 000 | Connection timeout/DNS failure | Check network, firewall |
| 403 | Forbidden | Check rate limits, IP blocks |
| 404 | Not Found | Verify URL, branch name |
| 503 | Service Unavailable | Wait and retry (automatic) |

## Environment Variables

```bash
# Override cache directory
export XDG_CACHE_HOME=/custom/cache
bash scripts/recommend_skills.sh

# Set cache expiry
export CACHE_EXPIRY_SECONDS=3600
bash scripts/recommend_skills.sh
```

## CI/CD Integration

### GitHub Actions
```yaml
- name: Cache skills
  uses: actions/cache@v3
  with:
    path: ~/.cache/claude-skills-library
    key: claude-skills-library-${{ hashFiles('scripts/recommend_skills.sh') }}

- name: Setup skills
  run: bash scripts/recommend_skills.sh --cache-expiry=604800
```

### GitLab CI
```yaml
setup_agents:
  cache:
    key: claude-skills-library
    paths:
      - .cache/claude-skills-library
  script:
    - export XDG_CACHE_HOME=$CI_PROJECT_DIR/.cache
    - bash scripts/recommend_skills.sh --cache-expiry=604800
```

Compatibility note: the script still reads `CLAUDE_AGENTS_*` env vars and legacy cache contents from `~/.cache/claude-agents`, but new automation should target `CLAUDE_SKILLS_*` and `~/.cache/claude-skills-library`.

## Best Practices

1. **Use default cache** for most scenarios
2. **Force refresh sparingly** (only when needed)
3. **Longer expiry for stable environments** (1 week)
4. **Shorter expiry for active development** (1 hour)
5. **Clear cache monthly** to free disk space
6. **Leverage CI/CD caching** for faster builds
7. **Prepare for offline** by running online first
8. **Use verbose mode** for debugging

## Full Documentation

For comprehensive documentation, see [NETWORK_OPERATIONS.md](NETWORK_OPERATIONS.md).
