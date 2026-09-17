---
name: review-queue
description: Lists the open PRs on this repo that are waiting on your review, newest first, and opens one space per PR to review it — a devspaces workspace in the "Local Review" group in a pod, a background session elsewhere — so the reviews arrive as separate spaces you switch between rather than in this one. Also names the review spaces whose PR no longer needs you, for you to delete.
disable-model-invocation: true
---

Two jobs, in order: find the PRs waiting on your review, then open one space per PR to review it.

You never review a PR here. This session ends holding nothing but the roster of what it opened, because the reviews are read one at a time in their own spaces, and a session that also holds five reviews is the clutter this skill exists to avoid.

## The list

Run this as it stands:

```sh
gh pr list --search "is:open review-requested:@me sort:created-desc" --limit 20 \
  --json number,url,createdAt,title \
  --template '{{printf "%-8s %-45s %-14s %s\n" "PR" "LINK" "CREATED" "TITLE"}}{{range .}}{{printf "%-8v %-45s %-14s %s\n" .number .url (.createdAt | timeago) .title}}{{end}}'
```

`--search` goes through the search API, which orders by best match unless told otherwise, so `sort:created-desc` is what makes "the 20 most recent" true rather than an arbitrary 20 of them. The command is scoped to the current repo by `gh pr list` itself.

Nothing in the list means nothing is waiting on you. Say so and stop; do not open a space to confirm it.

## A space per PR

One space each, and never a review in this one. What a space is depends on where you are running; take the first row that matches and follow only it:

| Where you are | What to open | How |
| --- | --- | --- |
| A devspaces pod, which has a `devspaces` executable on `PATH` | A devspaces workspace, in the `Local Review` group | [In devspaces](#in-devspaces) |
| Anywhere else with the `claude` CLI | A background session | [Where the claude CLI is local](#where-the-claude-cli-is-local) |
| Neither, e.g. Codex or a cloud session | Nothing; print a line to paste | [Where there is no local claude CLI](#where-there-is-no-local-claude-cli) |

**There is no fallback.** The row follows from the environment, not from how well its mechanism cooperates. If the one you landed on does not work, stop, name what you ran and what it said, and report which PRs got a space and which did not. Never drop to the row below, and never review a PR here instead. A pod that opened background sessions because the workspaces were harder is a pod where the reviews are somewhere you will not think to look.

Whichever row you land on, these hold:

- **Name it `review-<n>`**, for PR number `<n>`. Keep the shape exactly: it is what you see on the tab, and what the skip and cleanup steps below read back.
- **Skip any PR that already has a `review-<n>` space**, so running this again opens only what is new. A PR skipped this way still gets a line in the report.
- **The target is the PR's `url`, not its number**, since a pasted or attached space cannot be assumed to sit in this repo.
- **`/local-review` and nothing else.** Never `/review-loop`, which addresses and pushes; the review is yours to act on.
- **Never attach to a space you opened, read its output, or wait on it.** Switch to it yourself when you want the review.

### In devspaces

Each PR gets its own devspaces workspace, and every one of those workspaces is filed in the group named exactly `Local Review`. Both halves are the point of this path: a workspace per PR keeps the checkouts from colliding, and the group is what keeps eight reviews out of the groups you work in. File each workspace in that group as you create it, rather than somewhere else to be moved later.

Take the commands from the pod's own `devspaces` CLI rather than from memory, since its flags are free to change: read its help, then use whatever it offers for creating a workspace, for filing that workspace in a group, for listing the workspaces in one, and for giving a new workspace a starting prompt. Seed each one with `/local-review <url>`, so the review is running when you arrive.

Read the workspaces already in that group before creating anything. One named for a PR in the list means that review is already queued, so leave it as it is — a second workspace for the same PR is the duplicate this step exists to prevent, and the one already there may hold a review you have not read.

If the CLI will not do one of those four things, that is the end of this path: stop and report it, as above. No worktrees, no background sessions, no reviews here.

### Where the claude CLI is local

One background session each:

```sh
claude --bg -n "review-<n>" --permission-mode auto "/local-review <url>"
```

- `--bg` returns immediately with a short id, so opening eight of these costs eight lines here and nothing else. The session inherits this working directory, so it starts in the right repo.
- `--permission-mode auto` because a background session in manual mode stalls on its first `gh` call, waiting for someone to switch to it and approve.

`claude agents --json --all` is where you check for an existing `review-<n>` session.

### Reporting back

This is the report format for both paths above, devspaces and the local CLI. It does not apply to the Codex path below, which keeps its own. No table: one block per PR, in the same newest-first order as the list, and nothing else surrounding it. For each PR:

```
#<n>: <title> (<created>)
    <how to reach it>
    <url>
```

"How to reach it" is the workspace's name in devspaces, and `claude attach <id>` with the short id `claude --bg` returned elsewhere. A PR skipped because a `review-<n>` space already existed still gets a line, pointing at that space.

## Where there is no local claude CLI

In Codex, or a cloud session without the CLI, `claude --bg` does not exist, and there is no way to hand a cloud session a starting prompt. Still print the list, then one line per PR for you to paste into a space of your own:

```
/local-review https://github.com/<owner>/<repo>/pull/<n>
```

Say that is what happened and why. Never review the PRs here instead: several reviews in one context is the thing this skill is built to prevent, and it fails quietly, by writing each review in the shadow of the last one.

## Spaces you are done with

A PR that is no longer in the list no longer wants your review: you reviewed it, or it closed. Its space is now clutter.

Take every `review-<n>` space for an `<n>` absent from the list — workspaces in the `Local Review` group in devspaces, sessions in `claude agents --json --all` elsewhere — and hand them back for you to delete. Name the workspaces in devspaces; print one line each elsewhere:

```sh
claude rm <id>
```

Name them; never delete one. A review you have not read yet is not yours to throw away.

## What to report

Where you opened spaces, use the block format under "Reporting back" above for the list and the spaces you opened, plus the spaces to delete from the section above. In Codex or a cloud session without the CLI, report the list as the command printed it, the `/local-review` lines to paste, and the spaces to delete. Nothing about any PR's contents, either way: you have not read one.
