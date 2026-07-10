---
name: local-review
description: Reviews a GitHub PR as a staff engineer and returns numbered, categorized comments plus an APPROVE, COMMENT, or REQUEST CHANGES verdict in this session, without posting to the PR or changing code. Takes an optional PR number or URL (defaulting to the current branch's PR) and optional ticket context to check the PR fixes it. Use when asked to review a PR locally or without publishing comments.
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: 'python3 $HOME/.claude/hooks/allow-skill-commands.py "gh pr view" "gh pr diff" "git fetch" "git show" "git log" "git diff" "git status"'
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
gh pr view <pr> --json number,title,body,url,headRefName
```

2. Read the surrounding code the diff touches, not just the diff. Fetch the PR head without checking out, then read files from it:

```sh
git fetch origin pull/<n>/head        # <n>: the number from the metadata above
git show FETCH_HEAD:<path>
```

3. Read every existing comment, from humans and from bots or other AI tools: `gh pr view <pr> --comments`, plus `gh api repos/{owner}/{repo}/pulls/<n>/comments` for inline review comments. Never repeat a point another reviewer already made.

## Does it fix the ticket? (only when ticket context is provided)

This is the highest priority: correctness is judged against whether the change resolves the reported issue.

1. Understand the ticket fully: reported versus expected behavior, the specific case that triggered it, the investigation notes, and the impact.
2. Judge whether the logic fixes the root cause, not just a surface symptom. If it does not, say so as the single most important finding, explain the gap, and note that the architecture or code should be tailored to actually fix it.
3. Ask for whatever you need to be sure. If confirming the fix needs information or an artifact you lack, request it; for example, an end-to-end test that reproduces the ticket's exact scenario and shows the expected output.
4. A PR that is clean and low-risk but does not fix the ticket must not be approved; say so first.

## What else to scrutinize

1. Correctness: logic errors, edge cases, anything that could cascade to unintended effects.
2. Unnecessary changes: anything that could have been done with less code or less churn.
3. PR description: flag it if it no longer matches the code, and flag bloat judged against the [[pr-description]] standard.
4. Style and hygiene, however minor: `any`, unnecessary typecasts, non-pure functions, missing tests, and comments or JSDocs that fail the [[comment-hygiene]] standard.

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

Comment on every detail, however minor, even when the verdict is APPROVE.

## Verdict

Finish with exactly one of APPROVE, COMMENT, or REQUEST CHANGES.

1. APPROVE: the logic is correct, and if a ticket was given the PR genuinely fixes it. Use it even when minor style or hygiene issues remain; still leave every comment, since the author addresses them regardless.
2. COMMENT: minor errors or bugs that carry no real risk of breaking anything.
3. REQUEST CHANGES: the PR would break something and needs a second look before merging. Reserve it for real consequences such as logically wrong code or cascading effects, not style.

COMMENT and REQUEST CHANGES both withhold approval; state plainly why.

## Close

End with exactly these two lines, using the `headRefName` (the PR's head branch) and `url` from the metadata fetched above:

```
Branch name: <branch name>
PR URL: <link to PR>
```
