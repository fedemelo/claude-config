---
name: work-summary
description: "Summarizes the user's own pull request activity in the current repo from a cutoff date to now: PRs still open, PRs merged, and PRs closed without merging, each with a one-line summary of what it does plus review and CI state. Use when asked what work was done, for a recap, or for a status update over a period."
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: 'python3 $HOME/.claude/hooks/allow-skill-commands.py "gh pr list" "gh pr view" "gh pr diff" "gh pr checks" "gh repo view" "gh api repos/" "date"'
---

Report the user's own pull request activity in the current repo, from a cutoff date up to now.

Hard constraints: this is a read-only report. Never open, close, merge, comment on, or modify a PR, and never touch code. Report only what the API says; never infer, guess, or pad. This covers PRs alone, so do not claim it represents all the user's work.

Run the commands below as written rather than devising your own. Each is the cheapest form that answers its question, and the obvious alternatives are far more expensive: `gh pr view <n>` and `gh pr view <n> --comments` reprint an entire PR to surface one field, and raw `--json` output for as few as three PRs runs past 50 KB, most of it `body` and `statusCheckRollup`. Every command therefore ends in `--template`, which renders locally so only the rendered lines are read. Fields named in `--json` but collapsed by the template cost nothing to read, so keep the field lists as given.

Three syntax rules keep these commands from stalling on a permission prompt. Never use command substitution (`$(...)`) or redirection. Never use `--jq`, whose pipes read as separate commands. And keep `|` and `;` out of the template strings themselves, for the same reason, which is why the templates below separate fields with `--`.

## Resolve the window and the repo

1. The cutoff date is the argument. Accept `YYYY-MM-DD` or relative wording ("last Friday", "3 days ago", "the last 5 days"), resolving relative wording to a concrete date with `date` (`date +%F` for today, `date -v-<n>d +%F` for a number of days back). With no argument, use 7 days ago.
2. "The last N days" means N days before today, a window spanning N+1 calendar days once today is counted. Prefer that slightly wide window to risking a dropped day, and let the header show the resolved date.
3. The window runs from the start of the cutoff day through now, so the cutoff day itself always counts.
4. Anchor that start to the user's timezone: read the offset with `date +%z` and write it into the query as `created:<cutoff>T00:00:00-0500..*`. A bare date is read as UTC, which for a negative offset pulls in the previous evening's work and files it under the wrong day. Inline the literal offset rather than substituting the command inside the query.
5. The repo is whatever `gh` infers from the current directory; never ask which one. If the directory is not a GitHub repo, say so and stop. Get the name for the header with `gh repo view --json nameWithOwner --template '{{.nameWithOwner}}'`.

## Fetch the three sets

One command per section, and each PR lands in exactly one section, so the queries do not overlap. Below, `<from>` is the resolved cutoff written as `YYYY-MM-DDT00:00:00-0500`, with the real local offset.

```sh
gh pr list --author @me --state open --search "created:<from>..*" --limit 100 --json number,title,body,createdAt,isDraft,reviewRequests,reviews --template '{{range .}}#{{.number}} {{.title}} -- created {{timefmt "2006-01-02" .createdAt}} draft={{.isDraft}} requested={{len .reviewRequests}} reviews={{len .reviews}}{{"\n"}}{{truncate 400 .body}}{{"\n\n"}}{{end}}'

gh pr list --author @me --state merged --search "merged:<from>..*" --limit 100 --json number,title,body,createdAt,mergedAt,mergedBy --template '{{range .}}#{{.number}} {{.title}} -- merged {{timefmt "2006-01-02" .mergedAt}} by {{.mergedBy.login}}{{"\n"}}{{truncate 400 .body}}{{"\n\n"}}{{end}}'

gh pr list --author @me --state all --search "closed:<from>..* is:unmerged" --limit 100 --json number,title,body,createdAt,closedAt --template '{{range .}}#{{.number}} {{.title}} -- opened {{timefmt "2006-01-02" .createdAt}} closed {{timefmt "2006-01-02" .closedAt}}{{"\n"}}{{truncate 400 .body}}{{"\n\n"}}{{end}}'
```

1. Write the search as an open-ended range, `<from>..*`, never `>=<from>`.
2. `is:unmerged` is required on the third query: `--state closed` counts merged PRs as closed, so without it merged work is reported twice.
3. The 400-character body is normally the whole description and enough to summarize from. Widen the truncation for a specific PR only when its slice is cut mid-thought and the summary depends on the rest.
4. If any query returns exactly 100 PRs it was probably truncated; re-run it with a higher `--limit` before reporting.

