---
name: pr-target
description: "The rule for working out which pull request a task is about: the one named, or else the current branch's. Other skills reference it so they all resolve the target the same way, and never ask. Use when a task needs a pull request and none was named."
---

Work out which pull request the task is about. Resolve it yourself, and never ask the user which PR or branch they mean.

1. If a PR number or URL was given, act on exactly that PR.
2. If a branch name was given, act on that branch's PR. `gh pr view <branch>` accepts a branch as readily as a number or URL.
3. Otherwise act on the current branch's PR. `gh pr view` with no argument targets it, and `git branch --show-current` gives the branch name.
4. If the branch has no open PR, say so and stop, unless the skill that sent you here states that a branch without a PR is still a valid target.

The skills that reference this write `<pr>` for the given number or URL, or empty to target the current branch's PR, and `<n>` for the PR number, which comes from `gh pr view <pr> --json number --template '{{.number}}'`.
