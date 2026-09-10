---
name: review-queue
description: Lists the open PRs on this repo that are waiting on your review, newest first, and starts one background session per PR to review it, so the reviews arrive as separate sessions you switch between rather than in this one. Also names the review sessions whose PR no longer needs you, for you to delete.
disable-model-invocation: true
---

Two jobs, in order: find the PRs waiting on your review, then start a session per PR to review it.

You never review a PR here. This session ends holding nothing but the roster of what it started, because the reviews are read one at a time in their own sessions, and a session that also holds five reviews is the clutter this skill exists to avoid.

## The list

Run this as it stands:

```sh
gh pr list --search "is:open review-requested:@me sort:created-desc" --limit 20 \
  --json number,url,createdAt,title \
  --template '{{printf "%-8s %-45s %-14s %s\n" "PR" "LINK" "CREATED" "TITLE"}}{{range .}}{{printf "%-8v %-45s %-14s %s\n" .number .url (.createdAt | timeago) .title}}{{end}}'
```

`--search` goes through the search API, which orders by best match unless told otherwise, so `sort:created-desc` is what makes "the 20 most recent" true rather than an arbitrary 20 of them. The command is scoped to the current repo by `gh pr list` itself.

Nothing in the list means nothing is waiting on you. Say so and stop; do not start a session to confirm it.

## A session per PR

One background session each, and never a review in this one:

```sh
claude --bg -n "review-<n>" --permission-mode auto "/local-review <url>"
```

- `--bg` returns immediately with a short id, so starting eight of these costs eight lines here and nothing else. The session inherits this working directory, so it starts in the right repo.
- `-n review-<n>` is what you see on the tab, and what finds the session again later. Keep the shape exactly, since the cleanup step below reads it back.
- `--permission-mode auto` because a background session in manual mode stalls on its first `gh` call, waiting for someone to switch to it and approve.
- The target is the PR's `url`, not its number: a pasted or attached session cannot be assumed to sit in this repo.
- `/local-review` and nothing else. Never `/review-loop`, which addresses and pushes; the review is yours to act on.

Skip any PR that already has a session named `review-<n>` in `claude agents --json --all`, so running this again starts only what is new. Never attach to a session you started, read its output, or wait on it. Switch to the tab yourself when you want the review.

### Reporting back, in Claude

This is the Claude CLI's own report format — it does not apply to the Codex path below, which keeps its own. No table: one block per PR, in the same newest-first order as the list, and nothing else surrounding it. For each PR:

```
#<n>: <title> (<created>)
    claude attach <id>
    <url>
```

`<id>` is the short id `claude --bg` returned for that PR's session. A PR skipped because a `review-<n>` session already existed still gets a line, using that session's existing id.

## Where there is no local claude CLI

In Codex, or a cloud session without the CLI, `claude --bg` does not exist, and there is no way to hand a cloud session a starting prompt. Still print the list, then one line per PR for you to paste into a session of your own:

```
/local-review https://github.com/<owner>/<repo>/pull/<n>
```

Say that is what happened and why. Never review the PRs here instead: several reviews in one context is the thing this skill is built to prevent, and it fails quietly, by writing each review in the shadow of the last one.

## Sessions you are done with

A PR that is no longer in the list no longer wants your review: you reviewed it, or it closed. Its session is now clutter.

Read `claude agents --json --all`, take every session whose name matches `review-<n>` for an `<n>` absent from the list, and print one line each for you to run:

```sh
claude rm <id>
```

Print them; never run them. A session you have not read yet is not yours to delete.

## What to report

In Claude, use the block format under "Reporting back, in Claude" above for the list and the started sessions, plus the `claude rm` lines from the section below. In Codex or a cloud session without the CLI, report the list as the command printed it, the `/local-review` lines to paste, and the `claude rm` lines. Nothing about any PR's contents, either way: you have not read one.
