---
name: land
description: Pushes local commits to the tracked branch with the git-land tool, which wraps them in a disposable, auto-merged PR. Use when asked to land, ship, or merge local commits without a manual PR.
---

When told to land, ship, or merge commits, run `git land` from the current repo. Do not write code, open a PR by hand, or call `gh pr create` or `gh pr merge` yourself, since `git land` already does all of that. If `git-land` is not installed, a hook blocks the command and says so; report that to the user instead of replicating the behavior with raw `gh` or `git` commands.

Usage: `git land ["title"] [--force]`

The title is optional and defaults to the last commit's subject. Pass it in quotes only when the user gave one, or when a clear one-line summary is obvious from context; otherwise omit it.

`git land` refuses to run in a few cases. It refuses when the branch is behind its upstream, or when there is nothing to land; surface that message rather than working around it, and do not rebase or pull on the user's behalf unless asked. It also refuses when the remote repo is not owned by the authenticated GitHub user, which `--force` overrides; add `--force` only when the user explicitly confirms this is solo, unreviewed work they want merged automatically on someone else's repo, never preemptively to clear a refusal.

`git land` never touches uncommitted or staged changes; it lands only what is already committed.

`git land` lands every commit currently ahead of upstream as a single PR. To split work across separate PRs, land in rounds: commit one group, run `git land`, then commit the next group and run `git land` again.

For context, and not to be replicated by hand: it pushes the commits ahead of upstream to a disposable `tmp/...` branch, opens a PR, comments that the PR was auto-created and merged without review for recordkeeping, rebase-merges it without squashing, and deletes the temp branch. If an immediate merge is blocked by required checks or review, it enables auto-merge instead of hanging.
