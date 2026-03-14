# ai-skills-cli

Package manager for AI agent skills. Installs, updates, and manages skills from GitHub repositories into local agent directories.

Built on the [Agent Skills](https://agentskills.io) open standard.

## How It Works

Skill repositories on GitHub contain `SKILL.md` files following the [agentskills.io spec](https://agentskills.io/specification). The CLI clones them, discovers skills, and symlinks them into the right agent directories on your machine. Changes you make to installed skills propagate back to the source repo.

```
GitHub                          Local machine
──────                          ─────────────
owner/my-skills                 ~/.cursor/skills/my-skill/SKILL.md
  skills/my-skill/SKILL.md  ──► ~/.claude/skills/my-skill/SKILL.md
  .cursor/skills/only-cursor/   ~/.cursor/skills/only-cursor/SKILL.md
```

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/gullitmiranda/ai-skills-cli/main/scripts/install | bash
```

Or review the script before running:

```bash
curl -fsSL https://raw.githubusercontent.com/gullitmiranda/ai-skills-cli/main/scripts/install -o /tmp/ai-skills-install.sh && \
  less /tmp/ai-skills-install.sh && \
  read -p "Execute? [y/N] " -n 1 -r && echo && \
  [[ $REPLY =~ ^[Yy]$ ]] && bash /tmp/ai-skills-install.sh
```

From a cloned repo:

```bash
git clone https://github.com/gullitmiranda/ai-skills-cli.git ~/Code/personal/ai-skills-cli
cd ~/Code/personal/ai-skills-cli
./scripts/install
```

The installer places `ai-skills` in `~/.local/bin/`. If not in your PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"  # add to ~/.zshrc or ~/.bashrc
```

## Usage

### Add skills

```bash
# From a full repository (installs all discovered skills)
ai-skills add owner/skills-repo

# From a specific skill within a repo
ai-skills add https://github.com/owner/repo/tree/main/skills/my-skill

# Pin to a version
ai-skills add owner/repo --ref v1.0.0

# Target a specific agent only
ai-skills add owner/repo --agent cursor

# Preview without installing
ai-skills add owner/repo --dry-run
```

### Manage skills

```bash
# List installed skills
ai-skills list

# Update all installed skills
ai-skills update

# Update a specific skill
ai-skills update owner/repo/skills/my-skill

# Remove an installed skill
ai-skills remove owner/repo/skills/my-skill
```

### Diagnostics and maintenance

```bash
# Check agent directories, manifest, and tool availability
ai-skills doctor

# Pull latest CLI version and re-run setup
ai-skills self-update
```

## Skill Discovery

When installing from a skill repository, the CLI discovers skills in this order:

1. **Agent-specific**: `.<agent>/skills/*/` (e.g. `.cursor/skills/my-skill/`)
2. **Cross-agent**: `.agents/skills/*/`
3. **Generic**: `skills/*/`
4. **Root**: `SKILL.md` at repo root (single skill)

A skill repository can mix these to provide common and agent-specific skills:

```
my-skills-repo/
├── skills/                     # common skills (installed to all agents)
│   ├── code-review/
│   │   └── SKILL.md
│   └── testing/
│       └── SKILL.md
├── .cursor/skills/             # cursor-specific skills
│   └── cursor-only/
│       └── SKILL.md
└── .claude/skills/             # claude-specific skills
    └── claude-only/
        └── SKILL.md
```

## Supported Agents

| Agent | Target directory | Status |
|-------|-----------------|--------|
| Cursor | `~/.cursor/skills/` | Active |
| Claude | `~/.claude/skills/` | Active |
| Codex | `~/.codex/skills/` | Active |
| pi-mono | `~/.agents/skills/` | Active |
| Copilot | `~/.github/skills/` | Placeholder |

## Repository Structure

```
ai-skills-cli/
├── bin/ai-skills           # CLI entrypoint
├── skills/core/            # Core skills shipped with the CLI
├── config/agents.yaml      # Agent adapter configuration
├── scripts/
│   ├── install             # Remote + local installer
│   └── setup               # Post-clone setup (symlinks, bootstrap, doctor)
└── docs/
    ├── setup.md            # First-install guide
    ├── operations.md       # Day-2 operations
    ├── agent-adapters.md   # Agent discovery paths and the agentskills.io standard
    ├── auth-profiles.md    # Path-based GitHub profile routing
    ├── source-policy.md    # Trusted source policy
    └── repositories.md     # Repository responsibility boundaries
```

## Uninstall

```bash
ai-skills self-uninstall
ai-skills self-uninstall --purge  # also removes ~/.ai-skills/ state
```
