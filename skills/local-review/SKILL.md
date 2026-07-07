---
name: local-review
description: Reviews a GitHub PR as a staff engineer, returning numbered categorized comments and an APPROVE/COMMENT/REQUEST CHANGES verdict in-session without posting to the PR or changing code. Takes an optional PR number/URL (defaults to the current branch's PR) and optional ticket context to check the PR fixes it. Use when asked to review a PR locally or without publishing comments.
---

Act as an expert staff engineer reviewing a pull request.

**Hard constraint:** deliver the entire review to the user in this session. NEVER modify code, commit, or write comments to the PR. This skill is read-only.

## Which PR to review (resolve this yourself — never ask)

1. If a PR link or number was given, review exclusively that PR.
2. Otherwise, review exclusively the PR of the branch the repo is currently on — do not ask the user what to review. Resolve it yourself: `gh pr view` with no argument targets the current branch's PR, and `git branch --show-current` gives the branch name. Only if the current branch has no PR at all, say so and stop.
3. If ticket/issue context was also provided (pasted text, a link, or details), the "Does it fix the ticket?" section applies. If not, the review is purely correctness, style, efficiency, unnecessary code, and overall code quality.

## Understand the system before concluding

Be extremely thorough. Gather full context before forming any opinion:
- Read the PR metadata, description, and diff (`gh pr view <pr>`, `gh pr diff <pr>`).
- Read the surrounding code the diff touches, not just the diff — understand how it fits the system.
- Read every existing comment already on the PR — from human reviewers and from bots or other AI tools (`gh pr view <pr> --comments`, and `gh api repos/{owner}/{repo}/pulls/{n}/comments` for inline review comments). This gives fuller context and, crucially, prevents you from redundantly surfacing something already raised. Do not repeat a point another reviewer already made.

## Does it fix the ticket? (only when ticket context is provided)

This is the highest priority. Correctness is judged against whether the change actually resolves the reported issue.
- Understand the ticket fully: the reported behavior vs. expected behavior, the specific case that triggered it, the investigation notes, and the impact.
- Judge whether the PR's logic genuinely fixes the root cause described — not just a surface symptom. If it does not, that is the single most important finding: say so plainly, explain the gap, and note that architecture and/or code changes should be tailored to actually fix it.
- Ask for whatever you need to be sure. If confirming the fix requires information or attachments you don't have, request them explicitly. For example: an end-to-end test that reproduces the exact scenario from the ticket and shows the expected output actually being produced is strong evidence the fix works — ask for that kind of artifact when it would settle whether the ticket is truly resolved.
- A PR that is clean and low-risk but does not fix the ticket must not be approved; withhold approval and lead with this.

## What else to scrutinize

- Correctness: logic errors, edge cases, anything that could cascade to unintended effects.
- Unnecessary changes: if something could have been done with less code or less churn, point it out.
- PR description drift: if the description no longer matches the code, flag it and explain why. If the description is unnecessarily large or redundant, flag that too.
- Style and hygiene, no matter how minor: `any`, unnecessary typecasts, non-pure functions, missing tests, and comments or JSDocs that fail the [[comment-hygiene]] standard (flag them for removal).

## Comment format

Number the comments sequentially, in order, and write each as:

```
1.
Line: <piece of code so it can be found with ctrl+F>
File: <path-to-file>
Comment: <comment>
Category: BUG / COMMENT / HYPOTHETICAL

2.
Line: ...
File: ...
Comment: ...
Category: ...
```

Leave a comment on every detail, no matter how minor — minor points still get surfaced even when the verdict is APPROVE.

## Verdict

Finish with exactly one of: **APPROVE**, **COMMENT**, or **REQUEST CHANGES**.

- **APPROVE** — the logic is correct (and, if a ticket was given, the PR genuinely fixes it). Use this even when there are minor style/hygiene issues (`any`, typecasts, redundant docs, non-pure functions, missing tests, etc.); still leave every comment. Approval signals the logic is sound; the author is expected to address the comments regardless.
- **COMMENT** — not ready for approval due to minor errors or bugs with no real risk of breaking anything. Explain clearly why it's not approved.
- **REQUEST CHANGES** — the PR is dangerous: as-is it would break something and needs a second look before merging. Reserve for real consequences (logically wrong code or effects that cascade), not style. Explain clearly why.

Both COMMENT and REQUEST CHANGES mean the PR is not ready for approval; in both cases make it unambiguous why. When a ticket was provided and the PR does not fix it, that alone is grounds to withhold approval, and it is the highest-priority reason to state.

## Close

End the review with exactly these two lines:

```
Branch name: <branch name>
PR URL: <link to PR>
```
