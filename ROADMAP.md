# Roadmap

Planned features, improvements, and tech debt for ai-skills-cli.

## Planned Features

- [ ] **Cache Edit Guardrails** — make it impossible (or loudly obvious) to commit/push directly inside `~/.ai-skills/repos/<profile>/<owner>/<repo>/`. Today, agents and humans can — and do — edit through symlinks (e.g. `~/.cursor/skills/<name>`), commit on the cache repo, and even push to the upstream from there. The cache is meant to be a managed clone, not a working repo. Required pieces:
  - [x] Core skill `skills/core/ai-skills-cache-safety/SKILL.md` shipped via `ai-skills bootstrap`: agent-side rule that detects cache paths (prefix + `.ai-skills-cache` marker) and refuses git writes with a redirect procedure.
  - [ ] On clone (in `ai-skills add`), drop a `.ai-skills-cache` marker file at the cached repo root with metadata (source URL, profile, cached-at). The marker is also what the core skill above keys off when the path prefix check is ambiguous.
  - [ ] On clone, install a `pre-commit` hook in the cache repo's `.git/hooks/` that aborts with an actionable message ("use `ai-skills push` or edit in the source clone; bypass with `--no-verify` if you really mean it"). Tool-side enforcement to back up the agent-side skill.
  - [ ] `ai-skills push <repo>` — supported escape hatch (see below) so the hook and core skill have a real alternative to point users to.
  - [ ] `ai-skills link <local-path>` — primary fix (see below) so symlinks point at the user's own clone instead of the cache.
  - [ ] Doctor checks (see Diagnostics) round out the system by surfacing existing drift before damage spreads.
- [x] **Profiles** — git credential routing via `includeIf` per profile (see [`docs/profiles.md`](docs/profiles.md))
  - [x] `config.json` with `default_profile` and `profiles` map (name -> repos_dir)
  - [x] `--profile <name>` flag on `add` to override default
  - [x] `ai-skills profile list` — show configured profiles
  - [x] `ai-skills profile default <name>` — set the default profile
  - [x] `ai-skills profile add <name> --repos-dir <path>` — register a new profile
  - [x] `ai-skills profile remove <name>` — remove a profile
  - [x] Repos cloned into `~/.ai-skills/repos/<profile>/<owner>/<repo>` so `includeIf` applies per profile
  - [x] Document required `includeIf` gitconfig entries (see `docs/profiles.md`)
- [ ] `ai-skills push <repo>` — `git push` semantics for the cache clone: send local commits back to the upstream source repo (push to a feature branch and/or open a PR). Supported escape hatch for edits that landed in the cache via symlinks. Pairs with the cache `pre-commit` hook so the hook can point users at a real next step.
- [ ] `ai-skills diff <repo>` — show local modifications and unpushed commits in a cache clone vs upstream. Used as the "what's about to be lost" preview before `ai-skills update`, `ai-skills push`, or a `git reset --hard origin/<branch>`.
- [ ] `ai-skills link <local-path>` — register an existing local clone (e.g. `~/code/gullit/gullit-skills`) as the source for its repo. The CLI then **points symlinks at the local clone instead of the cache**, eliminating the cache-edit problem at the root for users who maintain their own working copy.
  - **Status:** the underlying plumbing is already in place. `ai-skills add <local-path>` (see `is_local_path` / `resolve_local_repo` in `bin/ai-skills`) installs from a local clone today, and the manifest already distinguishes `local-worktree` (`direct-link`) from `remote-git`/`local-cache` (`cached-link`) via `source_type` / `install_mode`. What is missing is the dedicated `link` subcommand UX (register/relink/unlink, switch an existing remote-cached entry to a local source without re-running `add`).
- [ ] Namespace-aware install defaults for team repos (e.g. platform common vs internal)
- [ ] Conflict detection when two sources provide the same skill id

## Tech Debt

- [ ] Validate SKILL.md frontmatter on install (name, description required per agentskills.io spec)
- [ ] `ai-skills remove` only removes by basename — should handle nested paths and multiple skills from same source
- [ ] Agent adapter config (`config/agents.yaml`) is not consumed by the CLI yet — discovery paths are hardcoded in `discover_skills()`
- [ ] `scripts/setup` duplicates color/output helpers from `bin/ai-skills` — extract shared lib
- [ ] `ai-skills add --ref <ref>` does not enforce the requested ref against an existing cache clone. If a previous `ai-skills add` cloned the default branch (e.g. `main`) and the next call passes `--ref v3-beta`, the cache stays on `main`, the skill discovery walks the wrong tree, and the install silently fails with a misleading "no skills found" message. Repro: clone `cloudwalk/github-builder` (skills live on `v3-beta`) without `--ref`, then retry with `--ref v3-beta`. Workaround today: `rm -rf ~/.ai-skills/repos/<profile>/<owner>/<repo>` and re-run with `--ref`. Fix should `git fetch origin <ref>` + `git checkout <ref>` (or `--force`) when an existing cache repo's HEAD does not match the requested ref.

