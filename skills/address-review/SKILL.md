---
name: address-review
description: Triages PR review feedback (human comments and bot findings) on the current branch's PR or a given number or URL, fixes the real issues by following the commit skill, and returns replies in this session for the rest. Never comments on the PR or asks anyone for a review, and pushes only when asked to. Use when asked to address, resolve, or respond to PR comments or bot issues.
disable-model-invocation: true
---

Triage and act on the review feedback on a pull request. Fix the real issues in code, hand back replies for the ones that are not, and never post any of them yourself.

Hard constraint, and the one to hold above every other line here: never put anything in front of a person on the PR. No comment, no reply to a thread, no resolving a thread, no reaction, no review or re-review request. This holds however obviously right a reply looks and however explicitly the review asks for an answer. Every reply is text in this session for the user to post themselves.

Pushing is allowed only when the user explicitly asks for it; else, the work stays as local commits. A push the user asked for covers updating the branch and nothing further, so it still comes with no re-review request and no comment about what changed.

## Which PR to address

Resolve it with [[pr-target]].

## Get the feedback

```sh
git review-feedback <pr>
```

One command, and the only one to use. `<pr>` is the number, URL or branch, omitted for the
current branch's PR.

Feedback on a PR lives in three places that no two of them overlap: inline review threads, the
body attached to a submitted review, and conversation comments. No single `gh` command returns
all three, so fetching them by hand is how a review gets addressed in part while looking
complete, and the body attached to an approval is what goes missing. This returns all three from
one query. If `git-review-feedback` is not installed, a hook blocks it and says so; report that
to the user rather than rebuilding it out of raw `gh` calls, since that is the very thing that
drops a source.

1. Resolved threads are hidden and counted, so what comes back is already the set to act on.
   Address all of it by default. Pass `--all` when the user asks for resolved threads too, and
   `--author <logins>` when they named specific reviewers ("just Dan's two").
2. Every point carries an id: `R1` for a review body, `T1` for a thread, `C1` for a conversation
   comment. Use those ids in your response so each reply is unambiguous about what it answers.
3. `APPROVED` on a review body does not mean there is nothing to do. An approval often carries a
   request, and it is triaged like any other point.
4. A review body takes no inline reply, which changes where the answer goes, never whether it
   gets one. What is real is fixed in code; what is not goes into your response.
5. `⚠ outdated` on a thread is GitHub's own verdict that the code moved since. `⚠ written before
   the current head` on a review body or comment is a hint rather than a verdict, since nothing
   computes that one. Either way, read the code as it stands before deciding: the point may
   already be moot.
6. Each thread arrives with the diff lines it is anchored to. That is where the comment points,
   not necessarily where the problem is, so read the file itself before concluding.
7. A `[bot]` tag is the author's GitHub account type, not a guess from the login. It only changes
   how a reply is phrased when the point turns out not to be a real issue.
8. If a point cannot be fetched because it lives somewhere `gh` does not reach, ask the user to
   paste it, then treat it identically.

## For each comment

1. Understand it fully. Read what it actually means. If it is unclear, disambiguate by reading the whole PR, the other comments and discussions, and above all the code. If you still cannot be certain you understand it, stop and ask the user in this session rather than guessing.
2. Decide whether it is a real issue that truly affects the code.
3. If it is not real, write a very succinct reply explaining why, and return it in this session without posting it. The user will use it to reply on the PR so other developers understand why nothing changed. Write it to the [[plain-english]] standard, phrased for the audience: a peer reply for a human reviewer, or a rebuttal for a bot finding that explains why it is irrelevant, already handled, or wrong.
4. If it is real, fix it. Do not introduce new issues or undesired effects; beware race conditions and any change to the original logic or intent of the code. Apply the [[comment-hygiene]] standard to comments in the code you touch: add none that merely restate the code, and drop existing ones that fail it.
5. Review the fix again in context. Confirm it fully addresses the issue, does not alter intended behavior, and causes no problems elsewhere. It is easy to lose the overall workflow while focused on one detail, so check that the fix broke nothing else.
6. Look for similar issues. If the same class of problem exists elsewhere, run this same procedure on each until everything is handled.

## Commit and hand back

1. Commit the changes you are sure about by following the [[commit]] skill; invoke it so its exact conventions load.
2. Push only if the user asked for a push, and then push the branch alone, as the hard constraint at the top says.
3. Do not commit changes you are unsure about or that are worth discussing first; describe them in your response instead.
4. Return every comment reply and discussion point in this session, for the user to review before publishing.