## Summarize each PR in one line

Say what the change does, in one line, always more explanatory than the title. Never restate the title verbatim.

1. Derive it from the title and body already fetched above; that is enough for most PRs and costs nothing extra.
2. When they are too thin to say what the change does, escalate in this order and stop as soon as it is clear: `gh pr diff --name-only <n>` for the touched paths, then `gh pr diff <n>` for the patch. The full patch is the only expensive call in this skill, so reach for it last and per PR, never as a sweep.
3. Describe the change, not the process: what behavior, bug, or structure it alters.
4. If even the diff leaves the intent unclear, say what the code changes and stop there.

## Review and CI state (open PRs only)

Report both for every open PR, in that order.

1. In review when `requested` or `reviews` is above zero; give the reviewer count. `requested` drops back to zero once a reviewer submits, which is why the review count matters too.
2. Not in review when both are zero. Call this out explicitly as needing reviewers, whether or not the PR is a draft, since nothing is moving until someone is asked. Note draft status separately, as an additional fact and never as the explanation.
3. For CI, run one `gh pr checks` per open PR, all in a single command separated by `;`. Write each PR's number into its own template, since `gh pr checks` output carries nothing identifying and batched results are otherwise impossible to attribute:

```sh
gh pr checks <n> --json name,bucket --template '#<n> {{len .}} checks, not passing: {{range .}}{{if and (ne .bucket "pass") (ne .bucket "skipping")}}{{.name}}={{.bucket}} {{end}}{{end}}{{"\n"}}'
```

4. Read the result by `bucket`, which normalizes across check types so nothing has to be inferred from a raw rollup: nothing listed means passing, `fail` or `cancel` means failing, and `pending` means still running. Name the failing checks. Skipped checks are filtered out deliberately, since they are not failures.
5. Prefer this over `statusCheckRollup` on the list query. That field is the single largest payload in the API, it repeats a check once per run, and it splits into `CheckRun` and `StatusContext` shapes carrying different fields, so a template over it prints `<no value>` noise.
6. If `gh pr checks` reports that no checks exist for the PR, say no checks ran rather than calling it passing.

## Closed without merging

Run these only for PRs in this section, never across the whole window.

1. Look for a stated reason in the comments. Use `--json comments` with a template, not `--comments`, which reprints the entire PR body and every comment in full:

```sh
gh pr view <n> --json comments --template '{{range .comments}}{{.author.login}} {{timefmt "2006-01-02" .createdAt}}: {{truncate 400 .body}}{{"\n"}}{{end}}'
```

2. A closing comment by the author or by whoever closed it, or a comment pointing at a superseding PR, is the reason.
3. If a reason is stated, that is the bullet: what the PR did, and why it was closed.
4. If no reason is stated, never infer one. Report what the PR did, how long it had been open, that it is now closed, and that no reason was given.
5. The timeline names who closed it and any cross-referenced PR. Filter it in the template; the raw response is roughly 250 times the size of the two lines wanted from it:

```sh
gh api repos/{owner}/{repo}/issues/<n>/timeline --template '{{range .}}{{if eq .event "closed"}}closed by {{.actor.login}}{{"\n"}}{{end}}{{if eq .event "cross-referenced"}}xref #{{.source.issue.number}}{{"\n"}}{{end}}{{end}}'
```

6. Use the timeline only when the comments state no reason, and mention the closer only when it was not the user. Branch on `.event`, which is always present; testing fields that exist on only some events errors out.

## Output

Plain prose and bullets, no tables. Give each section its count, and collapse an empty section to a single line ("Nothing merged in this window."). Order every section newest first.

```
Window: <cutoff> to today (<today>), <owner>/<repo>

Opened, still open (2)
- #41 <what it does>. In review (2 reviewers). CI passing.
- #43 <what it does>. No reviewers requested, so it is not in review. Draft. CI failing (build, lint).

Merged (3)
- #38 <what it does>. Merged by <login> on <date>.

Closed without merging (1)
- #39 <what it does>. Closed <date>: superseded by #44.
- #40 <what it does>. Open since <date>, closed <date>, no reason given.
```

End with the last bullet. Add no conclusion, no totals beyond the section counts, and no suggestions about what to do next.
