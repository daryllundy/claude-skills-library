# Network Operations & Caching

This document provides comprehensive information about the network operations, retry logic, and caching mechanisms in the skill recommendation script.

## Table of Contents

- [Overview](#overview)
- [Retry Mechanism](#retry-mechanism)
- [Caching System](#caching-system)
- [Command-Line Flags](#command-line-flags)
- [Offline Workflows](#offline-workflows)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)

## Overview

The skill recommendation script (`scripts/recommend_agents.sh`) implements robust network handling to ensure reliability across various network conditions:

- **Automatic Retry**: All network operations retry on failure with exponential backoff
- **Intelligent Caching**: Downloaded files are cached locally to reduce network requests
- **Offline Support**: Work with cached data when network is unavailable
- **Error Diagnostics**: Detailed troubleshooting guidance on failures

## Retry Mechanism

### How It Works

Every network operation uses the `fetch_with_retry` function, which implements:

1. **Multiple Attempts**: Up to 3 attempts per download
2. **Exponential Backoff**: Wait time doubles after each failure (1s, 2s, 4s)
3. **Timeout Protection**: 30-second timeout per attempt
4. **HTTP Diagnostics**: Logs HTTP status codes for debugging
5. **Troubleshooting Guidance**: Provides actionable help on final failure

### Retry Behavior Example

```
[agent-setup] Attempt 1/3: Downloading https://example.com/agent.md
[agent-setup] Attempt 1 failed (HTTP 503). Retrying in 1s...
[agent-setup] Attempt 2/3: Downloading https://example.com/agent.md
[agent-setup] Attempt 2 failed (HTTP 503). Retrying in 2s...
[agent-setup] Attempt 3/3: Downloading https://example.com/agent.md
[agent-setup] Attempt 3 failed (HTTP 503). No more retries.

Error: Failed to download from https://example.com/agent.md after 3 attempts

Troubleshooting:
  1. Check your internet connection
  2. Verify the URL is accessible: curl -I https://example.com/agent.md
  3. Check if you're behind a proxy or firewall
  4. Try again later if the server is temporarily unavailable
```

### When Retry Activates

Retry logic activates for:
- **Agent Downloads**: Fetching agent markdown files
- **Update Checks**: Comparing local vs remote agent versions
- **Registry Fetches**: Downloading the agent registry
- **Update Operations**: Applying updates to local agents

### Retry Configuration

The retry mechanism uses these defaults:
- **Max Attempts**: 3
- **Initial Backoff**: 1 second
- **Backoff Multiplier**: 2x (exponential)
- **Timeout**: 30 seconds per attempt
- **Total Max Time**: ~97 seconds (30s + 1s + 30s + 2s + 30s + 4s)

## Caching System

### Cache Location

Default cache directory:
```bash
$XDG_CACHE_HOME/claude-agents
# or if XDG_CACHE_HOME is not set:
~/.cache/claude-agents
```

Override with `--cache-dir` flag:
```bash
bash scripts/recommend_agents.sh --cache-dir=/tmp/my-cache
```

### Cache Strategy

The caching system uses a **check-then-fetch** strategy:

1. **Check Cache**: Look for cached file
2. **Validate Freshness**: Check if cache is within expiry time
3. **Use or Fetch**: Use cached data if fresh, otherwise fetch from network
4. **Update Cache**: Store newly fetched data in cache

### Cache Expiry

Different operations use different cache expiry times:

| Operation | Default Expiry | Rationale |
|-----------|---------------|-----------|
| Agent Downloads | 24 hours | Agents change infrequently |
| Update Checks | 1 hour | Balance freshness vs network load |
| Registry Fetches | 1 hour | Registry updates periodically |

Override with `--cache-expiry` flag:
```bash
# 1 hour
bash scripts/recommend_agents.sh --cache-expiry=3600

# 1 day (default)
bash scripts/recommend_agents.sh --cache-expiry=86400

# 1 week
bash scripts/recommend_agents.sh --cache-expiry=604800
```

### Cache File Format

Cache files are stored with hashed filenames:
```
~/.cache/claude-agents/
├── a3f2b8c9d1e4f5a6  # Cached agent file (hash of URL)
├── b4e3c9d2f5a6b7c8  # Another cached file
└── c5f4d3e2a6b7c8d9  # Registry cache
```

The hash is generated from the URL using MD5 (or fallback to cksum if MD5 unavailable).

### Cache Benefits

1. **Performance**: Instant access to previously downloaded files
2. **Bandwidth**: Reduces network usage for repeated operations
3. **Reliability**: Continue working when network is unavailable
4. **CI/CD**: Faster builds with cached dependencies
5. **Cost**: Lower data transfer costs in metered environments

## Command-Line Flags

### Cache Control Flags

#### `--force-refresh`

Bypass cache and fetch fresh data from network.

```bash
bash scripts/recommend_agents.sh --force-refresh
```

**Use cases**:
- Ensure you have the latest agent versions
- Troubleshoot cache-related issues
- After known upstream changes

#### `--clear-cache`

Remove all cached files and exit.

```bash
bash scripts/recommend_agents.sh --clear-cache
```

**Output**:
```
[agent-setup] Clearing cache directory: /home/user/.cache/claude-agents
[agent-setup] Successfully cleared 15 cached file(s)
```

**Use cases**:
- Free up disk space
- Reset cache state
- Troubleshoot corrupted cache

#### `--cache-dir=<path>`

Specify custom cache directory.

```bash
bash scripts/recommend_agents.sh --cache-dir=/tmp/my-cache
```

**Use cases**:
- Use project-specific cache
- Store cache on faster storage
- Comply with organizational policies
- Share cache across team members

#### `--cache-expiry=<seconds>`

Set custom cache expiry time.

```bash
# 30 minutes
bash scripts/recommend_agents.sh --cache-expiry=1800

# 1 hour
bash scripts/recommend_agents.sh --cache-expiry=3600

# 1 day (default)
bash scripts/recommend_agents.sh --cache-expiry=86400

# 1 week
bash scripts/recommend_agents.sh --cache-expiry=604800

# Never expire (use with caution)
bash scripts/recommend_agents.sh --cache-expiry=999999999
```

**Use cases**:
- Longer expiry for stable environments
- Shorter expiry for active development
- Optimize for network conditions

### Combining Flags

Flags can be combined for complex scenarios:

```bash
# Use custom cache with 1-week expiry
bash scripts/recommend_agents.sh \
  --cache-dir=/project/.cache \
  --cache-expiry=604800

# Force refresh with verbose output
bash scripts/recommend_agents.sh \
  --force-refresh \
  --verbose

# Interactive mode with custom cache
bash scripts/recommend_agents.sh \
  --interactive \
  --cache-dir=/tmp/agents-cache
```

## Offline Workflows

### Preparing for Offline Work

1. **Initial Download**: Run script while online to populate cache
   ```bash
   bash scripts/recommend_agents.sh
   ```

2. **Verify Cache**: Check cached files
   ```bash
   ls -lh ~/.cache/claude-agents
   ```

3. **Work Offline**: Script automatically uses cached data
   ```bash
   # Network unavailable - uses cache
   bash scripts/recommend_agents.sh
   ```

### Offline Workflow Example

```bash
# Day 1: Online - download and cache
$ bash scripts/recommend_agents.sh
[agent-setup] Fetching agent registry...
[agent-setup] Cache miss or stale, fetching https://...
[agent-setup] Successfully downloaded registry
[agent-setup] Recommended agents: docker-specialist, kubernetes-specialist
[agent-setup] Downloaded 2 agents

# Day 2: Offline - uses cache (within 24 hours)
$ bash scripts/recommend_agents.sh
[agent-setup] Using cached version of https://...
[agent-setup] Recommended agents: docker-specialist, kubernetes-specialist
[agent-setup] All agents already installed

# Day 3: Still offline - cache expired but falls back gracefully
$ bash scripts/recommend_agents.sh
[agent-setup] Cache miss or stale, fetching https://...
[agent-setup] Attempt 1 failed (HTTP 000). Retrying in 1s...
[agent-setup] Attempt 2 failed (HTTP 000). Retrying in 2s...
[agent-setup] Attempt 3 failed (HTTP 000). No more retries.
[agent-setup] Warning: Failed to fetch registry, using local agents
```

### CI/CD Caching

Integrate with CI/CD cache systems:

#### GitHub Actions

```yaml
name: Setup Agents

on: [push]

jobs:
  setup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Cache agent files
        uses: actions/cache@v3
        with:
          path: ~/.cache/claude-agents
          key: claude-agents-${{ runner.os }}-${{ hashFiles('scripts/recommend_agents.sh') }}
          restore-keys: |
            claude-agents-${{ runner.os }}-
      
      - name: Recommend agents
        run: bash scripts/recommend_agents.sh --cache-expiry=604800
```

#### GitLab CI

```yaml
setup_agents:
  cache:
    key: claude-agents-cache
    paths:
      - .cache/claude-agents
  script:
    - export XDG_CACHE_HOME=$CI_PROJECT_DIR/.cache
    - bash scripts/recommend_agents.sh --cache-expiry=604800
```

#### Jenkins

```groovy
pipeline {
  agent any
  stages {
    stage('Setup Agents') {
      steps {
        cache(maxCacheSize: 100, caches: [
          arbitraryFileCache(
            path: '.cache/claude-agents',
            cacheValidityDecidingFile: 'scripts/recommend_agents.sh'
          )
        ]) {
          sh '''
            export XDG_CACHE_HOME=$WORKSPACE/.cache
            bash scripts/recommend_agents.sh --cache-expiry=604800
          '''
        }
      }
    }
  }
}
```

## Troubleshooting

### Network Failures

#### Symptom: All retry attempts fail

```
Error: Failed to download from https://... after 3 attempts
```

**Diagnosis**:
1. Check internet connection: `ping -c 5 raw.githubusercontent.com`
2. Test URL directly: `curl -I https://raw.githubusercontent.com/...`
3. Check for proxy/firewall: `echo $http_proxy $https_proxy`
4. Verify DNS resolution: `nslookup raw.githubusercontent.com`

**Solutions**:
- Wait and retry (server may be temporarily unavailable)
- Configure proxy if behind corporate firewall
- Use cached data if available
- Try alternative branch: `--branch main`

#### Symptom: Timeout errors (HTTP 000)

```
Attempt 1 failed (HTTP 000). Retrying in 1s...
```

**Diagnosis**:
- HTTP 000 indicates connection timeout or DNS failure
- Check network connectivity
- Verify firewall rules

**Solutions**:
- Increase timeout (requires script modification)
- Check firewall/proxy settings
- Use VPN if network is restricted
- Work offline with cached data

#### Symptom: HTTP 403 Forbidden

```
Attempt 1 failed (HTTP 403). Retrying in 1s...
```

**Diagnosis**:
- GitHub rate limiting (rare for raw.githubusercontent.com)
- IP blocked by firewall
- Authentication required

**Solutions**:
- Wait 1 hour for rate limit reset
- Use different network/IP
- Check with network administrator
- Use cached data

#### Symptom: HTTP 404 Not Found

```
Attempt 1 failed (HTTP 404). Retrying in 1s...
```

**Diagnosis**:
- URL incorrect
- Branch doesn't exist
- File moved or deleted

**Solutions**:
- Verify branch: `--branch main`
- Check repository: `--repo https://raw.githubusercontent.com/...`
- Update script to latest version
- Report issue if file should exist

### Cache Issues

#### Symptom: Stale data being used

**Diagnosis**:
- Cache hasn't expired yet
- Cache expiry set too long

**Solutions**:
```bash
# Force refresh
bash scripts/recommend_agents.sh --force-refresh

# Clear cache
bash scripts/recommend_agents.sh --clear-cache

# Reduce expiry
bash scripts/recommend_agents.sh --cache-expiry=3600
```

#### Symptom: Cache not being used

**Diagnosis**:
- Cache directory doesn't exist
- Permission issues
- Cache files corrupted

**Solutions**:
```bash
# Check cache directory
ls -la ~/.cache/claude-agents

# Check permissions
ls -ld ~/.cache/claude-agents

# Recreate cache directory
mkdir -p ~/.cache/claude-agents

# Clear and rebuild cache
bash scripts/recommend_agents.sh --clear-cache
bash scripts/recommend_agents.sh
```

#### Symptom: Cache directory full

**Diagnosis**:
- Too many cached files
- Large cache size

**Solutions**:
```bash
# Check cache size
du -sh ~/.cache/claude-agents

# Clear cache
bash scripts/recommend_agents.sh --clear-cache

# Use custom cache location
bash scripts/recommend_agents.sh --cache-dir=/tmp/agents-cache
```

### Performance Issues

#### Symptom: Slow downloads

**Diagnosis**:
- Slow network connection
- Server throttling
- Large files

**Solutions**:
- Use longer cache expiry to reduce downloads
- Work offline with cached data
- Use faster network connection
- Enable verbose mode to identify bottlenecks

#### Symptom: Excessive network usage

**Diagnosis**:
- Cache not being used
- Cache expiry too short
- Force refresh being used unnecessarily

**Solutions**:
```bash
# Increase cache expiry
bash scripts/recommend_agents.sh --cache-expiry=604800

# Verify cache is working
bash scripts/recommend_agents.sh --verbose

# Don't use --force-refresh unless needed
bash scripts/recommend_agents.sh  # Uses cache
```

## Advanced Usage

### Custom Retry Logic

While the script has built-in retry logic, you can wrap it for additional resilience:

```bash
#!/bin/bash
# retry_wrapper.sh

max_script_retries=3
attempt=1

while [[ $attempt -le $max_script_retries ]]; do
  if bash scripts/recommend_agents.sh "$@"; then
    echo "Success on attempt $attempt"
    exit 0
  fi
  
  echo "Script failed on attempt $attempt, retrying..."
  ((attempt++))
  sleep 5
done

echo "Script failed after $max_script_retries attempts"
exit 1
```

### Cache Warming

Pre-populate cache for offline use:

```bash
#!/bin/bash
# warm_cache.sh

echo "Warming cache for offline use..."

# Download all agents
bash scripts/recommend_agents.sh --force-refresh

# Verify cache
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-agents"
file_count=$(find "$cache_dir" -type f | wc -l)

echo "Cache warmed: $file_count files cached"
echo "Cache location: $cache_dir"
echo "Cache size: $(du -sh "$cache_dir" | cut -f1)"
```

### Cache Monitoring

Monitor cache usage over time:

```bash
#!/bin/bash
# monitor_cache.sh

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-agents"

echo "Cache Statistics"
echo "================"
echo "Location: $cache_dir"
echo "Files: $(find "$cache_dir" -type f 2>/dev/null | wc -l)"
echo "Size: $(du -sh "$cache_dir" 2>/dev/null | cut -f1)"
echo ""
echo "Oldest file: $(find "$cache_dir" -type f -exec stat -f "%Sm %N" -t "%Y-%m-%d %H:%M:%S" {} \; 2>/dev/null | sort | head -1)"
echo "Newest file: $(find "$cache_dir" -type f -exec stat -f "%Sm %N" -t "%Y-%m-%d %H:%M:%S" {} \; 2>/dev/null | sort | tail -1)"
```

### Shared Team Cache

Share cache across team members:

```bash
# Setup shared cache directory
export SHARED_CACHE="/shared/team/claude-agents-cache"
mkdir -p "$SHARED_CACHE"
chmod 775 "$SHARED_CACHE"

# Use shared cache
bash scripts/recommend_agents.sh --cache-dir="$SHARED_CACHE"

# Add to team's .bashrc or .zshrc
echo 'export CLAUDE_AGENTS_CACHE="/shared/team/claude-agents-cache"' >> ~/.bashrc
echo 'alias recommend-agents="bash scripts/recommend_agents.sh --cache-dir=\$CLAUDE_AGENTS_CACHE"' >> ~/.bashrc
```

### Cache Cleanup Automation

Automate cache cleanup with cron:

```bash
# Add to crontab (run weekly)
0 0 * * 0 bash /path/to/scripts/recommend_agents.sh --clear-cache

# Or use a cleanup script
#!/bin/bash
# cleanup_old_cache.sh

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-agents"
max_age_days=7

find "$cache_dir" -type f -mtime +$max_age_days -delete

echo "Cleaned cache files older than $max_age_days days"
```

## Best Practices

1. **Use Default Cache**: Let the script manage cache automatically for most use cases
2. **Force Refresh Sparingly**: Only use `--force-refresh` when you need guaranteed fresh data
3. **Longer Expiry for Stable Environments**: Use `--cache-expiry=604800` (1 week) for production
4. **Shorter Expiry for Development**: Use `--cache-expiry=3600` (1 hour) when actively developing
5. **Clear Cache Periodically**: Run `--clear-cache` monthly to free disk space
6. **Monitor Cache Size**: Check cache size if disk space is limited
7. **Use Verbose Mode for Debugging**: Add `--verbose` to understand cache behavior
8. **Leverage CI/CD Caching**: Integrate with your CI/CD system's cache mechanism
9. **Prepare for Offline**: Run script online first to populate cache before going offline
10. **Document Team Practices**: Share cache configuration with team members

## Summary

The network operations and caching system provides:

- **Reliability**: Automatic retry with exponential backoff
- **Performance**: Intelligent caching reduces network requests
- **Flexibility**: Configurable cache location and expiry
- **Offline Support**: Work with cached data when network unavailable
- **Diagnostics**: Detailed error messages and troubleshooting guidance

For most users, the default configuration works well. Use the flags and advanced features when you need more control over network behavior and caching strategy.
