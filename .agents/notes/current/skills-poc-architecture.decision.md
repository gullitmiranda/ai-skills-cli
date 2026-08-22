# Skills POC Architecture

This note records the current direction for the `skills` proof of concept. It is working knowledge, not a replacement for an accepted ADR.

## Current decisions

- A Skills Workspace is any directory rooted at `skills.yaml`; it does not need to be a Git repository.
- A workspace contains vendored skill directories alongside its manifest. A parent repository may use a `skills/` directory as that workspace root.
- `skills/` is a source and bundle layout. Agent-specific directories such as `.agents/skills` and `.<agent>/skills` are installation targets, not the canonical vendor layout.
- The bundle keeps vendored files versioned and publishable. Installation creates links from agent targets to the bundle's vendor by default.
- A local development override changes only an installation link. It never rewrites the bundle vendor or its tracked files.
- The Skills Home is the CLI-managed data root. Its normal default is `SKILLS_HOME=$HOME/.skills`.
- POC integration tests set the process `HOME` to `SKILLS_SANDBOX_HOME` and set `SKILLS_HOME=$SKILLS_SANDBOX_HOME/.skills`. That sandbox home contains isolated `.skills`, `.agents`, and agent-specific target directories.
- The `name` in `SKILL.md` frontmatter is the public composition key. A source-relative path is provenance, not a global identity.
- A workspace exposes at most one selected skill for a given `name`. Distinct candidates with the same `name` are conflicts that consumers resolve explicitly through `include` and `exclude`.
- The POC does not introduce a lockfile or resolved-revision tracking. Those are later improvements for deterministic restore and safe updates.
- A missing local link target fails clearly in the POC. Managed cloning for local links is deferred.
- Publishing changes back to a source remains a Git workflow assisted by a core skill; the CLI does not automate commits or pull requests.

## Evaluation scope

The POC must validate the same vendor and local-link semantics through three possible implementations:

1. A refactored local CLI.
2. A wrapper that delegates suitable work to the pinned `npx skills` CLI.
3. A fork of `npx skills` if its architecture is the most maintainable place for generic workspace, vendor, and materialization capabilities.

The POC must never write to real agent directories. Setting `SKILLS_HOME` alone is insufficient because an upstream backend may resolve targets from `HOME`; every integration run uses the sandbox home.

## Deferred decisions

- The serialized local override schema and its scope.
- Source revision tracking, lockfiles, and update/merge semantics.
- Managed cloning when a local link target is absent.
- Final agent target mappings and precedence behavior.
- Whether the long-term implementation is a wrapper, a refactored CLI, or an upstream-oriented fork.
- Whether this direction supersedes any part of the accepted dependency-manifest ADR.

## Related records

- `docs/adr/0001-consumer-owned-skill-dependencies.md`
- `docs/adr/0002-keep-legacy-backend-default.md`
- `.agents/notes/current/skill-name-collisions.research.md`
