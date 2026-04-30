---
name: ai-skills-cache-safety
description: >-
  Refuse git writes (add/commit/push) inside the ai-skills CLI cache
  (~/.ai-skills/repos/) and redirect to the source clone or
  `ai-skills publish`. ALWAYS use BEFORE any `git add`, `git commit`,
  `git push`, or any other git write op when working in a directory
  that could be — or could resolve via symlink to — a path under
  ~/.ai-skills/repos/. Skill files are commonly accessed via symlinks
  in ~/.cursor/skills/, ~/.claude/skills/, ~/.codex/skills/,
  ~/.agents/skills/ that resolve into the cache.
---

# ai-skills Cache Safety

The ai-skills CLI installs skills as **symlinks** from agent directories
(`~/.cursor/skills/<name>`, `~/.claude/skills/<name>`,
`~/.codex/skills/<name>`, `~/.agents/skills/<name>`) into a managed clone
under `~/.ai-skills/repos/<profile>/<owner>/<repo>/`. That managed clone is
**the cache**. It is owned by the CLI and may be reset, re-cloned, or
moved by `ai-skills update` / `ai-skills doctor` at any time.

The cache is **not** a working repo. Writes inside it cause two distinct
problems for agents:

1. **Lost work.** Local commits/edits in the cache are silently
   overwritten by the next `ai-skills update` or repair.
2. **Unintended upstream mutations.** The cache has a real `origin`
   pointing at the source repo. A `git push` from inside the cache pushes
   to the same upstream the user pushes from their working clone — but
   from history that the user never authored.

This skill exists to make those two failure modes impossible by reflex.

## Hard rule

**Before any `git add`, `git commit`, `git push`, `git rebase`,
`git reset`, `git merge`, or any other op that mutates a repo or its
remote, run the cache check below. If the check trips, STOP — do not
attempt the write, and follow the redirect procedure.**

The rule applies whether the agent navigated to the path explicitly
(`cd ~/.ai-skills/repos/...`) or implicitly via a skill symlink (e.g.
opening `~/.claude/skills/git/SKILL.md` for editing).

## Cache check

For the file or directory you are about to mutate:

1. Resolve the real path:

   ```bash
   # for a directory (cwd):
   real="$(pwd -P)"

   # for a file:
   real="$(readlink -f <path>)"
   ```

2. Trip the rule if **any** of these are true:
   - `$real` starts with `$HOME/.ai-skills/repos/` (or `$AI_SKILLS_HOME/repos/` if `AI_SKILLS_HOME` is set).
   - The git repo root containing `$real` has a `.ai-skills-cache` marker file:

     ```bash
     toplevel="$(git -C "$real" rev-parse --show-toplevel 2>/dev/null)"
     [[ -n "$toplevel" && -f "$toplevel/.ai-skills-cache" ]]
     ```

The marker file is added by future versions of the CLI on clone (see the
Cache Edit Guardrails entry in `ROADMAP.md`); the path-prefix check works
today even before the marker exists.

## Redirect procedure (when the check trips)

Stop the in-flight write and pick one of these, in order of preference:

### 1. Edit in the source clone

If the user has a local clone of the same repo elsewhere, switch the edit
to that clone and use it as the working repo. To find a candidate clone:

```bash
# What is the cache repo's upstream?
upstream="$(git -C "$real" config --get remote.origin.url)"

# Look for any other local clone with the same upstream
# (search common locations; do not exhaust the filesystem).
for base in "$HOME/code" "$HOME/Code" "$HOME/src" "$HOME/projects"; do
  [[ -d "$base" ]] || continue
  while IFS= read -r -d '' candidate; do
    other="$(git -C "$candidate" config --get remote.origin.url 2>/dev/null || true)"
    if [[ "$other" == "$upstream" && "$candidate" != *"/.ai-skills/repos/"* ]]; then
      echo "candidate source clone: $candidate"
    fi
  done < <(find "$base" -maxdepth 4 -type d -name .git -print0 2>/dev/null)
done
```

Keep the search shallow (`-maxdepth 4`) and skip noisy directories
(`node_modules`, `.cache`, etc.) when needed. If exactly one candidate
appears, prefer it and ask the user to confirm. If none appears, do not
guess — fall through to step 2 or 3.

After the user confirms a source clone:

1. Apply the edits there.
2. Commit + push from the source clone (subject to the user's regular
   git/safety rules).
3. Run `ai-skills update <owner>/<repo>` (or just `ai-skills update`) so
   the cache fast-forwards and the agent-visible symlinks see the new
   content.

### 2. `ai-skills publish` (when implemented)

When the user has no source clone and the change must originate from the
cache, the supported escape hatch is `ai-skills publish <repo>` (planned
in `ROADMAP.md` under Cache Edit Guardrails). It detects local commits
ahead of upstream and turns them into a normal upstream push or PR.

If `ai-skills publish` is not yet available in the installed CLI, do not
silently `git push` from the cache as a substitute. Tell the user the
command is not implemented yet and ask them how to proceed.

### 3. Bypass (only when the user explicitly asks)

If the user explicitly asks to commit in the cache anyway (e.g. for a
short-lived experiment they will discard), the agent may proceed only
when the user has stated this in the current conversation. Always:

- Show the cache path (`pwd -P`) to confirm the intent.
- Warn that `ai-skills update` may discard the work.
- Never push from the cache without a second explicit confirmation.

## Quick checklist (run before every git write)

- [ ] Resolved the real path (`pwd -P` / `readlink -f`).
- [ ] Path is **not** under `~/.ai-skills/repos/`.
- [ ] No `.ai-skills-cache` marker at the repo root.
- [ ] If either trips: stopped, ran the redirect procedure, asked the user.

## When this skill does NOT apply

- Read-only operations (`git status`, `git log`, `git diff`, viewing a
  file). Reading the cache to inspect installed skill content is fine.
- Operations the CLI itself performs (`ai-skills update` mutates the
  cache by design).
- Repos outside `~/.ai-skills/repos/` that have no `.ai-skills-cache`
  marker. The user's normal source clones are unaffected by this skill.
