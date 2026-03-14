# ai-skills-cli

Package manager for AI agent skills. Installs, updates, and manages skills from GitHub repositories into local agent directories.

## CLI

Primary command: `ai-skills`
Work ecosystem alias: `cw-skills`

## Structure

- `skills/core/` - Required/base skills shipped with the CLI
- `scripts/` - Bootstrap, add-skill, update, doctor
- `state/` - Local manifest/lock and metadata (gitignored)
- `docs/` - Setup, operations, and repository documentation

## Quick Start

```bash
# Bootstrap core skills and agent adapters
./scripts/bootstrap

# Add a skill from a GitHub repository
ai-skills add https://github.com/org/repo/tree/main/skills/my-skill

# Update all installed skills
ai-skills update

# Check health of installed skills and agent links
ai-skills doctor
```

## Supported Agents (v1)

- Cursor
- Claude
- Codex
- pi-mono
