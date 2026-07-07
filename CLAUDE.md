# Global rules (apply to every project)

## Committing

Whenever instructed to commit changes, invoke the `commit` skill first and follow it. Do not commit ad hoc, even if you recall its rules — invoke the skill so its exact instructions are loaded fresh. (A PreToolUse hook also blocks `git commit` until the skill has been invoked in the current session, so if a commit is unexpectedly blocked, invoke the `commit` skill and retry.)

## Self-Documenting Code

Readable code supersedes static documentation, as the latter quickly becomes outdated. Never add comments that explain what the code does; instead, refactor the code to make its purpose clear. When writing, reviewing, or removing comments, apply the `comment-hygiene` skill: keep only comments carrying knowledge that can't be inferred from the code.

## Single Responsibility Principle

Each function or module should have one, and only one, reason to change. This enhances maintainability and testability.

## DRY Principle

Avoid code duplication by abstracting repeated logic into reusable functions or modules. No amount of code duplication is acceptable.
