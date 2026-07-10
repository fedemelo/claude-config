# claude-config

Global Claude Code setup: opinionated skills, the instructions they follow, and the hooks that enforce them.

## Why this repo

1. Zero-effort install
2. Single source of truth
3. Opinionated skills
4. Scripts and guardrails

How so?

1. `./install.sh` wires every skill, hook, and `CLAUDE.md` into `~/.claude/`. No copying files around or per-machine fiddling.
2. `./install.sh` symlinks the repo files into `~/.claude/` rather than copying them. Editing a skill here edits the live one Claude uses, so there is no second copy to drift or go stale.
3. These are not restatements of Claude's built-ins. They encode specific conventions that actually save humans (not AI) time. See the [skills](#skills) section.
4. Some skills drive fast `git` subcommands (from [git-tools](https://github.com/fedemelo/git-tools)) instead of long `gh` incantations, and `PreToolUse` hooks block the raw commands until the matching skill is loaded, so the conventions can't be silently skipped.

## Install

```sh
git clone <this-repo-url>
cd claude-config
./install.sh
```

It symlinks `CLAUDE.md`, `hooks/`, and `skills/` into `~/.claude/`, then merges the `PreToolUse` hook entries into `~/.claude/settings.json` without disturbing your existing settings. **Re-run it any time you add a skill**.

The `land` and `todo` skills call the `git-land` / `git-todo` executables from [git-tools](https://github.com/fedemelo/git-tools); install that repo too, or those two skills stay inert.

## Skills

Each links to its full definition. The one-liner here is why it's useful and how it differs from what Claude does by default.

- **[commit](skills/commit/SKILL.md)** — enforces one commit per file, a single terse imperative message, and zero AI attribution. Unlike Claude's default committing it won't write paragraphs or slip in a `Co-Authored-By` trailer, and a hook blocks `git commit` until it's loaded.
- **[open-pr](skills/open-pr/SKILL.md)** — puts up a clean PR end to end: branches off the latest default branch (not whatever you're sitting on), commits via the commit skill, assigns you, and writes the description to a strict standard. More than `gh pr create`: it gets the branching, hygiene, and description right.
- **[local-review](skills/local-review/SKILL.md)** — a staff-engineer PR review delivered in the session and never posted. Unlike the native `/review` and `/code-review`, it is strictly read-only, uses a fixed comment format with an APPROVE / COMMENT / REQUEST CHANGES verdict whose meanings are defined, and can verify a PR actually fixes a given ticket.
- **[address-review](skills/address-review/SKILL.md)** — works through the review comments on a PR, fixes the real ones and drafts replies to the rest, without ever posting. No native equivalent: it auto-detects human vs bot comments, stays read-only toward the PR, and hands everything back to you to publish.
- **[land](skills/land/SKILL.md)** — ships committed work with a single `git land` instead of a manual `gh pr create`/`merge` dance. Wraps the commits in a disposable, auto-merged PR so solo work lands with a paper trail and no ceremony.
- **[todo](skills/todo/SKILL.md)** — files a GitHub issue with `git todo`, auto-assigned to you with the right defaults, instead of recalling `gh issue create` flags.
- **[comment-hygiene](skills/comment-hygiene/SKILL.md)** — the shared rule for which comments are worth keeping (only what the code can't say itself). Used alone to strip noise, and referenced by the review skills and `CLAUDE.md`.
- **[pr-description](skills/pr-description/SKILL.md)** — the shared standard for PR descriptions: at most two short paragraphs, no formatting, no fluff. Used by open-pr and applied when local-review judges a description.

## Also included

- **`CLAUDE.md`** — global rules applied to every project: commit discipline, self-documenting code, single responsibility, DRY.
- **`hooks/`** — three `PreToolUse` hooks. One blocks `git commit` until the commit skill has been invoked this session; one blocks `git land` / `git todo` until the git-tools executables are installed; and one, declared in each command-running skill's frontmatter and active only while that skill is in use, auto-approves the specific commands that skill needs so they don't trigger a permission prompt.
