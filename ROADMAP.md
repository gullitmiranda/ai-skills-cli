# Roadmap

Planned features, improvements, and tech debt for ai-skills-cli.

## Planned Features

- [ ] `ai-skills publish` — commit and push local skill changes back to the source repository
- [ ] `ai-skills diff` — show local modifications to installed skills vs source
- [ ] `ai-skills link <local-path>` — symlink a local skill repo directly (skip clone)
- [ ] Namespace-aware install defaults for team repos (e.g. platform common vs internal)
- [ ] Conflict detection when two sources provide the same skill id

## Tech Debt

- [ ] Validate SKILL.md frontmatter on install (name, description required per agentskills.io spec)
- [ ] `ai-skills remove` only removes by basename — should handle nested paths and multiple skills from same source
- [ ] Agent adapter config (`config/agents.yaml`) is not consumed by the CLI yet — discovery paths are hardcoded in `discover_skills()`
- [ ] `scripts/setup` duplicates color/output helpers from `bin/ai-skills` — extract shared lib
- [ ] `skills/core/` is empty — define what core skills ship with the CLI

## Future Agents

- [ ] Copilot adapter is placeholder — confirm target path and discovery behavior
- [ ] pi-mono adapter needs confirmation of official config path

## Nice to Have

- [ ] Shell completions (bash, zsh, fish)
- [ ] `ai-skills search` — search GitHub for skill repositories
- [ ] Manifest lock file for reproducible installs across machines
- [ ] `ai-skills init` — scaffold a new skill repository
