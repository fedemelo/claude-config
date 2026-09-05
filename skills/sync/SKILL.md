---
name: sync
description: Brings a branch, or the whole stack it sits in, up to date with its base branch by rebasing and resolving conflicts so both sides keep working. Stops and asks whenever a conflict needs a real decision, or whenever a branch it would have to force-push already has reviewers. Use when asked to sync, rebase, or bring a branch or PR up to date with master.
disable-model-invocation: true
---

The branch is behind its base branch and may conflict with it. Bring it up to date.

## Which branch

Resolve it with [[pr-target]]. Here a branch with no PR is still a valid target: sync it, and mention it has no PR.

## What to run

Resolve the base instead of assuming `master` or `main`: it is `gh pr view <pr> --json baseRefName`, or `git symbolic-ref refs/remotes/origin/HEAD --short` for a branch with no PR. Then `git fetch origin`, rebase onto `origin/<base>`, and push with `--force-with-lease`, never a plain `--force`.

Rebase rather than merging the base in, so the branch keeps showing only its own diff.

## Resolving conflicts

A conflict means the base changed something this branch also touched. Both sides shipped for a reason, so the resolution keeps the base's new behavior and this branch's change working together. Never take one side wholesale unless that truly is the answer, and never drop the base's work to make the rebase pass.

Then prove it. Read the resolved code in context, not just the conflict hunks, and run whatever the repo runs: tests, lint, build. `git rebase --continue` carries the original commit message, so leave it alone.

## Stop and ask

Fail loudly rather than deciding for the user. Run `git rebase --abort` so the branch is left exactly as it was, say what you found, and wait when:

1. A conflict cannot be resolved with both sides intact.
2. Resolving it takes a design decision or a real trade-off, however small it looks. Name the options and which one you would pick.
3. The repo is not in a state to sync: no clear base, a dirty working tree, or local commits unrelated to this branch's work. Never stash or discard anything to get going.

## Stacked PRs

Treat the stack as one unit, because keeping its diff clean is the whole point. Moving the bottom branch onto the base means every branch above it has to be rebased onto its new parent and force-pushed, from the bottom up. That is the default, not something to ask about.

Read the stack off the PRs' base branches: a PR based on another branch of the stack, rather than on the default branch, sits above that branch. Whichever branch of the stack you were pointed at, start from the bottom one.

One exception, and check it before touching anything: if the PR of any branch that would be rebased and force-pushed already has reviewers, do none of it. A force-push throws away what they were reading. Stop, name those branches, and let the user decide.

```sh
gh pr view <n> --json reviewRequests,reviews
```

Reviewers who already reviewed count as much as ones still requested.
