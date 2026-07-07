---
name: land
description: Pushes local commits to the tracked branch via the git-land tool, which wraps them in a disposable, auto-merged PR. Use when asked to land, ship, or merge local commits without a manual PR.
---

When instructed to land, ship, or merge commits, run `git land` from the current repo. Do NOT write code, open a PR by hand, or call `gh pr create`/`gh pr merge` yourself — `git land` already does all of that. If `git-land` isn't installed on this machine, a hook will block the command and tell you so — don't fall back to manually replicating its behavior with raw `gh`/git commands in that case; just report it to the user.

Usage: `git land ["title"] [--force]`

- Title is optional; if omitted, it defaults to the last commit's subject.
- Pass the title in quotes only if the user gave one or a clear one-line summary is obvious from context; otherwise omit it.
- The tool refuses to run if the current branch is behind its upstream, or if there's nothing to land — surface that message to the user rather than trying to work around it (e.g. don't rebase/pull on their behalf unless asked).
- The tool also refuses if the remote repo isn't owned by the authenticated GitHub user, requiring `--force` to override. Only add `--force` if the user explicitly confirms this is still solo/unreviewed work they want auto-merged on someone else's repo — never add it preemptively to make a refusal go away.
- The tool never touches uncommitted/staged changes; it only lands what's already committed.

What it does under the hood (for context, not to be replicated manually): pushes the commits ahead of upstream to a disposable `tmp/...` branch, opens a PR, posts a comment on it noting it was auto-created and merged without review for recordkeeping, then rebase-merges it (no squash) and deletes the temp branch. If immediate merge is blocked by required checks/review, it falls back to enabling auto-merge instead of hanging.
