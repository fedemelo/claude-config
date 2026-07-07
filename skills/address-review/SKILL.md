---
name: address-review
description: Triages PR review feedback — human comments and bot findings — on the current branch's PR or a given number/URL, fixes the real issues via the commit skill, and returns in-session replies for the rest. Never pushes or posts to the PR. Use when asked to address, resolve, or respond to PR comments or bot issues.
---

Triage and act on the review feedback on a pull request. Resolve the real issues in code and hand back replies for the ones that aren't — but never publish anything yourself.

## Get the comments

Default to the PR for the current branch; if a PR number or URL was passed as the argument, use that instead.

```sh
gh pr view --comments                              # PR body + review/issue comments
gh api repos/{owner}/{repo}/pulls/{n}/comments     # inline review comments, with file + line + diff hunk
```

- Address **unresolved** comments by default. Skip threads already marked resolved unless told otherwise. If the user named specific comments ("just Dan's two"), scope to those.
- Detect each comment's author: a human reviewer vs. a bot (`user.type == "Bot"`, or known bot logins like CodeRabbit/Copilot/Cursor). This only changes how a "not an issue" reply is phrased — see below.
- If a comment can't be fetched (posted somewhere `gh` doesn't reach), ask the user to paste it, then treat it identically.

## For each comment

**1. Understand it fully.** Read the comment and what it actually means. If it's unclear or ambiguous, disambiguate by reading the whole PR, other comments and discussions, and — most importantly — the code. If you still can't be certain you completely understand it, stop and ask the user in this session rather than guessing.

**2. Decide whether it's a real issue** that truly affects the code.

- **If not real:** craft a very succinct reply explaining why it isn't an issue, and return it in-session — do NOT post it. The user will use it to reply on the PR so other developers understand why no change was made. Phrase it for the audience: for a human reviewer, write it as a peer reply; for a bot finding, write it as a rebuttal explaining why the finding is irrelevant, already handled, or simply wrong.

- **If real:** fix it. While fixing, do not introduce new issues or undesired effects — beware of race conditions and of changing the original logic or intended purpose of the code. Apply the [[comment-hygiene]] standard to comments in the code you touch: don't add ones that merely restate the code, and drop existing ones that fail it.

**3. Re-review in context** after the fix. Confirm three things: the fix fully addresses the issue; it does not break or alter the intended behavior; and it causes no problems outside the fix. It's easy to lose the overall workflow while focused on one detail — make sure the fix hasn't broken something elsewhere.

**4. Look for similar issues** once the fix is verified. If the same class of problem exists elsewhere, apply this same procedure to each: understand it, confirm it's real, fix it, re-review it, and check again. Iterate until everything is handled.

## Committing and what to hand back

- Commit the changes you are **sure** about following the [[commit]] skill — invoke it so its exact conventions load; don't hand-roll commits.
- **Never push, and never post anything to the PR.** This skill only writes commits locally.
- For changes you are **not** sure about, or that are worth discussing or thinking through first, don't commit them — describe them in your response so they can be discussed before anything is done.
- Return all comment replies (the "not an issue" explanations and any discussion points) in this session, for the user to review before publishing.
