# No space to open, so hand back the lines to paste

For any environment that is not a devspaces pod and has no `claude` CLI on `PATH`: Codex, or a cloud session without it. Reached from the [review-queue](../SKILL.md) skill, which decides that this is the right procedure.

`claude --bg` does not exist here, and there is no way to hand a cloud session a starting prompt. So open nothing. Print the list, then one line per PR for the user to paste into a space of their own:

```
/local-review https://github.com/<owner>/<repo>/pull/<n>
```

Say that is what happened and why. **Never review the PRs here instead**: several reviews in one context is the thing this skill is built to prevent, and it fails quietly, by writing each review in the shadow of the last one.

## The report

This path keeps its own, since the block format in the skill describes spaces and none were opened. Report the list as the command printed it, then the `/local-review` lines to paste. Nothing about any PR's contents: you have not read one.

## Reading spaces back

Nothing opens a space here, so there is none to skip and none to clean up. Say that the cleanup step does not apply rather than leaving it unmentioned.