## Future Agents

- [ ] Copilot adapter is placeholder — confirm target path and discovery behavior. Note: the `vercel-labs/skills` ecosystem uses `~/.copilot/skills/` rather than our current placeholder `~/.github/skills/`; revisit before promoting the adapter to `active`.
- [ ] `agents` adapter (`~/.agents/skills/`, formerly `pi-mono`): track which clients adopt the agentskills.io cross-client convention natively. Today only pi-mono reads it directly; Claude Code support is tracked in [anthropics/claude-code#53950](https://github.com/anthropics/claude-code/issues/53950). When more clients adopt it, drop the per-agent symlinks from defaults.

## Registry / Ecosystem Parity

We share the same `SKILL.md` contract as [skills.sh](https://skills.sh/) (`vercel-labs/skills`) and [agentskill.sh](https://agentskill.sh/), so any well-formed repo is mutually installable. The gaps below are about **discovery breadth** and **frontmatter semantics**, not the core format.

- [ ] Expand `config/agents.yaml` to cover the ~45 agents enumerated by `vercel-labs/skills` (aider-desk, augment, codestudio, continue, crush, factory/droid, goose, junie, kiro, mcpjam, openhands, qoder, qwen, roo, tabnine, trae, windsurf, zencoder, etc.). Many can ship as `placeholder` until validated, but having them in the config means the (still pending) move to read `agents.yaml` from the CLI immediately benefits skills targeting those agents. Pairs with the existing tech-debt item "Agent adapter config is not consumed by the CLI yet".
- [ ] Read `.claude-plugin/marketplace.json` and `.claude-plugin/plugin.json` when present, and discover skills declared in `plugins[].skills`. Required for Claude Code plugin marketplace repos like `anthropics/skills` (`/plugin marketplace add ...`) to install correctly via `ai-skills add`.
- [ ] Honor `metadata.internal: true` in `SKILL.md` frontmatter — hide marked skills from `ai-skills add --list` and from default install unless `INSTALL_INTERNAL_SKILLS=1` is set. Combine with the existing tech-debt item "Validate SKILL.md frontmatter on install" so we get parsing + the internal flag in one pass.
- [ ] Project-scope installs (`-p`/default) vs global (`-g`). Today every install lands under `~/<agent>/skills/`. Project scope would target `./<agent>/skills/` so teams can commit installed skills with their codebase, matching the convention used by `vercel-labs/skills`. Requires touching the manifest (`~/.ai-skills/state` vs in-project state file) and `doctor` checks.

## Diagnostics

Doctor should be **actionable** — every warning must include a fix command or instruction.

- [x] Detect broken symlinks and surface them in `doctor` (with `rm <path>` fix)
- [x] Detect stale manifest entries (skill in manifest but missing from filesystem) and suggest `ai-skills add <source>` to reinstall
- [x] Detect unmanaged skill directories under agent dirs (real dirs, not symlinks) and suggest cleanup
- [ ] Detect skills installed in wrong profile (clone in different profile than expected) and suggest migration. Note: `clone_or_update_repo` already prompts for migration interactively when a repo is found in another profile (`bin/ai-skills` ~L320), but `doctor` does not flag the steady-state case.
- [ ] Detect duplicate skills across agent directories (Cursor cross-loading from `.claude/` and `.codex/`)
- [ ] Detect uncommitted changes, local commits ahead of upstream, or local-only branches in cache repos. For each, suggest one of: `ai-skills push <repo>`, `ai-skills diff <repo>`, or `git -C <cache-path> reset --hard origin/<branch>`. Part of the **Cache Edit Guardrails** system (see Planned Features).
- [ ] Detect when a registered local source clone exists (`ai-skills link`) but symlinks still point at the cache, and offer to relink. Part of the **Cache Edit Guardrails** system.
- [x] Show a summary section "How to fix" at the end with copy-pasteable commands

## Nice to Have

- [ ] Shell completions (bash, zsh, fish)
- [ ] `ai-skills search` — search for skill repositories. Primary backend should be public skill registries (e.g. [skills.sh](https://skills.sh/), [agentskill.sh](https://agentskill.sh/)) instead of raw GitHub search, so results come with install counts, agent compatibility, and (where available) quality/security metadata. GitHub fallback for repos not indexed anywhere.
- [ ] Registry-aware install sources — accept registry-style identifiers in `ai-skills add` (e.g. `ai-skills add skills.sh:owner/repo` or `--registry agentskill.sh`) so users can install from curated indexes without knowing the underlying GitHub URL. Resolve to a `owner/repo` (+ optional ref) and fall back to the existing GitHub clone path. Only worth doing once at least one registry exposes a stable resolution API.
- [ ] Surface registry trust signals in `add` and `doctor` — when a skill is known to a registry that publishes a security/quality score (e.g. agentskill.sh audit), show it before install and flag installed skills whose score regressed. Ties into `docs/source-policy.md`.
- [ ] Manifest lock file for reproducible installs across machines
- [ ] `ai-skills init` — scaffold a new skill repository
