# Duplicate Skill Names in Claude Code and Zed

**Scope:** researched 2026-08-21 using only first-party documentation and the public Zed source repository. In Claude Code, "global" below means the **personal** `~/.claude/skills/` scope.

## Short answer

| Agent       | Documented global/project conflict                                 | What identifies an ordinary skill                                                                                          |
| ----------- | ------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------- |
| Claude Code | Enterprise overrides personal; personal overrides project.         | For personal and project skills, the directory name creates the slash command. Frontmatter `name` is only a display label. |
| Zed         | A project-local skill overrides a global skill with the same name. | The parsed frontmatter `name` is the identity used for conflict resolution.                                                |

## Claude Code

### Documented behavior in Claude Code

The official Skills documentation says: **"Across levels, enterprise overrides personal, and personal overrides project."** Thus a `deploy` skill in both `~/.claude/skills/deploy/` and `.claude/skills/deploy/` runs the personal version for `/deploy`.

However, for ordinary personal and project skills, this is a collision of the **directory-derived command name**, not merely of YAML metadata. The same page states: **"In a personal or project skill, `name` sets only the display label shown in skill listings, and the command still comes from the directory name."**

Therefore, two ordinary skills such as these do not have a documented command collision solely because their frontmatter matches:

```text
~/.claude/skills/global-review/SKILL.md   # name: review
.claude/skills/project-review/SKILL.md    # name: review
```

Their commands are `/global-review` and `/project-review`. The documentation does not specify how duplicate display labels are rendered, so do not rely on them being visually distinguished.

Other documented cases:

- A project or personal skill also overrides a bundled skill with the same command name.
- A nested project skill with a colliding directory name remains available under a directory-qualified command such as `/apps/web:deploy`; unqualified `/deploy` runs the root-level skill.
- Plugin skills are namespaced as `/plugin-name:skill-name`, so they do not conflict with project, personal, or enterprise skills. In plugins, frontmatter `name` can set the final command segment.

### Uncertainty

Anthropic documents the precedence and command-name rules, but this note found no public Claude Code runtime source to justify additional claims about internal deduplication or duplicate display labels. In particular, same `name` values in different plugin skill directories are outside the documented project/global case.

## Zed

### Documented behavior in Zed

Zed loads global skills from `~/.agents/skills/` and project-local skills from `<worktree>/.agents/skills/`. Its documentation requires a `name` field and says the folder name **should** match it. It explicitly states: **"If a global and a project-local skill share the same name, the project-local skill takes precedence."**

### Source-code inference (current `main`, not a documented compatibility promise)

The implementation makes the term "same name" precise: parsing assigns `Skill.name` from the YAML `metadata.name`, then `apply_skill_overrides` keys a map by `skill.name`. The precedence is `ProjectLocal > Global > BuiltIn`. So unlike ordinary Claude Code skills, duplicate frontmatter `name` values are a real Zed collision even when their directory names differ.

For two skills from the same source with the same frontmatter name, current Zed source keeps the first encountered skill and logs a warning. Within one scanned skills root, Zed sorts skill-file paths before resolving conflicts; consequently, this is deterministic and the lexicographically earlier path wins. This is implementation behavior, not documented API:

```text
~/.agents/skills/alpha/SKILL.md  # name: review   -> selected
~/.agents/skills/beta/SKILL.md   # name: review   -> shadowed
```

The source also distinguishes the model-facing and manual-user paths:

- The model catalog and unqualified `/review` resolve to the highest-precedence skill, so project-local wins over global.
- The autocomplete UI retains colliding entries with source labels. Its generated qualified commands can explicitly select `/:review` for the global skill or `/<worktree>:review` for a project-local skill. This is source-derived behavior and is not currently promised by the public Skills documentation.

## Practical guidance

- **Claude Code:** keep directory names unique at a given intended command scope. Matching frontmatter `name` values alone are not a documented conflict for normal project/personal skills, but unique display names avoid ambiguity for people.
- **Zed:** treat frontmatter `name` as globally/project-locally collision-sensitive. Use a unique `name` unless you intentionally want the project-local override; keep it equal to the folder name as Zed recommends.

## Sources

### Claude Code documentation

- [Skills: locations, precedence, nested conflicts, and plugins](https://code.claude.com/docs/en/skills#where-skills-live)
- [Skills: frontmatter reference](https://code.claude.com/docs/en/skills#frontmatter-reference)
- [Skills: how a skill gets its command name](https://code.claude.com/docs/en/skills#how-a-skill-gets-its-command-name)

### Zed documentation

- [Skills: format, required `name`, and discovery locations](https://zed.dev/docs/ai/skills#skill-format)
- [Skills: documented global/project override behavior](https://zed.dev/docs/ai/skills#override-behavior)

### Zed source code

- [Frontmatter-to-`Skill.name` parsing](https://github.com/zed-industries/zed/blob/main/crates/agent_skills/agent_skills.rs#L190-L226)
- [Source precedence definition](https://github.com/zed-industries/zed/blob/main/crates/agent_skills/agent_skills.rs#L97-L124)
- [Deterministic path sorting before collision resolution](https://github.com/zed-industries/zed/blob/main/crates/agent_skills/agent_skills.rs#L544-L578)
- [Conflict collection and `Skill.name`-keyed resolution](https://github.com/zed-industries/zed/blob/main/crates/agent/src/agent.rs#L3662-L3752)
- [Regression tests for project-over-global and same-source first-wins behavior](https://github.com/zed-industries/zed/blob/main/crates/agent/src/agent.rs#L4099-L4129)
- [Manual qualified and unqualified slash-command resolution](https://github.com/zed-industries/zed/blob/main/crates/agent/src/agent.rs#L2798-L2907)
- [Zed's source-level rationale for override semantics](https://github.com/zed-industries/zed/blob/main/crates/agent_skills/README.md#override-semantics)
