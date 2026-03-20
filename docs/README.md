# Documentation

This directory contains detailed technical documentation for the Claude Skills Library project.

## Available Documentation

### Network Operations
- **[NETWORK_OPERATIONS.md](NETWORK_OPERATIONS.md)** - Comprehensive guide to network operations, retry logic, and caching
  - Retry mechanism with exponential backoff
  - Intelligent caching system
  - Offline workflow support
  - Troubleshooting network failures
  - Advanced usage patterns
  - CI/CD integration examples

- **[NETWORK_QUICK_REFERENCE.md](NETWORK_QUICK_REFERENCE.md)** - Quick reference card for network operations
  - Common commands
  - Cache control
  - Troubleshooting tips
  - HTTP status codes
  - Best practices

### Testing
- **[TESTING_INTERACTIVE_MODE.md](TESTING_INTERACTIVE_MODE.md)** - Guide to testing the interactive mode
  - Test structure and organization
  - Running interactive tests
  - Writing new tests
  - Troubleshooting test failures

### Scoring & Detection
- **[CONFIDENCE_CALCULATION.md](CONFIDENCE_CALCULATION.md)** - How confidence scores are calculated
  - Pattern matching weights
  - Score normalization
  - Recommendation thresholds
  - DevOps orchestrator boosting logic

## Quick Links

### For Users
- Start with [NETWORK_QUICK_REFERENCE.md](NETWORK_QUICK_REFERENCE.md) for common commands
- Read [NETWORK_OPERATIONS.md](NETWORK_OPERATIONS.md) for detailed network documentation
- Check [CONFIDENCE_CALCULATION.md](CONFIDENCE_CALCULATION.md) to understand recommendations

### For Developers
- Review [TESTING_INTERACTIVE_MODE.md](TESTING_INTERACTIVE_MODE.md) for test development
- See [CONFIDENCE_CALCULATION.md](CONFIDENCE_CALCULATION.md) for scoring algorithm details
- Read [NETWORK_OPERATIONS.md](NETWORK_OPERATIONS.md) for implementation details

## Main Documentation

For general usage documentation, see:
- **[../README.md](../README.md)** - Project overview and quick start
- **[../GETTING_STARTED.md](../GETTING_STARTED.md)** - Beginner's guide
- **[../CLAUDE_CODE_USAGE.md](../CLAUDE_CODE_USAGE.md)** - Comprehensive usage guide
- **[../.claude/skills/SKILLS_REGISTRY.md](../.claude/skills/SKILLS_REGISTRY.md)** - Complete skills catalog

## Contributing

When adding new documentation:
1. Place technical documentation in this `docs/` directory
2. Update this README with a link to your new document
3. Add references in main documentation files where appropriate
4. Follow the existing documentation style and format
