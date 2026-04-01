# Roadmap

Planned features, improvements, and tech debt for ai-skills-cli.

## Planned Features

- [ ] **Profiles** — git credential routing via `includeIf` per profile
  - [ ] `config.json` with `default_profile` and `profiles` map (name -> repos_dir)
  - [ ] `--profile <name>` flag on `add` to override default
  - [ ] `ai-skills profile list` — show configured profiles
  - [ ] `ai-skills profile default <name>` — set the default profile
  - [ ] `ai-skills profile add <name> --repos-dir <path>` — register a new profile
  - [ ] Repos cloned into `~/.ai-skills/repos/<profile>/<owner>/<repo>` so `includeIf` applies per profile
  - [ ] Document required `includeIf` gitconfig entries in setup docs
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

## Diagnostics

Doctor should be **actionable** — every warning must include a fix command or instruction.

- [ ] Detect broken symlinks and suggest: `ai-skills add <source> --profile <profile>` to fix
- [ ] Detect stale manifest entries (skill in manifest but missing from filesystem) and suggest: `ai-skills remove <source-id>` or reinstall
- [ ] Detect skills installed in wrong profile (clone in different profile than expected) and suggest migration
- [ ] Detect duplicate skills across agent directories (Cursor cross-loading from `.claude/` and `.codex/`)
- [ ] Detect uncommitted changes in cloned repos and warn before update
- [ ] Show a summary section "How to fix" at the end with copy-pasteable commands

## Nice to Have

- [ ] Shell completions (bash, zsh, fish)
- [ ] `ai-skills search` — search GitHub for skill repositories
- [ ] Manifest lock file for reproducible installs across machines
- [ ] `ai-skills init` — scaffold a new skill repository
