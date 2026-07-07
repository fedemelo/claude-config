---
name: commit
description: Commits staged/pending changes following personal conventions — modular commits, terse single-line messages, no AI attribution. Use when asked to commit.
---

When instructed to commit changes, do NOT change the code. Commit your changes.

Do NOT commit:
- Any .md or .plan files used for designing
- Any environment files or secrets

Only commit code changes.

Make commits modular; i.e., write a separate commit for separate changes. Ideally, make one commit per file. Do not make one commit per file if and only if the commit pipeline, linting or checks fail by including a standalone file but would pass if other dependent changes where included. In that case include the necessary files in a single commit.

NEVER disable linting or other verifications for commits to pass. Never use the --no-verify flag.

Each commit should have a single message, the main message, starting with an active verb and written as a single succinct sentence that summarizes the changes. No commit should have additional secondary long messages; only the title suffices for each. Each message should be short and to the point. Do not use unnecessary adjectives. E.g., prefer "Update AI agent to use new chunking utilities" over "Update AI agent to use new comprehensive chunking utilities".

If it happens that two or more semantically distinct or unrelated changes are done in a single file, try to commit each action individually by staging the file content by parts, using `git add -p`, if it is possible and all commit checks pass. If not, commit the whole file and separate the sentences by `;`. E.g.: Usually: "Add x" in one commit and "Implement y" in another; if needed: "Add x; Implement y". Never: "Add x and implement y"

NEVER add yourself as an author or co-author of the commit, or add any AI model as an author or co-author of the commit.

The same rule applies to pull requests: NEVER add yourself or any AI model as an author, co-author, or contributor in the PR title or body. Do NOT include any "Generated with [Claude Code]" / "Generated with [tool]" footer, "Co-Authored-By" line, or any equivalent attribution to an AI tool or assistant in the PR body. The PR body should only describe the change.
