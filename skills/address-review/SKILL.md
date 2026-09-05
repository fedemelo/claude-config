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

## Get the comments

Inline review comments come from GraphQL, which is the only source that reports whether a thread is resolved. The REST endpoint `repos/{owner}/{repo}/pulls/{n}/comments` carries no resolution field of any kind, so it cannot tell an open thread from one settled weeks ago; do not use it here. Below, `<pr>` is the given number or URL, or empty to target the current branch's PR. Get the number the query needs with `gh pr view <pr> --json number --template '{{.number}}'`, then:

```sh
gh api graphql -F owner='{owner}' -F name='{repo}' -F number=<n> -f query='
query($owner:String!,$name:String!,$number:Int!){
  repository(owner:$owner,name:$name){ pullRequest(number:$number){
    reviewThreads(first:100){nodes{ isResolved isOutdated path line
      comments(first:20){nodes{ author{ login kind:__typename } body }}}}}}}' \
  --template '{{range .data.repository.pullRequest.reviewThreads.nodes}}{{if not .isResolved}}{{.path}}:{{.line}} outdated={{.isOutdated}}{{"\n"}}{{range .comments.nodes}}  {{.author.login}} [{{.author.kind}}]: {{.body}}{{"\n"}}{{end}}{{"\n"}}{{end}}{{end}}'
```

Conversation comments have no notion of resolution, so read them separately. Use `--json comments` with a template rather than `--comments`, which reprints the whole PR body and every comment in full:

```sh
gh pr view <pr> --json comments --template '{{range .comments}}{{.author.login}}: {{.body}}{{"\n"}}{{end}}'
```

1. `{owner}` and `{repo}` in the GraphQL command are substituted by `gh`, so it works in any repo without resolving the name first.
2. The template filters on `isResolved`, so what comes back is already the set to act on. Address all of it by default. To include resolved threads when the user asks, drop the `{{if not .isResolved}}` guard. If the user named specific comments ("just Dan's two"), scope to those.
3. `outdated=true` means the thread points at code that has since changed; re-read the current file before deciding, since the comment may already be moot.
4. `kind` is the author's GraphQL type, `User` or `Bot`, which settles human versus bot authoritatively rather than by guessing from the login. Do not pattern-match names: GitHub's own reviewer posts as `copilot-pull-request-reviewer`, and bot logins change. This only changes how a reply is phrased when the comment turns out not to be a real issue.
5. Raise `first:100` or `first:20` only if a PR is large enough to truncate.
6. If a comment cannot be fetched because it lives somewhere `gh` does not reach, ask the user to paste it, then treat it identically.

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
