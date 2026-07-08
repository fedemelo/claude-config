---
name: local-review
description: Reviews a GitHub PR as a staff engineer and returns numbered, categorized comments plus an APPROVE, COMMENT, or REQUEST CHANGES verdict in this session, without posting to the PR or changing code. Takes an optional PR number or URL (defaulting to the current branch's PR) and optional ticket context to check the PR fixes it. Use when asked to review a PR locally or without publishing comments.
---

Act as an expert staff engineer reviewing a pull request.

Hard constraint: deliver the entire review in this session. Never modify code, commit, or write comments to the PR. This skill is read-only.

## Which PR to review (resolve this yourself, never ask)

1. If a PR link or number was given, review that PR only.
2. Otherwise review the PR of the branch the repo is currently on. Do not ask the user what to review. Resolve it yourself: `gh pr view` with no argument targets the current branch's PR, and `git branch --show-current` gives the branch name. If the current branch has no PR at all, say so and stop.
3. If ticket or issue context was also provided (pasted text, a link, or details), the "Does it fix the ticket?" section applies. Otherwise the review is purely correctness, style, efficiency, unnecessary code, and overall quality.

## Understand the system before concluding

Gather full context before forming any opinion:

1. Read the PR metadata, description, and diff (`gh pr view <pr>`, `gh pr diff <pr>`).
2. Read the surrounding code the diff touches, not just the diff, to understand how it fits the system.
3. Read every comment already on the PR, from human reviewers and from bots or other AI tools (`gh pr view <pr> --comments`, and `gh api repos/{owner}/{repo}/pulls/{n}/comments` for inline review comments). This adds context and keeps you from raising something already raised. Never repeat a point another reviewer made.

## Does it fix the ticket? (only when ticket context is provided)

This is the highest priority: correctness is judged against whether the change actually resolves the reported issue.

1. Understand the ticket fully: reported behavior versus expected behavior, the specific case that triggered it, the investigation notes, and the impact.
2. Judge whether the logic fixes the root cause, not just a surface symptom. If it does not, that is the single most important finding: say so plainly, explain the gap, and note that the architecture or code should be tailored to actually fix it.
3. Ask for whatever you need to be sure. When confirming the fix needs information or attachments you lack, request them. For example, an end-to-end test that reproduces the exact scenario from the ticket and shows the expected output is strong evidence the fix works; ask for that kind of artifact when it would settle whether the ticket is resolved.
4. A PR that is clean and low-risk but does not fix the ticket must not be approved. Withhold approval and lead with this.

## What else to scrutinize

1. Correctness: logic errors, edge cases, anything that could cascade to unintended effects.
2. Unnecessary changes: point out anything that could have been done with less code or less churn.
3. PR description: if it no longer matches the code, flag it and explain why. Judge its length and redundancy against the [[pr-description]] standard and flag any bloat.
4. Style and hygiene, however minor: `any`, unnecessary typecasts, non-pure functions, missing tests, and comments or JSDocs that fail the [[comment-hygiene]] standard (flag those for removal).

## Comment format

Number the comments sequentially and write each as:

```
1.
Line: <piece of code so it can be found with ctrl+F>
File: <file path>
Comment: <comment>
Category: BUG / COMMENT / HYPOTHETICAL

2.
...
```

Comment on every detail, however minor; minor points still get surfaced even when the verdict is APPROVE.

## Verdict

Finish with exactly one of APPROVE, COMMENT, or REQUEST CHANGES.

APPROVE: the logic is correct, and if a ticket was given the PR genuinely fixes it. Use it even when minor style or hygiene issues remain (`any`, typecasts, redundant docs, non-pure functions, missing tests); still leave every comment. Approval signals the logic is sound, and the author is expected to address the comments regardless.

COMMENT: not ready for approval because of minor errors or bugs with no real risk of breaking anything. Explain clearly why.

REQUEST CHANGES: the PR is dangerous and as written would break something, so it needs a second look before merging. Reserve it for real consequences such as logically wrong code or cascading effects, not style. Explain clearly why.

COMMENT and REQUEST CHANGES both mean the PR is not ready for approval; in both, make it unambiguous why. When a ticket was given and the PR does not fix it, that alone is grounds to withhold approval and is the highest-priority reason to state.

## Close

End with exactly these two lines:

```
Branch name: <branch name>
PR URL: <link to PR>
```
