# Consumer-owned skill dependencies

Status: accepted

`ai-skills.yaml` will be a consumer-owned installation manifest. Its first dependency model deliberately stays small: each dependency declares a source accepted by the supported `npx skills` version and an optional selection of discovered skills. This keeps the manifest close to the CLI input while allowing `ai-skills` to add deterministic exclusions and local source overrides.

## Decision

A dependency has this initial shape:

```yaml
version: 1

dependencies:
  - source: <source specifier accepted by npx skills>
    include: # optional; exact skill names or "*"
      - <skill-name>
    exclude: # optional; exact skill names or "*"
      - <skill-name>
```

- `source` is an opaque source specifier, not a structured `source`/`ref`/`path` object. It may be a GitHub shorthand or URL, a GitHub tree URL scoped to a repository subpath, a Git URL, a local path, a skills.sh pack, or a supported direct download. The supported grammar is that of the pinned compatible `npx skills` release. The shell backend may reject unsupported source kinds with an actionable error until it reaches this parity.
- The manifest has no `key`, package identity, export declaration, or user-maintained locator. The resolver may normalize the source internally for state, diagnostics, lockfiles, deduplication, and override matching.
- `include` and `exclude` apply only to the `name` field in `SKILL.md` frontmatter. Matching is case-insensitive. Initially, a pattern is either an exact name or `"*"`; partial name globs and path globs are not supported.
- Candidates are discovered within the source scope, included, then excluded. Omitted `include` means all candidates. `exclude` wins over `include`; an unmatched include or an empty final selection is an error. An unmatched exclude may warn without failing.
- The CLI continues to use `--skill` for inclusion and adds repeatable `--exclude` for exclusion. `!name` is not used because it is ambiguous and inconvenient in shells and YAML.
- `npx skills` has no exclusion flag. `ai-skills` resolves exclusions to exact skill names, then delegates materialization to `npx skills` with repeated `--skill` arguments.
- Local overrides remain outside the shared manifest. They match the originally declared source and can replace the effective source, `include`, or `exclude`; replacement lists replace rather than merge. The precise serialization of the override file is intentionally deferred.

The direct GitHub `tree/<ref>/<path>` form is provider-specific, not a universal Git locator. The manifest does not promise generic remote-subpath support until the selected backend supports it.

## Consequences

This decision intentionally defers targets, project versus global installation, copy versus symlink behavior, auth profiles, lockfile schema, package/export metadata, path globs, and transitive manifest imports. They must not expand the initial source-selection contract without a separate decision.

The upstream source-input and `--skill` behavior is documented in the [Vercel Skills CLI source-format reference](https://github.com/vercel-labs/skills#source-formats).
