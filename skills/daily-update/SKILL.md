---
name: daily-update
description: "Writes the work update the user posts to their team for a window ending today, built from their pull request activity in the current repo but regrouped by initiative and shaped by an external standard for what belongs in a daily update. Use when asked for a daily update, a standup post, or an update to send the team."
disallowed-tools: Edit Write NotebookEdit
---

Write the update the user posts to their team, covering a window that ends today. The material is their pull request activity; the shape is set by the guidelines quoted at the end, which come from outside this repo.

Hard constraints: this is read-only and unpublished. Never open, close, merge, comment on, or modify a PR, never touch code, and never post the update anywhere. Return it in this session for the user to send. Report only what the API says; never infer, guess, or pad.

The name says daily, but the window is whatever the user asks for. The point is to cover the work since their last update, which is often more than one day.

## Gather the material

Follow the [[work-summary]] skill for resolving the window and the repo, for the three fetch queries, and for summarizing each PR in one line. Four differences:

1. With no argument the cutoff is two days back (`date -v-2d +%F`), not seven, so the window runs from the day before yesterday through now. That is a day wider than a strictly daily post, on purpose: an update written late one day and early the next would otherwise drop the work in between. An argument overrides the default and is resolved exactly as that skill says.
2. Add `url` to each query's `--json` field list and print it with `{{.url}}` on the head line of each template, since the bullets link to the PRs. Change nothing else about the commands.
3. Skip the review and CI state. A reviewer count and a check status answer "where is my PR", which is a question about the user rather than about the work, and two of the bad examples below are exactly that kind of bullet.
4. Skip the closed-without-merging investigation, unless dropping the PR is itself news for the team, meaning an approach was abandoned or replaced. Then the stated reason is the bullet, and the commands for finding it are in that skill.

## Regroup by initiative

What comes back is one entry per PR. The update is not one bullet per PR: every bad example below is a list of changes, and every good one is a list of initiatives.

1. Group every PR serving the same initiative into one bullet, named for the initiative. A bullet is a piece of work and what moved in it, never a change and its state.
2. A one-off PR earns its own bullet only when a teammate gains something by knowing about it.
3. Each bullet says what moved inside this window and where the work stands now. The window is what makes tomorrow's bullet different from today's, and the standing is what makes it worth reading.
4. Expect two or three bullets. That is how many initiatives a person moves in a couple of days, and a longer list means the grouping collapsed back into one bullet per PR.
5. Drop what the team gains nothing from: dependency bumps, chores, flaky test fixes, and self-contained bug fixes in code nobody else is working on. The guidelines name that last one directly.
6. Never carry a status label. No `[Merged]`, `[In review]`, `[In progress]`, `[WIP]`. The verb already says where the work got to, and a list of labels is the failure the guidelines complain about most.

## Link the PRs

Every bullet links to the PRs behind it, inline in the sentence.

1. One word per PR, written as `[word](<url>)`. Never more than one word, and never the whole phrase.
2. The word is the verb for what that PR did, so the reader can tell which link covers which piece of work: `[Implemented](<url>) the ERP sync`.
3. Never link a filler word (this, here, PR, it), never link the number, and never append numbers at the end of the bullet.
4. When one bullet covers several PRs, each one contributes a single linked word to the part of the sentence it accounts for.
5. Use the PR's own `url`, never a number written out as text.

## Language

Write the bullets to the [[plain-english]] standard, with one exception: where the quoted guidelines differ, they win, because their examples set the form. They are terse fragments rather than full sentences, they use "we" and "I", and they are bullets rather than prose.

## Output

The update alone, ready to paste. One context line above it, and one line below it when work was left out. Neither line is part of the post, so label them as shown and keep them outside the bullets.

```
Window: <cutoff> to today (<today>), <owner>/<repo>

- Rebates: [completed](<url>) the ERP sync and [added](<url>) the UI list page. Approvals flow next.
- [Migrating](<url>) reports from a separate field per filter to one `filters` jsonb field, so we can support any filter without adding a column each time. 50% done.

Left out: #44 (dependency bump), #46 (flaky test fix)
```

End with that line, or with the last bullet when nothing was left out. Add no conclusion, no totals, and no suggestions about what to do next.

## The guidelines

Quoted from their source word for word, with one change: the Slack emoji are dropped, so that nothing here reads as an invitation to write with emoji. The Good and Bad labels they sat next to stayed. Nothing else is ours to edit. Match the examples as they are written rather than an interpretation of them, and let them settle anything this skill leaves open.

```
Daily update effectiveness

Everyone's doing a much better job posting, but now we have a new problem which is there's too much to read. I'd like to continue to read every single one and I think it can still stay manageable for the next while if everyone is thoughtful about how they post.

Include only useful things
The goal is to push useful information to your team, not to show that you're working hard. We know everyone is working hard. If it won't be useful to them to read it, don't post it. For example, no need to post about 1-1s or about a random bug you fixed that isn't relevant to anyone to know about.

Avoid duplicate content
If you're working on a long-running initiative, there should be progress each day and you should post about it. But it should be different each day, as opposed to seeing the same changes every day.

Good
Day 1
* Rebates: created tables and CRUD, working on ERP sync

Day 2
* Rebates: completed ERP sync and UI list page

Bad
Day 1
* [In progress] Rebates

Day 2
* [In progress] Rebates

Bad
Day 10
* Rebates is done (I haven't updated in 10 days)

Good
Day 1
* Change 1

Day 2
* Change 2
* Change 3

Bad
Day 1
* [Merged] Change 1
* [In review] Change 2
* [In review] Change 3

Day 2
* [Merged] Change 2
* [Merged] Change 3
* [In review] Change 4
* [In review] Change 5

Update at the right level of granularity
What are you working on? Why? What are the relevant technical details? Again, it all comes back to making this useful for your team.

Good
* Migrating reports from a separate field per filter to 1 `filters` jsonb field. That'll allow us support any filter without needing to keep adding an unbounded number of columns. 50% done.

Bad
* Reporting migration: Added `filters` jsonb field to `reports` table, updated openapi, added dual writes. Tests were flaky so I had to iterate on them a bit. I'm also seeing smoke test failures so I'll need to deal with those. Next step: backfilling and then switching to use the new field
```
