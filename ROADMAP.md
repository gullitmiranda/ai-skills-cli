# Roadmap

Planned features, improvements, and tech debt for ai-skills-cli.

## Planned Features

- [ ] **Cache Edit Guardrails** — make it impossible (or loudly obvious) to commit/push directly inside `~/.ai-skills/repos/<profile>/<owner>/<repo>/`. Today, agents and humans can — and do — edit through symlinks (e.g. `~/.cursor/skills/<name>`), commit on the cache repo, and even push to the upstream from there. The cache is meant to be a managed clone, not a working repo. Required pieces:
  - [x] Core skill `skills/core/ai-skills-cache-safety/SKILL.md` shipped via `ai-skills bootstrap`: agent-side rule that detects cache paths (prefix + `.ai-skills-cache` marker) and refuses git writes with a redirect procedure.
  - [ ] On clone (in `ai-skills add`), drop a `.ai-skills-cache` marker file at the cached repo root with metadata (source URL, profile, cached-at). The marker is also what the core skill above keys off when the path prefix check is ambiguous.
  - [ ] On clone, install a `pre-commit` hook in the cache repo's `.git/hooks/` that aborts with an actionable message ("use `ai-skills publish` or edit in the source clone; bypass with `--no-verify` if you really mean it"). Tool-side enforcement to back up the agent-side skill.
  - [ ] `ai-skills publish <repo>` — supported escape hatch (see below) so the hook and core skill have a real alternative to point users to.
  - [ ] `ai-skills link <local-path>` — primary fix (see below) so symlinks point at the user's own clone instead of the cache.
  - [ ] Doctor checks (see Diagnostics) round out the system by surfacing existing drift before damage spreads.
- [ ] **Profiles** — git credential routing via `includeIf` per profile
  - [ ] `config.json` with `default_profile` and `profiles` map (name -> repos_dir)
  - [ ] `--profile <name>` flag on `add` to override default
  - [ ] `ai-skills profile list` — show configured profiles
  - [ ] `ai-skills profile default <name>` — set the default profile
  - [ ] `ai-skills profile add <name> --repos-dir <path>` — register a new profile
  - [ ] Repos cloned into `~/.ai-skills/repos/<profile>/<owner>/<repo>` so `includeIf` applies per profile
  - [ ] Document required `includeIf` gitconfig entries in setup docs
- [ ] `ai-skills publish <repo>` — supported escape hatch for changes that landed in the cache: detect commits ahead of upstream, open a PR or push to a feature branch on the source repo. Pairs with the cache `pre-commit` hook so the hook can point users at a real next step.
- [ ] `ai-skills diff <repo>` — show local modifications and unpublished commits in a cache clone vs upstream. Used as the "what's about to be lost" preview before `ai-skills update`, `ai-skills publish`, or a `git reset --hard origin/<branch>`.
- [ ] `ai-skills link <local-path>` — register an existing local clone (e.g. `~/code/gullit/gullit-skills`) as the source for its repo. The CLI then **points symlinks at the local clone instead of the cache**, eliminating the cache-edit problem at the root for users who maintain their own working copy.
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
- [ ] Detect uncommitted changes, local commits ahead of upstream, or local-only branches in cache repos. For each, suggest one of: `ai-skills publish <repo>`, `ai-skills diff <repo>`, or `git -C <cache-path> reset --hard origin/<branch>`. Part of the **Cache Edit Guardrails** system (see Planned Features).
- [ ] Detect when a registered local source clone exists (`ai-skills link`) but symlinks still point at the cache, and offer to relink. Part of the **Cache Edit Guardrails** system.
- [ ] Show a summary section "How to fix" at the end with copy-pasteable commands

## Nice to Have

- [ ] Shell completions (bash, zsh, fish)
- [ ] `ai-skills search` — search GitHub for skill repositories
- [ ] Manifest lock file for reproducible installs across machines
- [ ] `ai-skills init` — scaffold a new skill repository
