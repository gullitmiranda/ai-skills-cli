# Source Policy

Trusted source policy for `ai-skills`. Defines how skills are discovered, installed, versioned, and resolved.

## No Global Catalog

Sources are provided explicitly per install command. There is no `sources.yaml` or central registry required.

A skill is installed by pointing directly at a GitHub repository or subpath. The CLI fetches it on demand -- no subscription, no sync, no background polling.

## Source Input Formats

`ai-skills add` accepts direct GitHub URLs or shorthand notation:

| Format | Example |
|--------|---------|
| Repository URL | `https://github.com/owner/repo` |
| Subpath URL | `https://github.com/owner/repo/tree/main/skills/my-skill` |
| Shorthand | `owner/repo` |
| Shorthand + path | `owner/repo/skills/my-skill` |

All formats resolve to a GitHub repository + optional directory path.

## Installed Sources in Local State

Every installed skill is recorded in `~/.ai-skills/manifest.json`. The manifest tracks:

- Source repository and path
- Installed ref (branch, tag, or commit SHA)
- Update policy
- Install timestamp

This enables reproducibility (`ai-skills restore`) and update tracking (`ai-skills update`).

## Version Pinning

Pin a specific version with `--ref`:

```bash
ai-skills add owner/repo --ref v2.1.0      # tag
ai-skills add owner/repo --ref main         # branch
ai-skills add owner/repo --ref abc1234      # commit SHA
```

Default: the repository's default branch.

## Update Policy

Each installed skill has an update policy:

| Policy | Behavior |
|--------|----------|
| `manual` (default) | Updates only when explicitly requested via `ai-skills update` |
| `tracked branch` | Follows a branch (e.g. `main`) on update |
| `pinned` | Locked to a specific ref; update only changes the ref explicitly |

Set at install time:

```bash
ai-skills add owner/repo                          # manual (default)
ai-skills add owner/repo --ref main --track       # tracked branch
ai-skills add owner/repo --ref v1.0.0 --pin       # pinned
```

## Conflict Resolution

When two sources provide a skill with the same id:

1. **Last installed wins** by default.
2. `ai-skills doctor` warns about id conflicts across sources.
3. User resolves by removing one source with `ai-skills remove`.

No implicit merging or priority ordering is applied.

## Allowlist (Optional)

Organizations can maintain an allowlist of trusted GitHub sources. Stored in `~/.ai-skills/allowlist.json`:

```json
{
  "allowed_orgs": ["my-org", "another-org"],
  "allowed_repos": ["external-user/vetted-skills"]
}
```

- Not enforced by default.
- Enable enforcement with `ai-skills config set allowlist.enforce true`.
- When enforced, `ai-skills add` rejects sources not in the allowlist.

## Namespace Defaults for platform-skills

`platform-skills` uses namespace-aware defaults to control what gets installed:

| Consumer | Default namespaces |
|----------|--------------------|
| Non-platform teams | `platform/common` |
| Platform team | `platform/common` + `platform/internal` |

Override defaults:

```bash
ai-skills add owner/platform-skills --path platform/internal   # specific namespace
ai-skills add owner/platform-skills --enforce common,internal  # explicit set
```
