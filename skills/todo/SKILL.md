---
name: todo
description: File a GitHub issue via the git-todo tool, auto-assigned to the user, for lightweight personal backlog tracking. Use whenever instructed to create a todo, issue, or track a bug/task on GitHub.
---

When instructed to create a todo, issue, or track a task/bug on GitHub, run `git todo` from the current repo. Do NOT call `gh issue create` directly — `git todo` wraps it with the right defaults. If `git-todo` isn't installed on this machine, a hook will block the command and tell you so — don't fall back to manually replicating its behavior with `gh issue create` in that case; just report it to the user.

Usage: `git todo "<title>" [-b|--body "<body>"]`

- Title is required; use the user's wording or a succinct summary of what they described.
- Body is optional — only include it if the user gave real detail worth preserving; don't pad a one-line todo with an invented description.
- The tool auto-assigns the issue to the authenticated user and prints the issue number along with a reminder to reference `Fixes #<N>` in a commit message.
- To actually close the issue later, put `Fixes #<N>` in the commit message of the change that resolves it, then land that commit via the [[land]] skill — GitHub auto-closes issues referenced this way once the commit reaches the default branch.
