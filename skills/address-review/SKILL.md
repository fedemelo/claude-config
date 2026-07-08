---
name: address-review
description: Triages PR review feedback (human comments and bot findings) on the current branch's PR or a given number or URL, fixes the real issues by following the commit skill, and returns replies in this session for the rest. Never pushes or posts to the PR. Use when asked to address, resolve, or respond to PR comments or bot issues.
---

Triage and act on the review feedback on a pull request. Fix the real issues in code, hand back replies for the ones that are not, and never publish anything yourself.

## Which PR to address (resolve this yourself, never ask)

1. If a PR link or number was given, address that PR only.
2. Otherwise address the PR of the branch the repo is currently on. Do not ask the user which PR. Resolve it yourself: `gh pr view` with no argument targets the current branch's PR, and `git branch --show-current` gives the branch name. If the current branch has no PR at all, say so and stop.

## Get the comments

```sh
gh pr view --comments                            # PR body plus review and issue comments
gh api repos/{owner}/{repo}/pulls/{n}/comments   # inline review comments, with file, line, and diff hunk
```

1. Address unresolved comments by default. Skip threads already marked resolved unless told otherwise. If the user named specific comments ("just Dan's two"), scope to those.
2. Detect each comment's author, human reviewer or bot (`user.type == "Bot"`, or known bot logins like CodeRabbit, Copilot, Cursor). This only changes how a reply is phrased when the comment turns out not to be a real issue.
3. If a comment cannot be fetched because it lives somewhere `gh` does not reach, ask the user to paste it, then treat it identically.

## For each comment

1. Understand it fully. Read what it actually means. If it is unclear, disambiguate by reading the whole PR, the other comments and discussions, and above all the code. If you still cannot be certain you understand it, stop and ask the user in this session rather than guessing.
2. Decide whether it is a real issue that truly affects the code.
3. If it is not real, write a very succinct reply explaining why, and return it in this session without posting it. The user will use it to reply on the PR so other developers understand why nothing changed. Phrase it for the audience: a peer reply for a human reviewer, or a rebuttal for a bot finding that explains why it is irrelevant, already handled, or wrong.
4. If it is real, fix it. Do not introduce new issues or undesired effects; beware race conditions and any change to the original logic or intent of the code. Apply the [[comment-hygiene]] standard to comments in the code you touch: add none that merely restate the code, and drop existing ones that fail it.
5. Review the fix again in context. Confirm it fully addresses the issue, does not alter intended behavior, and causes no problems elsewhere. It is easy to lose the overall workflow while focused on one detail, so check that the fix broke nothing else.
6. Look for similar issues. If the same class of problem exists elsewhere, run this same procedure on each until everything is handled.

## Commit and hand back

1. Commit the changes you are sure about by following the [[commit]] skill; invoke it so its exact conventions load.
2. Never push, and never post anything to the PR. This skill only writes commits locally.
3. Do not commit changes you are unsure about or that are worth discussing first; describe them in your response instead.
4. Return every comment reply and discussion point in this session, for the user to review before publishing.
