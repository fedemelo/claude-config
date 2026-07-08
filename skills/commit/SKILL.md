---
name: commit
description: Commits staged or pending changes following personal conventions: modular commits, terse single-line messages, no AI attribution. Use when asked to commit.
---

When told to commit, do not change the code; only commit what is already there.

Commit only code changes. Never commit design files (any .md or .plan), environment files, or secrets.

Keep commits modular: one commit per separate change, ideally one per file. Group files into a single commit only when committing a file on its own would fail the commit pipeline, linting, or checks that would pass once its dependent files are included.

Never disable linting or any verification to make a commit pass. Never use the `--no-verify` flag.

Give each commit a single message: one succinct sentence that starts with an active verb and summarizes the change. No secondary body, no unnecessary adjectives. Prefer "Update AI agent to use new chunking utilities" over "Update AI agent to use new comprehensive chunking utilities".

When one file holds two or more unrelated changes, stage the parts separately with `git add -p` and commit each on its own, when that is possible and all checks still pass. Otherwise commit the whole file and join the sentences with `;`. Write "Add x" and "Implement y" as separate commits when you can, or "Add x; Implement y" in one when you cannot. Never "Add x and implement y".

Never list yourself or any AI model as author or co-author of a commit. The same holds for pull requests: never add any author, co-author, or contributor attribution in the title or body, and never include a "Generated with [tool]" footer or a "Co-Authored-By" line. The PR body describes only the change.
