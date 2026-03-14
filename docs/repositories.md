# Repositories

Each skill repository has a clear scope. Mixing concerns across repos leads to drift and conflicts.

## ai-skills-cli

**Owner:** `gullitmiranda/ai-skills-cli`

CLI tooling, core skills, scripts, and documentation. This is the package manager itself.

**Contains:**

- `bin/ai-skills` -- main CLI entry point
- `skills/core/` -- base skills shipped with every install (bootstrap)
- `scripts/` -- helper scripts
- `docs/` -- this documentation
- `state/` -- local manifest and metadata (gitignored)

**Does NOT contain:** domain-specific skills, work-specific configuration, or personal preferences. Those belong in external skill repos.

## gullit-skills

**Owner:** `gullitmiranda/gullit-skills`

Personal common skills reusable across all projects and machines. Not tied to any employer or team.

**Scope:**

- Editor/workflow preferences
- Git conventions and helpers
- Shell productivity skills
- Auth profile routing (gh-profile)
- Personal quality standards

**Does NOT contain:** work-specific secrets, team conventions, or employer-scoped tooling.

## Work skills (example)

Work-scoped skill repositories contain configurations and workflows specific to the work environment. They are owned by the work GitHub account and cloned under `~/Code/<work>/`.

**Scope:**

- Work-specific tool integrations
- Team conventions and standards
- Internal service helpers
- Environment-specific configuration

**Does NOT contain:** personal preferences, personal auth tokens, or content that should exist in personal repos.

## Team skills (example: platform-skills)

**Owner:** `<org>/platform-skills`

Platform team skills with two namespaces controlling access:

| Namespace | Audience | Content |
|-----------|----------|---------|
| `platform/common` | All teams consuming platform services | Shared tools, deploy helpers, observability |
| `platform/internal` | Platform team only | Internal ops, runbooks, team-specific workflows |

Non-platform consumers install only `common` by default. Platform team members get both. See [source-policy.md](source-policy.md) for namespace override syntax.

## Adding a New Skill Repository

1. Create a GitHub repo with skills in one of the standard layouts:

   ```
   skills/<skill-name>/SKILL.md    # common layout
   .cursor/skills/<name>/SKILL.md  # agent-specific layout
   .claude/skills/<name>/SKILL.md  # agent-specific layout
   ```

2. Register it with the CLI:

   ```bash
   ai-skills add owner/new-repo
   ```

3. The CLI discovers skills automatically based on directory structure. No registration file required inside the repo.

4. For multi-namespace repos, use `--path` to target a specific subtree:

   ```bash
   ai-skills add owner/new-repo --path skills/specific-namespace
   ```
