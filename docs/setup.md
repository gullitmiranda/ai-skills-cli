# Setup

First-install and new-machine onboarding for `ai-skills`.

## Prerequisites

Ensure the following are available:

| Tool | Purpose |
|------|---------|
| `git` | Clone repos, fetch skill sources |
| `gh` | GitHub auth for private repos |
| `jq` | JSON manipulation for manifest |
| `bash` | Runtime (4.0+, macOS ships 3.x -- install via `brew install bash`) |

## Install

Clone to your personal code directory:

```bash
git clone https://github.com/gullitmiranda/ai-skills-cli.git \
  ~/Code/<personal>/ai-skills-cli
```

## Bootstrap

Run bootstrap to install core skills and configure agent adapters:

```bash
cd ~/Code/<personal>/ai-skills-cli
./bin/ai-skills bootstrap
```

This creates `~/.ai-skills/` (state dir), installs core skills from `skills/core/`, and links them into configured agent directories (`~/.cursor/skills`, `~/.claude/skills`, `~/.codex/skills`).

## Verify

```bash
./bin/ai-skills doctor
```

Doctor checks: required tools, `gh` auth status, state directory, manifest integrity, agent directories, and installed skill symlinks.

## Add to PATH (optional)

Add the CLI to your shell so `ai-skills` works from anywhere:

```bash
# ~/.zshrc or ~/.bashrc
export PATH="$HOME/Code/<personal>/ai-skills-cli/bin:$PATH"
```

Reload your shell or run `source ~/.zshrc`.

## Custom Alias

Create an alias during install for convenience:

```bash
./scripts/install --alias <your-alias>
```

Or add a shell alias manually:

```bash
# ~/.zshrc or ~/.bashrc
alias <your-alias>=ai-skills
```

## Adding Your First External Skill Repo

After bootstrap, add an external skill repository:

```bash
ai-skills add gullitmiranda/gullit-skills
```

This clones the repo, discovers skills, and installs them into all configured agents. See [operations.md](operations.md) for more commands.
