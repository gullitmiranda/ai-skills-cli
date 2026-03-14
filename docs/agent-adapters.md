# Agent Adapters

How `ai-skills` discovers, installs, and manages skills across different AI coding agents following the [Agent Skills open standard](https://agentskills.io).

## The Agent Skills Standard

The **Agent Skills** open standard (agentskills.io) defines a portable format for packaging reusable capabilities that AI coding agents can load at runtime. The standard specifies:

- A **SKILL.md** file as the skill entry point
- A **directory structure** convention for organizing skill assets
- **Discovery paths** so agents can find skills in repositories and on disk

The `ai-skills` CLI implements this standard for installation, discovery, and management.

## SKILL.md Format

Every skill is a directory containing a `SKILL.md` file. The file uses YAML frontmatter followed by Markdown instructions:

```markdown
---
name: my-skill
description: Short description of what this skill does.
# Optional fields:
# version: 1.0.0
# tags: [git, workflow]
# agent: cursor          # if agent-specific
# globs: ["*.ts"]        # file patterns the skill applies to
---

Instructions the agent reads when the skill is activated.

## When to Use

Describe trigger conditions here.

## Steps

1. Step-by-step instructions for the agent.
```

**Required frontmatter:** `name` and `description`.
All other fields are optional and agent-dependent.

## Standard Directory Structure

Each skill lives in its own directory under a discovery path:

```
skill-name/
  SKILL.md              # required — entry point
  scripts/              # optional — helper scripts the skill invokes
  references/           # optional — reference docs, examples, templates
  assets/               # optional — images, config files, other resources
```

## Supported Agents

| Agent | Target Directory | Status | Notes |
|-------|-----------------|--------|-------|
| cursor | `~/.cursor/skills/` | Active | Also reads `.claude/` and `.codex/` skills |
| claude | `~/.claude/skills/` | Active | Claude Code |
| codex | `~/.codex/skills/` | Active | Codex CLI |
| pi-mono | `~/.agents/skills/` | Active | Uses cross-agent standard path |
| copilot | `~/.github/skills/` | Placeholder | Provisional path |

## Skill Discovery Paths

When installing from a repository, the CLI probes paths in order for each agent:

| Agent | Priority 1 | Priority 2 | Priority 3 | Priority 4 | Fallback |
|-------|-----------|-----------|-----------|-----------|----------|
| cursor | `.cursor/skills/` | `.claude/skills/` | `.codex/skills/` | `.agents/skills/` | `skills/` |
| claude | `.claude/skills/` | `.agents/skills/` | `skills/` | — | — |
| codex | `.codex/skills/` | `.agents/skills/` | `skills/` | — | — |
| pi-mono | `.pi/skills/` | `.agents/skills/` | `skills/` | — | — |
| copilot | `.github/skills/` | `.agents/skills/` | `skills/` | — | — |

If none of these paths exist, the CLI checks for a `SKILL.md` at the repo root (single-skill repository).

Every subdirectory under a matched path that contains a `SKILL.md` is treated as one installable skill. Duplicates across paths are deduplicated by directory name.

## Cross-Agent Compatibility

**Cursor** has the broadest discovery: it reads from `.cursor/skills/`, `.claude/skills/`, and `.codex/skills/` in addition to the standard `.agents/skills/` and `skills/` paths. This means skills written for Claude or Codex are automatically available in Cursor without duplication.

Other agents discover only from their own agent-specific path plus the shared locations (`.agents/skills/` and `skills/`).

### Cursor cross-loading and duplicates

Cursor has a setting **"Include third-party Plugins, Skills, and other configs"** (in Cursor Settings > Rules, Skills, Subagents) that controls whether it auto-imports from other agents' directories (`~/.claude/skills/`, `~/.codex/skills/`, etc.).

- **Toggle ON** (default): Cursor loads skills from its own directory **and** other agents' directories. If `ai-skills` installed the same skill to both `~/.cursor/skills/` and `~/.claude/skills/`, Cursor will see it **twice**.
- **Toggle OFF**: Cursor only loads from `~/.cursor/skills/`.

If you use Cursor with this toggle enabled, consider either:
- Installing common skills only to `~/.claude/skills/` (Cursor will pick them up automatically)
- Or installing to `~/.cursor/skills/` only via `--agent cursor` and letting other agents get their own copies

The `ai-skills` CLI installs to each configured agent independently. A future `ai-skills doctor` check may detect and warn about duplicates across agent directories.

## How to Organize a Skill Repository

Use these conventions to maximize portability:

```
my-skills-repo/
  skills/                       # cross-agent skills (all agents discover this)
    shared-lint/
      SKILL.md
    shared-git/
      SKILL.md
  .agents/skills/               # cross-agent standard location (agentskills.io)
    workflow/
      SKILL.md
  .cursor/skills/               # cursor-specific skills
    cursor-rules/
      SKILL.md
  .claude/skills/               # claude-specific skills (cursor also reads these)
    claude-tooling/
      SKILL.md
  .codex/skills/                # codex-specific skills (cursor also reads these)
    codex-sandbox/
      SKILL.md
  .pi/skills/                   # pi-mono-specific skills
    pi-config/
      SKILL.md
  .github/skills/               # copilot-specific skills (placeholder)
    copilot-actions/
      SKILL.md
```

**Guidelines:**

- Put **common/cross-agent skills** in `skills/` — every agent discovers this path.
- Put **cross-agent standard skills** in `.agents/skills/` — the agentskills.io canonical location.
- Put **agent-specific skills** in `.<agent>/skills/` — only that agent (and Cursor for `.claude/` and `.codex/`) discovers them.
- Skills in `skills/` and `.agents/skills/` should avoid agent-specific features to stay portable.

## How Agents Consume Skills

Each agent has its own mechanism for loading skills at runtime:

- **Cursor** — Reads `<available_skills>` entries from project rules. Each skill directory must contain a `SKILL.md` with a description and instructions. Auto-discovers from `.claude/skills/` and `.codex/skills/` for compatibility.
- **Claude Code** — Loads skills from `~/.claude/skills/` on session start. Same `SKILL.md` contract.
- **Codex** — Loads skills from `~/.codex/skills/`. Same `SKILL.md` contract.
- **Pi-mono** — Loads skills from `~/.agents/skills/`. Discovers from `.pi/skills/` for agent-specific content.
- **Copilot** — Provisional. Target path `~/.github/skills/` is subject to change.

## Adding a New Agent Adapter

1. Add an entry to `config/agents.yaml` with `target_dir`, `discovery` paths, and `status`.

2. Register the agent directory in `bin/ai-skills`:

```bash
declare -A AGENT_DIRS=(
  # ... existing entries ...
  [new-agent]="$HOME/.new-agent/skills"
)

readonly SUPPORTED_AGENTS=("cursor" "claude" "codex" "pi-mono" "copilot" "new-agent")
```

3. Run `ai-skills doctor` to verify the new agent directory is detected.

4. Test with `ai-skills add owner/repo --agent new-agent --dry-run`.

## Known Limitations

| Agent | Limitation |
|-------|-----------|
| cursor | Skill discovery in project-scoped `.cursor/skills/` is separate from the global install path. The CLI manages global only. |
| claude | No namespace isolation — all skills share a flat directory under `~/.claude/skills/`. |
| codex | Same flat-directory constraint as Claude. |
| pi-mono | Uses the generic `~/.agents/skills/` path, which may overlap with other agents using the same standard location. |
| copilot | Target path and loading mechanism unconfirmed. Do not install skills to this agent yet. |

## Reference

- [Agent Skills open standard](https://agentskills.io) — the specification this CLI implements.
- `config/agents.yaml` — adapter configuration file.
- `docs/source-policy.md` — source trust and verification policy.
