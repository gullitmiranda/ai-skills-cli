# Keep the legacy installer as the default backend

Status: accepted

Date: 2026-05-29

`ai-skills` gained an opt-in `npx-skills` backend that delegates generic
install/update/list/remove work to the upstream [`npx skills`](https://github.com/vercel-labs/skills)
CLI. That backend remains experimental. The default installer stays `legacy`.

## Context

[`vercel-labs/skills`](https://github.com/vercel-labs/skills) now advertises
symlink support. That raised the question of whether a custom CLI is still
worth keeping, versus becoming a thin wrapper, versus switching the default
installer to `npx skills`.

The local CLI still owns capabilities the upstream CLI does not replace:

- GitHub credential routing via profiles
- private and local skill sources
- bootstrap of core skills
- diagnostics (`doctor`)
- declarative, versionable desired state per profile (`ai-skills sync`)

The wrapper strategy is still useful: keep those local policies, and optionally
delegate generic package-management calls to `npx skills`. Changing the
**default** backend is a separate decision.

## Decision

1. Default backend remains `legacy` (`AI_SKILLS_BACKEND` unset, or
   `--backend legacy`).
2. `npx-skills` is opt-in only:
   `AI_SKILLS_BACKEND=npx-skills` or `--backend npx-skills`.
3. Versioned profile specs used for restore should declare `backend: legacy`
   until the upstream Cursor/symlink/agent-mapping issues are fixed without a
   local workaround.
4. Do not make `npx-skills` the default just because symlink support exists in
   upstream docs or in a newer package version that has not been validated.

## Why `npx-skills` is not the default

Validated against `skills@1.5.7` (the newest `skills@1.5.9` was blocked by the
local npm release-age guard at the time).

### Cursor global install lands in the wrong place

`npx skills add ... --agent cursor -g` materialized the skill under
`~/.agents/skills/<name>` instead of `~/.cursor/skills/<name>`. Cursor does not
treat `~/.agents/skills` as its global skills directory.

Tracked upstream:

- [Issue #421](https://github.com/vercel-labs/skills/issues/421)
- [Issue #537](https://github.com/vercel-labs/skills/issues/537)
- [Issue #745](https://github.com/vercel-labs/skills/issues/745)

Related PRs that were not landed at the time of this decision:

- [Pull request #694](https://github.com/vercel-labs/skills/pull/694)
- [Pull request #799](https://github.com/vercel-labs/skills/pull/799)

### Symlink mode is not reliable for that path

Even with advertised symlink support, the Cursor global install was a **copy**
in `~/.agents/skills`, not a symlink into `~/.cursor/skills`. The custom CLI
installs managed clones under `~/.ai-skills/repos/<profile>/...` and links
agent dirs at those clones. Losing that model breaks edit/update continuity.

### Upstream `list` mis-attributes the shared directory

After a Cursor-requested global install, `npx skills list -g --json` associated
the skill with Warp (and only reported Cursor after a local symlink workaround).
A profile that asks for Cursor cannot trust upstream inventory as the source of
truth.

### The two backends do not share the same selection model

`npx skills` treats `--skill <name>` as a logical filter over a catalog/source.

The `legacy` backend clones a repo and discovers `SKILL.md` directories
(agent-specific dirs, `.agents/skills`, `skills/`, or a root `SKILL.md`). A
declarative profile entry uses `skills: [web-design-guidelines]` as a **name
filter after discovery**, not as a hardcoded `skills/<name>` path. Making
`npx-skills` the default would change restore semantics before that contract is
stable.

## Local workaround (temporary, npx-skills only)

When the `npx-skills` backend installs named skills globally for Cursor, the
wrapper may create:

```text
~/.cursor/skills/<skill> -> ~/.agents/skills/<skill>
```

This is isolated in `npx_skills_apply_cursor_global_workaround` in
`bin/ai-skills`. It is marked `TODO`/`FIXME` with the upstream issue/PR links
above. After a real install, `npx_skills_verify_install` runs
`npx skills list -g --json` and warns if the requested agent is missing from
the listed association.

Do not treat this workaround as a reason to switch the default. Remove it when
upstream reliably links Cursor global installs into `~/.cursor/skills` and
defaults to symlink mode.

## Declarative restore (independent of the default backend)

Desired state is a YAML spec per profile, versioned outside `~/.ai-skills`
(typically in dotfiles) and linked by the CLI:

```bash
ai-skills profile link personal <path-to>/profiles/personal.yaml
ai-skills sync --dry-run
ai-skills sync
```

Canonical local layout:

```text
~/.ai-skills/
  config.json
  manifest.json          # operational state for the legacy backend
  profiles/
    personal.yaml        # often a symlink into a versioned repo
  profiles.d/
    personal/            # optional additive fragments
```

Example spec (legacy default):

```yaml
version: 1
profile: personal
defaults:
  backend: legacy
  scope: global
  agents:
    - cursor
skills:
  - source: vercel-labs/agent-skills
    ref: main
    skills:
      - web-design-guidelines
```

`skills:` is the public schema. The legacy backend discovers `SKILL.md`
directories and filters by basename. Do not encode layout-specific `path:` in
the profile for this.

`AI_SKILLS_NPX_PACKAGE` pins the npm package the experimental backend executes
(for example `skills@1.5.7`).

## What was verified with the legacy path

A real `ai-skills sync` against the example spec:

- installed `web-design-guidelines` for Cursor as a symlink
- pointed `~/.cursor/skills/web-design-guidelines` at the managed clone under
  `~/.ai-skills/repos/<profile>/vercel-labs/agent-skills/...`
- wrote a `manifest.json` entry with `profile` serialized as JSON
  (`"personal"`, not a bare identifier)

A first real sync hit a `jq` bug in `update_manifest_skill`: `jq -rn` printed a
raw string, so the filter treated `personal` as an identifier. The fix is
`jq -n` so the profile value is valid JSON.

## When to revisit making `npx-skills` the default

All of the following should be true without a local Cursor symlink workaround:

- Global `--agent cursor` installs into `~/.cursor/skills`
- Installs are symlinks (or an explicit, reliable symlink mode)
- `npx skills list -g --json` reports the requested agent
- A pinned `npx skills` version older than the local release-age window has
  been validated
- Declarative `sync` with `backend: npx-skills` restores named skills
  idempotently for the agents in the spec

Until then, keep `legacy` as default and `npx-skills` experimental.

## Open follow-ups at the time of this decision

- Commit any remaining `update_manifest_skill` JSON serialization fix if it is
  still uncommitted
- Expand the versioned personal profile with third-party skills that should
  survive a machine restore
- Add a dotfiles bootstrap step that runs `profile link` then `sync --dry-run`
- Re-check the upstream issues/PRs listed above before changing the default
