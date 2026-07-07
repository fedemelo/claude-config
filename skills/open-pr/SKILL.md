---
name: open-pr
description: Put up a clean PR from a fresh branch cut off the latest default branch — fetch, branch, commit only valid code changes, push, and open a PR assigned to the user with a terse description. Use whenever instructed to open, put up, raise, or submit a PR for the current working changes.
---

Put up a clean PR for the changes that already exist in the working tree. Do NOT write, refactor, clean up, or make opportunistic code changes — commit and open the PR using the existing changes exactly as they are.

## Start from a fresh branch off the latest default branch

Determine the remote's default branch rather than assuming `master`:

```sh
git remote show origin | sed -n 's/.*HEAD branch: //p'
```

Then get fully up to date and cut a brand-new branch from the remote default (never from the current branch):

```sh
git fetch origin
git switch -c <branch-name> origin/<default-branch>
```

- Uncommitted working-tree changes carry over onto the new branch — that is intended.
- If the changes you're PR-ing are already committed on the current branch, cherry-pick or rebase them onto the new branch instead; do not lose them.
- Name the branch clearly and descriptively from the changes (e.g. `fix-token-refresh-race`).

## Commit only valid code changes

Inspect the changes with `git status` first. Commit following the [[commit]] skill — invoke it so its exact conventions load; do not hand-roll commits.

Do NOT commit:
- Any `.md` or `.plan` files used for design, planning, or notes
- Any secrets or environment files
- Any unrelated or accidental changes

Only commit code changes.

## Push and open the PR

Push the new branch and open a PR targeting the default branch, assigned to the user:

```sh
git push -u origin <branch-name>
gh pr create --base <default-branch> --assignee @me --title "<title>" --body "<description>"
```

## PR description

Write it like an experienced staff engineer leaving a short, practical note. Extremely succinct:
- Briefly say what changed.
- Mention important trade-offs, constraints, or decisions only if relevant.
- Human and concise.
- No headers, no markdown styling, no bold, no emojis, no sections, no bullets, no templates.

Never add AI attribution to the PR (title or body), per the [[commit]] skill.
