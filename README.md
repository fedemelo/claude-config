# claude-config

Global Claude Code configuration: instructions, a commit-discipline hook, and the skill it enforces.

## Install

```sh
git clone <this-repo-url>
cd claude-config
./install.sh
```

This symlinks `CLAUDE.md`, `hooks/enforce-commit-skill.py`, and `skills/commit` into `~/.claude/`,
then merges the `PreToolUse` hook entry into `~/.claude/settings.json` (creating it if it doesn't
exist yet, or adding just the hook entry without touching any other settings already there).

## What's in here

- **`CLAUDE.md`** — global instructions applied to every project: commit discipline
  (must invoke the `commit` skill before committing), self-documenting code, single
  responsibility, DRY.
- **`hooks/enforce-commit-skill.py`** — a `PreToolUse` hook that blocks any `git commit`
  until the `commit` skill has actually been invoked in the current session's transcript.
- **`skills/commit/SKILL.md`** — the actual commit/PR conventions the hook enforces: modular
  commits, terse single-line messages, no AI attribution anywhere (commits or PRs).

These three pieces only work as a set — the hook enforces the skill, `CLAUDE.md` tells Claude
the skill exists and when to use it.
