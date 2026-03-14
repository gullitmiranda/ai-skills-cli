# Auth Profiles

GitHub authentication profile routing based on repository path.

## Convention

Repositories follow this directory structure:

```
~/Code/<namespace>/<scope>/<repo>
```

The `<namespace>` segment determines which GitHub profile (and credentials) the agent and CLI should use.

## Namespace-to-Profile Mapping

| Namespace | GitHub Profile | Use Case |
|-----------|---------------|----------|
| `<personal>` | `gullitmiranda` | Personal projects, side work, open source owned by you |
| `oss` | `gullitmiranda` | Open-source contributions to third-party projects |
| `<work>` | work gh profile | Employer/org repositories |

`<personal>` and `<work>` are placeholders. The concrete directory names are defined in local or scope-owned skills (e.g., the `gh-profile` skill in `gullit-skills`). This keeps real namespace names out of shared documentation.

## How It Works

The `gh-profile` skill (shipped via `gullit-skills`) inspects the current working directory, matches the namespace segment, and configures `gh` to use the appropriate auth token. This happens transparently when agents invoke `gh` commands.

Profile switching affects:

- `gh` CLI authentication (API calls, PR creation, issue management)
- Git push/pull credentials when using HTTPS
- Agent tools that shell out to `gh`

## Other Environment Variables

For non-GitHub env vars in work repos (API keys, service tokens, internal tool config), continue using:

```bash
eval "$(mise env)"
```

This loads `.mise.toml` or `.tool-versions` scoped to each repo. Auth profiles handle only the GitHub credential layer.

## Reference

The `gh-profile` skill implementation lives in the `gullit-skills` repository. Install it with:

```bash
ai-skills add gullitmiranda/gullit-skills
```

After installation, profile routing is automatic based on `pwd`.
