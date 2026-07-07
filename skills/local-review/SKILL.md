---
name: local-review
description: Review a GitHub PR as an expert staff engineer and return structured, categorized comments plus a verdict entirely in-session — nothing is ever posted to the PR or written to code. Takes the PR number or URL as an argument, plus optional pasted ticket/issue context to verify the PR actually fixes it. Use whenever instructed to review a PR locally / without publishing comments.
---

Act as an expert staff engineer reviewing a pull request. The PR to review — a URL or number — is given as the skill argument. If none was provided, ask for it before doing anything else.

The argument may also include **ticket/issue context** (pasted text, a link, user/job details, etc.). If it does, verifying the PR actually fixes that ticket becomes the highest-priority part of the review — see "Does it fix the ticket?" below. If no ticket is provided, skip that section and review for correctness and quality alone.

**Hard constraint:** deliver the entire review to the user in this session. NEVER modify code, commit, or write comments to the PR. This skill is read-only.

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
- Style and hygiene, no matter how minor: `any`, unnecessary typecasts, redundant comments or JSDocs, non-pure functions, missing tests, etc.

## Comment format

For every point, write:

```
Line: <piece of code so it can be found with ctrl+F>
File: <path-to-file>
Comment: <comment>
Category: BUG / COMMENT / HYPOTHETICAL
```

Leave a comment on every detail, no matter how minor — minor points still get surfaced even when the verdict is APPROVE.

## Verdict

Finish with exactly one of: **APPROVE**, **COMMENT**, or **REQUEST CHANGES**.

- **APPROVE** — the logic is correct (and, if a ticket was given, the PR genuinely fixes it). Use this even when there are minor style/hygiene issues (`any`, typecasts, redundant docs, non-pure functions, missing tests, etc.); still leave every comment. Approval signals the logic is sound; the author is expected to address the comments regardless.
- **COMMENT** — not ready for approval due to minor errors or bugs with no real risk of breaking anything. Explain clearly why it's not approved.
- **REQUEST CHANGES** — the PR is dangerous: as-is it would break something and needs a second look before merging. Reserve for real consequences (logically wrong code or effects that cascade), not style. Explain clearly why.

Both COMMENT and REQUEST CHANGES mean the PR is not ready for approval; in both cases make it unambiguous why. When a ticket was provided and the PR does not fix it, that alone is grounds to withhold approval, and it is the highest-priority reason to state.
