---
name: todo
description: Files a GitHub issue with the git-todo tool, auto-assigned to the user, for lightweight personal backlog tracking. Use when asked to create a todo or issue, or track a bug or task on GitHub.
---

When told to create a todo or issue, or to track a task or bug on GitHub, run `git todo` from the current repo. Do not call `gh issue create` directly, since `git todo` wraps it with the right defaults. If `git-todo` is not installed, a hook blocks the command and says so; report that to the user instead of replicating it with `gh issue create`.

Usage: `git todo "<title>" [-b|--body "<body>"]`

The title is required: use the user's wording or a succinct summary of what they described, written in English whatever the language of the surrounding project. The body is optional: include it only when the user gave real detail worth preserving, and do not pad a short todo with an invented description; write it in English too.

`git todo` auto-assigns the issue to the authenticated user and prints the issue number with a reminder to reference `Fixes #<N>` in a commit message. To close the issue later, put `Fixes #<N>` in the commit message of the change that resolves it and land that commit with the [[land]] skill; GitHub auto-closes issues referenced this way once the commit reaches the default branch.
