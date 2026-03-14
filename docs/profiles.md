# Profiles

Profiles route git credentials when cloning skill repositories. Each profile maps to a subdirectory under `~/.ai-skills/repos/`, allowing gitconfig `includeIf` rules to apply the correct identity and credentials per profile.

## Why Profiles Exist

Skill repositories may live on different GitHub accounts (personal, work, org). Without profiles, all clones land in the same directory and git uses a single credential context. Profiles solve this by separating repos into profile-scoped directories that gitconfig can match independently.

## How It Works

```
~/.ai-skills/
├── config.json                         # profiles configuration
├── manifest.json
└── repos/
    ├── personal/                       # profile: personal
    │   └── gullitmiranda/
    │       └── gullit-skills/
    └── work/                           # profile: work
        └── cloudwalk/
            └── tyrell-skills/
```

Git credentials are routed by `includeIf` matching the repos path:

```
~/.ai-skills/repos/personal/**  →  personal gitconfig (personal identity + credentials)
~/.ai-skills/repos/work/**      →  work gitconfig (work identity + credentials)
```

## CLI Commands

```bash
# List profiles
ai-skills profile list

# Add a profile
ai-skills profile add work
ai-skills profile add work --repos-dir ~/.ai-skills/repos/work

# Set default profile
ai-skills profile default personal

# Install using a specific profile
ai-skills add owner/repo --profile work

# Install using default profile
ai-skills add owner/repo
```

## Git Configuration

Profiles only work if your gitconfig routes credentials based on the repos directory path. Add `includeIf` blocks to your `~/.gitconfig` (or `~/.gitconfig.local`):

### Example: two profiles (personal + work)

```gitconfig
# Personal credentials for personal profile
[includeIf "gitdir:~/.ai-skills/repos/personal/"]
    path = ~/Code/.gitconfig

# Work credentials for work profile
[includeIf "gitdir:~/.ai-skills/repos/work/"]
    path = ~/Code/<work>/.gitconfig
```

Where each included gitconfig sets the appropriate identity and credential helper:

```gitconfig
# ~/Code/.gitconfig (personal)
[user]
    email = you@personal.com
    name = Your Name
    signingkey = ~/.ssh/signing_personal

[credential "https://github.com"]
    helper =
    helper = !/usr/bin/gh auth git-credential
```

```gitconfig
# ~/Code/<work>/.gitconfig (work)
[user]
    email = you@company.com
    name = Your Name
    signingkey = ~/.ssh/signing_work

[credential "https://github.com"]
    helper =
    helper = !GH_TOKEN="$(gh auth token --user work-user)" gh auth git-credential
```

### Using `gh auth` with multiple accounts

If you use `gh` as credential helper with multiple GitHub accounts, the work gitconfig can explicitly select the account:

```gitconfig
[credential "https://github.com"]
    helper =
    helper = !GH_TOKEN="$(gh auth token --user <work-github-user>)" gh auth git-credential
```

This ensures clones under `~/.ai-skills/repos/work/` always authenticate as the work account, regardless of which `gh` profile is currently active.

## Config File

Profiles are stored in `~/.ai-skills/config.json`:

```json
{
  "default_profile": "personal",
  "profiles": {
    "personal": {},
    "work": {
      "repos_dir": "~/.ai-skills/repos/work"
    }
  }
}
```

- `default_profile`: used when `--profile` is not specified
- `profiles.<name>.repos_dir`: override the repos directory for this profile (default: `~/.ai-skills/repos/<name>`)

## Typical Setup

1. Add profiles:

```bash
ai-skills profile add personal
ai-skills profile add work
ai-skills profile default personal
```

2. Configure gitconfig `includeIf` rules (see examples above).

3. Install skills with the appropriate profile:

```bash
ai-skills add my-user/my-skills                          # uses default (personal)
ai-skills add my-org/org-skills --profile work            # uses work credentials
```

4. Verify with `--debug`:

```bash
ai-skills add my-org/repo --profile work --debug
# Should show: repos dir = ~/.ai-skills/repos/work/my-org/repo
```
