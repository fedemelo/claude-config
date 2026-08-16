---
name: second-opinion
description: "Gives an informed opinion on a comment someone left on a PR: refetches so the view is current, works out which comment is meant without being told, checks the claim against the code, and says plainly whether it holds. Never changes code, posts, replies, or drafts a reply. Use when asked what you think or wdyt about a comment, or for a take on someone's review feedback."
disallowed-tools: Edit Write NotebookEdit
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: 'python3 $HOME/.claude/hooks/allow-skill-commands.py "gh pr view" "gh pr diff" "gh api user" "gh api graphql" "git fetch" "git show" "git log" "git diff" "git status"'
---

Someone commented on a pull request and the user wants to know what you make of it. Give a real opinion on whether the comment is right, grounded in the code rather than in the comment's own confidence.

Answering is the whole job. Never modify code, never commit, never post, reply, react, or resolve anything, and never draft a reply unless the user asks for one. Fixing the comment in code is a different task and is not this one.

## Which PR (resolve this yourself, never ask)

1. If a PR number or URL was given, use exactly that PR.
2. Otherwise use the current branch's PR: `gh pr view` with no argument targets it. If the branch has no open PR, say so and stop.

## Refresh first, every single time

Never answer from memory. Read the PR again at the start of every invocation, even when you already read it earlier in this session and nothing seems to have changed. The comment in question is often minutes old, so the state you remember is the state before it existed. Answering from memory produces a confident opinion about something the reviewer never said, which is worse than not answering at all.

Below, `<pr>` is the given number or URL (or empty for the current branch's PR); `<n>` is the PR number.

1. Take the current state and the user's own login, which later steps need:

```sh
gh pr view <pr> --json number,title,url,headRefOid,updatedAt
gh api user --template '{{.login}}'
```

2. Take every comment with its timestamp. Conversation comments, review summaries, and inline threads each hold points, and the one being asked about can be in any of them:

```sh
gh pr view <pr> --json comments --template '{{range .comments}}{{.createdAt}} {{.author.login}}: {{.body}}{{"\n"}}{{end}}'
gh pr view <pr> --json reviews --template '{{range .reviews}}{{.submittedAt}} {{.author.login}} [{{.state}}]: {{.body}}{{"\n"}}{{end}}'
gh api graphql -F owner='{owner}' -F name='{repo}' -F number=<n> -f query='
query($owner:String!,$name:String!,$number:Int!){
  repository(owner:$owner,name:$name){ pullRequest(number:$number){
    reviewThreads(first:100){nodes{ isResolved path line
      comments(first:50){nodes{ createdAt author{ login kind:__typename } body }}}}}}}' \
  --template '{{range .data.repository.pullRequest.reviewThreads.nodes}}{{.path}}:{{.line}} resolved={{.isResolved}}{{"\n"}}{{range .comments.nodes}}  {{.createdAt}} {{.author.login}} [{{.author.kind}}]: {{.body}}{{"\n"}}{{end}}{{"\n"}}{{end}}'
```

3. Take the commits, so a comment written before the last push can be recognised as already overtaken:

```sh
gh pr view <pr> --json commits --template '{{range .commits}}{{.committedDate}} {{.oid}} {{.messageHeadline}}{{"\n"}}{{end}}'
```

4. Read the code the comment is about, from the current head rather than from the diff alone:

```sh
gh pr diff <pr>
git fetch origin pull/<n>/head
git show FETCH_HEAD:<path>
```

When any of this contradicts what you believed earlier in the session, the fetch wins. Say in one line what moved, then answer against the new state.

## Work out which comment is meant

The user will rarely say. Resolve it yourself in this order, and never open by asking which comment they mean.

1. If they named an author, quoted a phrase, or pointed at a file, use that.
2. Otherwise take everything posted after the user's own last activity on the PR, meaning their last comment, their last reply, or their last push. That gap is what they have not engaged with, and it is what "what do you think" refers to.
3. If that turns up several comments, cover them all, most recent first. Do not make the user pick.
4. If it turns up nothing, say so plainly: nothing has arrived since their last activity. Name the most recent exchange and its timestamp so they can see what you did look at, then ask what they meant. Only a real fetch earns the right to say this, which is the reason for the previous section.

State in one line which comment you are answering on, so a wrong guess is visible immediately and costs one message.

## Judge it on the code

An opinion is worth something only when it survives the code. Before agreeing or disagreeing with anything:

1. Read the code the comment is about and confirm the comment describes it correctly. Reviewers misread diffs, and a confident tone is not evidence.
2. Check whether the point still stands against the current head. A comment written before the last push may already be handled, and saying so is often the entire answer.
3. Check the reasoning, not just the conclusion. A reviewer can be right that something is wrong and wrong about why, which changes what should be done about it.
4. Consider what the reviewer could not see: another part of the diff, a constraint elsewhere in the codebase, or a decision already settled earlier in the discussion.

## Say what you actually think

Hold an independent position. Two failure modes matter here, and they pull in opposite directions:

1. Do not side with the reviewer because a review comment sounds authoritative.
2. Do not side with the user because they are the one asking. Telling them their code is fine when it is not is the most expensive thing this skill can do.

Where you land is whatever the code supports. When the reviewer is right, say so first and plainly. When the user is right, say that just as plainly, and give them the argument they need.

Separate fact from taste, and label which one is in play. Many review comments are a preference stated as a correctness problem, and the user cannot answer well without knowing which they are facing. If it is a matter of fact, the code settles it. If it is a matter of taste, say so, give your preference, and say how much it is worth.

Then land on a recommendation: agree and change it, agree but not in this PR, or push back. When you recommend pushing back, give the reason that would convince the reviewer, not the reason that would comfort the user.

## Shape of the answer

Lead with the verdict in a sentence: the reviewer is right, partly right, or wrong. Then the evidence from the code, then the recommendation. Cite what you read as `path:line` so the user can check you.

Keep it short enough to read in one pass. Prose, no headers, no finding blocks; this is an answer in a conversation, not a report. Use more than a couple of paragraphs only when covering several comments, one short block each.

If the comment is genuinely ambiguous, say which reading you took and answer that one, rather than covering every reading.
