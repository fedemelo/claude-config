# claude-config

Global Claude Code configuration: instructions, hooks, and the skills they enforce.

## Install

```sh
git clone <this-repo-url>
cd claude-config
./install.sh
```

This symlinks `CLAUDE.md`, the `hooks/`, and the `skills/` into `~/.claude/`, so editing the
installed path edits the repo file directly and they can't drift out of sync, then merges the
`PreToolUse` hook entries into `~/.claude/settings.json` (creating it if it doesn't exist yet, or
adding just the missing hook entries without touching any other settings already there, since
that file also holds machine-local preferences like model/theme that shouldn't be forced identical).

## Prerequisite: git-tools

The `land` / `todo` skills need the `git-land` / `git-todo` executables from [git-tools](https://github.com/fedemelo/git-tools) — install that repo too, or those two skills stay inert.

## What's in here

- **`CLAUDE.md`** — global instructions applied to every project: commit discipline
  (must invoke the `commit` skill before committing), self-documenting code, single
  responsibility, DRY.
- **`hooks/enforce-commit-skill.py`** — a `PreToolUse` hook that blocks any `git commit`
  until the `commit` skill has actually been invoked in the current session's transcript.
- **`hooks/require-git-land-todo-tools.py`** — a `PreToolUse` hook that blocks `git land` /
  `git todo` if the corresponding `git-land` / `git-todo` executable isn't installed on PATH,
  rather than letting Claude fall back to replicating their behavior by hand.
- **`skills/commit/SKILL.md`** — the actual commit/PR conventions the commit hook enforces:
  modular commits, terse single-line messages, no AI attribution anywhere (commits or PRs).
- **`skills/land/SKILL.md`** — instructs Claude to land/ship/merge commits via `git land`
  instead of hand-rolling a PR with `gh`.
- **`skills/todo/SKILL.md`** — instructs Claude to file GitHub issues via `git todo` instead
  of calling `gh issue create` directly.

Each hook pairs with the skill it enforces — the hook blocks the raw command, the skill (and
`CLAUDE.md`, which tells Claude the skills exist) points Claude at the right tool instead.
