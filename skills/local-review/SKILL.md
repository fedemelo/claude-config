---
name: local-review
description: Reviews a GitHub PR as a staff engineer and returns numbered, categorized comments plus an APPROVE, COMMENT, or REQUEST CHANGES verdict in this session, without posting to the PR or changing code. Takes an optional PR number or URL (defaulting to the current branch's PR) and optional ticket context to check the PR fixes it. Use when asked to review a PR locally or without publishing comments.
disallowed-tools: Edit Write NotebookEdit
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: 'python3 $HOME/.claude/hooks/allow-skill-commands.py "gh pr view" "gh pr diff" "gh api repos/" "git fetch" "git show" "git log" "git diff" "git status"'
---

Act as an expert staff engineer reviewing a pull request.

Hard constraint: deliver the entire review in this session. This skill is strictly read-only: never modify code, commit, post to the PR, switch or check out branches, create a worktree, or stash. Everything below is achievable read-only.

## Which PR to review (resolve this yourself, never ask)

1. If a PR number or URL was given, review exactly that PR.
2. Otherwise review the current branch's PR: `gh pr view` with no argument targets it. There must be an open PR for the branch; if there is none, say so and stop. Do not review the local working tree (uncommitted or unpushed changes) as a fallback.
3. If ticket or issue context was also provided (pasted text, a link, or details), apply the "Does it fix the ticket?" section. Otherwise review purely for correctness, style, efficiency, unnecessary code, and overall quality.

## Understand the system before concluding

Gather full context before forming an opinion. Below, `<pr>` is the given number or URL (or empty for the current branch's PR); `<n>` is the PR number.

1. Read the diff, then only the metadata you need. The diff comes straight from `gh pr diff <pr>`; never fetch it through the PR's web URL. Scope the metadata with `--json` rather than pulling the full view:

```sh
gh pr diff <pr>
gh pr view <pr> --json number,title,body,headRefName
```

2. Read the surrounding code the diff touches, not just the diff. Fetch the PR head without checking out, then read files from it:

```sh
git fetch origin pull/<n>/head        # <n>: the number from the metadata above
git show FETCH_HEAD:<path>
```

3. Read every existing comment, from humans and from bots or other AI tools, so you never repeat a point another reviewer already made. Both commands render through `--template`, which keeps the output to the comments themselves; `--comments` and the raw REST endpoint each return several times the volume for the same content, most of it identifiers and URLs.

```sh
gh pr view <pr> --json comments --template '{{range .comments}}{{.author.login}}: {{.body}}{{"\n"}}{{end}}'
gh api repos/{owner}/{repo}/pulls/<n>/comments --template '{{range .}}{{.user.login}} {{.path}}:{{.line}}{{"\n"}}{{.diff_hunk}}{{"\n"}}{{.body}}{{"\n\n"}}{{end}}'
```

## Does it fix the ticket? (only when ticket context is provided)

This is the highest priority: correctness is judged against whether the change resolves the reported issue.

1. Understand the ticket fully: reported versus expected behavior, the specific case that triggered it, the investigation notes, and the impact.
2. Judge whether the logic fixes the root cause, not just a surface symptom. If it does not, say so as the single most important finding, explain the gap, and note that the architecture or code should be tailored to actually fix it.
3. Ask for whatever you need to be sure. If confirming the fix needs information or an artifact you lack, request it; for example, an end-to-end test that reproduces the ticket's exact scenario and shows the expected output.
4. A PR that is clean and low-risk but does not fix the ticket must not be approved; say so first.

## What else to scrutinize

1. Correctness: logic errors, edge cases, anything that could cascade to unintended effects.
2. Unnecessary changes: anything that could have been done with less code or less churn.
3. Intent: read the PR description as the author's statement of what they meant to do, and check the code against it. Say so whenever the two diverge, in the form "the description says X, the code does Y", and treat the divergence as a finding about the code or about a change the description never mentions, anchored to the code that diverges rather than to the description. Never review the description itself: not its wording, its formatting, its length, or whether it is still up to date.
4. Style and hygiene, however minor: `any`, unnecessary typecasts, non-pure functions, missing tests, and comments or JSDocs that fail the [[comment-hygiene]] standard.

## Comment format

Number the comments sequentially and write each as:

```
1.
Category: BUG / MAJOR / MINOR / SUGGESTION / HYPOTHETICAL
Line: <piece of code from the diff so it can be found with ctrl+F>
File: <path of the file that code lives in>
Reasoning: <the full case for the finding>

Comment: <the comment as it will be posted>

2.
...
```

Every comment is posted on a line of code, so Line and File always point at code the diff touches, and never at the PR description, the title, the commit messages, or anything else outside a file. Such a line always exists. A problem that is real now and was not real before was caused by something this PR changed, however long the chain from cause to effect, so anchor the comment to the line that caused it: the new call for the case it fails to handle, the changed signature for the caller left behind, the new branch for the test that does not cover it. When nothing in the diff caused it, the problem predates the PR and is not this review's business.

Reproduce that layout exactly, including the blank line before the comment. The comment is the part the user acts on, so it has to be findable at a glance rather than buried against the reasoning above it.

Two rules survive the field order. The reasoning is written first and the comment is compressed from it, never the other way round. The category is a conclusion drawn from the reasoning by the tests below, never a label chosen before the case is made; settle both before writing the block out, so the category standing at the top reports a decision already taken.

Order the findings by category, in the order listed under "Categories" below, rather than by file. Number them sequentially across the whole list.

Reasoning is for the user, who decides whether to post. It has to convince them the finding is real, so give it everything: what is wrong, the code path that proves it, every function, module, and file involved, and how it was verified, naming the files and lines read. Length does not matter here.

Comment is for the PR author, and the user posts it as written. Follow the [[plain-english]] standard in full, plus:

1. Name at most one identifier beyond what is already visible on the commented line. Every other name belongs in the reasoning.
2. Say what goes wrong, and what to do instead when that is not obvious. Never how the finding was reached.
3. It must hold up alone. If compressing drops a condition that the finding depends on, keep the condition and cut something else, since a comment that is clear but wrong costs more than a long one.

Comment on every detail, however minor, even when the verdict is APPROVE.

## Categories

1. BUG: the code is wrong. It breaks now, or breaks on an input that can actually occur. It has to be fixed before merging.
2. MAJOR: nothing breaks, but leaving it costs later. Duplicated code that will drift out of sync, an abstraction in the wrong place, a missing test over risky logic.
3. MINOR: objectively wrong, cheap to fix, and cheap to leave. A comment that restates the code, an unnecessary cast, a stray `any`.
4. SUGGESTION: nothing is wrong. An alternative worth naming, and fine if the author declines it.
5. HYPOTHETICAL: correct today, and a problem only under conditions that do not hold yet. Always state the condition.

Use these tests on the boundaries:

1. BUG or MAJOR: does an input that can actually occur produce wrong behavior? If yes, BUG.
2. MAJOR or MINOR: if the author declined to change it, would you still want it changed before merging? If yes, MAJOR.
3. MINOR or SUGGESTION: is it objectively wrong, or just not how you would have done it? If wrong, MINOR.
4. HYPOTHETICAL or BUG: does the triggering condition exist in the code today? If yes, BUG.

When two categories both fit, take the lower one. A genuine question gets no category of its own: file it under the concern behind it, usually MAJOR or HYPOTHETICAL, and phrase the comment as the question.

## Verdict

Finish with exactly one of APPROVE, COMMENT, or REQUEST CHANGES. These are the GitHub review actions, unrelated to the categories above.

1. APPROVE: the logic is correct, and if a ticket was given the PR genuinely fixes it. Every finding is MINOR, SUGGESTION, or HYPOTHETICAL. Still leave all of them, since the author addresses them regardless.
2. COMMENT: there is at least one MAJOR, or a BUG that carries no real risk of breaking anything.
3. REQUEST CHANGES: a BUG would break something real, so the PR needs a second look before merging. Reserve it for real consequences such as logically wrong code or cascading effects, not style.

COMMENT and REQUEST CHANGES both withhold approval; state plainly why.

## Close

End with exactly these two lines, using the `headRefName` (the PR's head branch) and `number` from the metadata fetched above:

```
Branch name: <branch name>
PR: #<number>
```
