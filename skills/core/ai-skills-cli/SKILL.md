---
name: ai-skills-cli
description: >-
  Manage AI agent skills via the ai-skills CLI - install, update, remove, list,
  diagnose, and configure profiles. Use when the user asks to add a skill repo,
  update skills, remove a skill, list installed skills, run doctor, manage
  profiles, or self-update the CLI.
---

# ai-skills CLI

Package manager for AI agent skills. Installs, updates, and manages skills from
GitHub repositories into local agent directories (`~/.cursor/skills/`,
`~/.claude/skills/`, `~/.codex/skills/`, `~/.agents/skills/`).

## Prerequisites

The CLI requires `git` and `jq`. Run `ai-skills doctor` to verify.

## Commands Reference

### Install skills

```bash
# Full repository (discovers and installs all skills)
ai-skills add owner/repo

# Specific skill within a repo
ai-skills add owner/repo --path skills/my-skill

# From a GitHub URL (extracts owner/repo/ref/path automatically)
ai-skills add https://github.com/owner/repo/tree/main/skills/my-skill

# Pin to a version tag or branch
ai-skills add owner/repo --ref v1.0.0

# Target a single agent
ai-skills add owner/repo --agent cursor

# Use a specific auth profile
ai-skills add owner/repo --profile work

# Preview without changes
ai-skills add owner/repo --dry-run
```

### Update skills

```bash
# Update all installed skills (re-fetches repos, re-links)
ai-skills update

# Update a specific skill by its source ID
ai-skills update owner/repo/skills/my-skill
```

### Remove skills

```bash
# Remove a skill from all agents and the manifest
ai-skills remove owner/repo/skills/my-skill
```

The source ID is shown in `ai-skills list` output.

### List installed skills

```bash
ai-skills list
```

Displays a table with skill ID, ref, agents, and last update timestamp.

### Diagnostics

```bash
ai-skills doctor
```

Checks: `git`/`jq` availability, `gh` auth, state directory, manifest integrity,
agent directories, and installed skill symlink health.

### Profiles

Profiles route GitHub credentials by repository namespace.

```bash
ai-skills profile list
ai-skills profile add work --repos-dir ~/.ai-skills/repos/work
ai-skills profile default work
ai-skills profile remove old-profile
```

Use `--profile <name>` on any command to override the active profile.

### Maintenance

```bash
# Pull latest CLI and re-run setup
ai-skills self-update

# Uninstall CLI (preserves state by default)
ai-skills self-uninstall
ai-skills self-uninstall --purge   # also removes ~/.ai-skills/
```

### Bootstrap

```bash
ai-skills bootstrap
```

Initializes agent directories and installs core skills from the CLI repo.

## Global Flags

| Flag               | Description                                                                |
| ------------------ | -------------------------------------------------------------------------- |
| `--agent <name>`   | Target a specific agent: `cursor`, `claude`, `codex`, `pi-mono`, `copilot` |
| `--ref <ref>`      | Pin to branch, tag, or commit SHA                                          |
| `--path <path>`    | Subpath within the repository                                              |
| `--profile <name>` | Override active auth profile                                               |
| `--dry-run`        | Preview actions without making changes                                     |
| `--debug`          | Enable verbose debug output                                                |

## Source Formats

The `add` command accepts these formats:

- `owner/repo` - full repository
- `owner/repo/path/to/skill` - specific skill path
- `https://github.com/owner/repo` - full URL
- `https://github.com/owner/repo/tree/branch/path` - URL with branch and path

## State and Manifest

- State directory: `~/.ai-skills/` (override with `AI_SKILLS_HOME`)
- Manifest: `~/.ai-skills/manifest.json` - tracks all installed skills
- Config: `~/.ai-skills/config.json` - profiles and settings
- Cloned repos: `~/.ai-skills/repos/<profile>/<owner>/<repo>/`

Skills are installed as **symlinks** from agent directories to the cloned repos.
The cloned repos under `~/.ai-skills/repos/` are a managed cache, not a working
repo: do not commit or push from there. See the `ai-skills-cache-safety` core
skill for the full rule and redirect procedure.

## Skill Discovery Order

When installing from a repository, the CLI discovers skills in this priority:

1. Agent-specific: `.<agent>/skills/*/`
2. Cross-agent standard: `.agents/skills/*/`
3. Generic: `skills/*/`
4. Root fallback: `SKILL.md` at repo root (single-skill repo)

## Common Workflows

### First-time setup

```bash
ai-skills doctor          # verify prerequisites
ai-skills bootstrap       # initialize agent dirs + core skills
ai-skills add owner/repo  # install your first skill repo
```

### Keep skills current

```bash
ai-skills update          # pull and re-link all skills
ai-skills list            # verify state
```

### Work with multiple GitHub orgs

```bash
ai-skills profile add work --repos-dir ~/Code/work/.ai-skills/repos
ai-skills add org/repo --profile work
ai-skills profile default personal   # switch back
```

## Troubleshooting

| Symptom                    | Fix                                                                                      |
| -------------------------- | ---------------------------------------------------------------------------------------- |
| `jq: not found`            | Install jq: `brew install jq`                                                            |
| `Failed to clone`          | Check `gh auth status` or verify repo URL                                                |
| Skill missing after update | Run `ai-skills doctor` to find broken symlinks                                           |
| Duplicate skills in Cursor | Use `--agent cursor` or `--agent claude` (not both) when Cursor cross-loading is enabled |
