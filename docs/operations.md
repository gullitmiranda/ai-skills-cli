# Operations

Day-2 operations for managing installed skills.

## Update Skills

Update all installed skills to their latest tracked ref:

```bash
ai-skills update
```

Update all installed skills from one GitHub repository:

```bash
ai-skills update owner/repo
```

Update a specific skill by source ID:

```bash
ai-skills update owner/repo/skills/my-skill
```

Core skills (installed via bootstrap) are skipped during update. Re-run `ai-skills bootstrap` to update those.

## Add a New Skill

Install from a GitHub URL or shorthand:

```bash
ai-skills add owner/repo
ai-skills install owner/repo
ai-skills add https://github.com/owner/repo/tree/main/skills/my-skill
ai-skills add owner/repo --path skills/specific --ref v1.0.0
```

Target a specific agent:

```bash
ai-skills add owner/repo --agent cursor
```

Preview without making changes:

```bash
ai-skills add owner/repo --dry-run
```

Use the upstream `npx skills` backend experimentally:

```bash
ai-skills --backend npx-skills add owner/repo --dry-run
AI_SKILLS_BACKEND=npx-skills ai-skills add owner/repo
```

## Sync Declarative Specs

Link a versioned spec to a profile:

```bash
ai-skills profile link personal ~/dotfiles/tools/ai-skills/profiles/personal.yaml
ai-skills profile sources
```

Then apply the default profile:

```bash
ai-skills sync --dry-run
ai-skills sync
```

`ai-skills sync` reads `~/.ai-skills/profiles/<profile>.yaml` for the selected
profile and additive fragments from `~/.ai-skills/profiles.d/<profile>/*.yaml`.
Use `--profile <name>`, `--all-profiles`, or `--from <file-or-dir>` for explicit
sync runs.

After a real `npx-skills` sync, the wrapper checks `npx skills list -g --json`
for named skills and warns when the upstream state does not show the requested
agent. This catches cases where `npx skills` materializes a skill in a shared
directory but reports a different agent association than the profile requested.

## Remove a Skill

Remove a skill from managed agent directories and the legacy manifest:

```bash
ai-skills remove owner/repo/skills/my-skill
```

With the experimental `npx-skills` backend, removal is delegated upstream:

```bash
ai-skills --backend npx-skills remove web-design-guidelines
```

## List Installed Skills

```bash
ai-skills list
```

Shows all installed skills with their ref, target agents, and last update timestamp.

## Health Check

```bash
ai-skills doctor
```

Doctor verifies:

- Required tools (`git`, `jq`) are installed
- `npx` is available when `--backend npx-skills` is selected
- `gh` authentication status
- State directory and manifest integrity
- Agent directories exist and contain expected skills
- Manifest entries match filesystem state
- Installed legacy manifest sources are represented in linked profile specs when `yq` is available

## Rollback

To roll back a skill to a previous version, re-add it with a pinned ref:

```bash
ai-skills add owner/repo --ref <previous-tag-or-sha>
```

This overwrites the current version with the specified ref. The manifest updates to reflect the pinned ref.

## Troubleshooting

### `Required command not found: jq`

Install missing dependencies:

```bash
brew install jq        # macOS
apt install jq         # Debian/Ubuntu
```

### `gh: not authenticated`

```bash
gh auth login
```

For work repos using a separate GitHub account, ensure the correct profile is active (see [auth-profiles.md](auth-profiles.md)).

### `State directory missing`

Run bootstrap to initialize:

```bash
ai-skills bootstrap
```

### `Manifest: invalid JSON`

The manifest at `~/.ai-skills/manifest.json` is corrupted. Back it up and re-bootstrap:

```bash
cp ~/.ai-skills/manifest.json ~/.ai-skills/manifest.json.bak
rm ~/.ai-skills/manifest.json
ai-skills bootstrap
```

Then re-add external skills. The backup can help recover source IDs.

### `Skill X -> agent: missing from filesystem`

The manifest references a skill that no longer exists on disk. Re-install it:

```bash
ai-skills update owner/repo/skills/X
```

Or remove the stale entry from `~/.ai-skills/manifest.json` manually.

### Private repo clone fails

Ensure `gh` is authenticated and has access to the repository:

```bash
gh auth status
gh repo view owner/repo
```
