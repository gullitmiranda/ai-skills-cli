# ai-skills-cli

Package manager for AI agent skills. Installs, updates, and manages skills from GitHub repositories into local agent directories.

## Supported Agents

- Cursor
- Claude
- Codex
- pi-mono
- Copilot

## Repository Structure

- `bin/ai-skills` - Main CLI entrypoint
- `skills/core/` - Required/base skills shipped with the CLI
- `scripts/` - Install and setup scripts
- `docs/` - Setup, operations, and repository documentation

## Install

### One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/gullitmiranda/ai-skills-cli/main/scripts/install | bash
```

### Review before execute

Downloads the script first so you can inspect it before running anything:

```bash
curl -fsSL https://raw.githubusercontent.com/gullitmiranda/ai-skills-cli/main/scripts/install -o /tmp/ai-skills-install.sh && \
  less /tmp/ai-skills-install.sh && \
  read -p "Execute? [y/N] " -n 1 -r && echo && \
  [[ $REPLY =~ ^[Yy]$ ]] && bash /tmp/ai-skills-install.sh
```

### Local (from cloned repo)

```bash
git clone https://github.com/gullitmiranda/ai-skills-cli.git ~/Code/personal/ai-skills-cli
cd ~/Code/personal/ai-skills-cli
./scripts/install
```

### Options

```bash
# Custom clone location
curl -fsSL .../scripts/install | bash -s -- --clone-dir ~/my/custom/path

# Install with an alias
./scripts/install --alias my-alias

# Skip doctor check
./scripts/install --no-doctor
```

### PATH Setup

The installer places `ai-skills` in `~/.local/bin/`. If that directory is not in your PATH, add it:

```bash
# ~/.zshrc or ~/.bashrc
export PATH="$HOME/.local/bin:$PATH"
```

## Usage

```bash
# Add a skill from a GitHub repository
ai-skills add https://github.com/org/repo/tree/main/skills/my-skill

# Update all installed skills
ai-skills update

# Remove an installed skill
ai-skills remove <source-id>

# List installed skills
ai-skills list

# Check health of setup
ai-skills doctor

# Pull latest CLI and re-run setup
ai-skills self-update
```

## Uninstall

```bash
ai-skills self-uninstall
ai-skills self-uninstall --purge  # also removes ~/.ai-skills/ state
```
