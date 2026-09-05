# claude-config

> **New machine, or after any pull:** `git pull && ./install.sh` in [git-tools](https://github.com/fedemelo/git-tools) first, then the same here. Editing a skill takes effect immediately through the symlinks, but adding or removing one does not.

Global setup for Claude Code and Codex: opinionated skills, the instructions they follow, and the hooks that enforce them.

## Why this repo

1. Zero-effort install
2. Single source of truth
3. Opinionated skills
4. Scripts and guardrails

How so?

1. `./install.sh` wires every skill, hook, and `CLAUDE.md` into place. No copying files around or per-machine fiddling.
2. `./install.sh` symlinks the repo files rather than copying them. Editing a skill here edits the live one the agent uses, so there is no second copy to drift or go stale. A skill is also written once for [both runtimes](#both-runtimes) rather than once each.
3. These are not restatements of what the agent already does. They encode specific conventions that actually save humans (not AI) time. See the [skills](#skills) section.
4. Some skills drive fast `git` subcommands (from [git-tools](https://github.com/fedemelo/git-tools)) instead of long `gh` incantations, and `PreToolUse` hooks block the raw commands until the matching skill is loaded, so the conventions can't be silently skipped.

## Prerequisites

- The [`gh` CLI](https://cli.github.com), authenticated with `gh auth login`. Most skills drive `gh`, and nothing here checks for it, so without it they fail at first use with a bare `gh: command not found`.
- `python3`, which the hooks and the settings merge run on.
- [git-tools](https://github.com/fedemelo/git-tools), or the `land` and `todo` skills stay inert, since they call its `git-land` / `git-todo` executables. Install it first and follow its `~/.gitconfig` step: a fresh machine has no `user.email`, and every commit fails until that is filled in.

## Install

```sh
git clone <this-repo-url>
cd claude-config
./install.sh
```

It symlinks `CLAUDE.md` and `hooks/` into `~/.claude/`, links every skill into both `~/.claude/skills/` and `~/.agents/skills/`, then merges the `PreToolUse` hook entries into `~/.claude/settings.json` without disturbing your existing settings. A `CLAUDE.md` you wrote yourself is moved to `CLAUDE.md.pre-claude-config` rather than overwritten, and hook entries are matched by script, so a changed command updates in place instead of leaving the old one alongside it.

**Re-run it after every pull.** Editing a skill takes effect immediately, since the installed paths are symlinks, but a skill *added* upstream has no link until you re-run, and one renamed or removed upstream leaves a link pointing nowhere. Re-running creates the first and prunes the second, reporting whatever it changed.

## Both runtimes

Claude Code reads `~/.claude/skills/`; Codex reads `~/.agents/skills/`, as do Copilot and OpenCode. Both get a link to the same directory in this repo, so a skill is written once and there is still only one copy of it.

What differs between the runtimes is not the skill but who may start it. Claude reads `disable-model-invocation` from the `SKILL.md` frontmatter. Codex ignores that key entirely and reads `policy.allow_implicit_invocation` from a five-line `agents/openai.yaml` beside it, which Claude in turn ignores. So each skill states the same policy twice, once per runtime, and nothing has to be duplicated except those two lines:

```
skills/land/
├── SKILL.md            # disable-model-invocation: true
└── agents/openai.yaml  # policy.allow_implicit_invocation: false
```

Two files can disagree, so the [validator](#also-included) fails the build unless they say the same thing and say what `explicit-only-skills.txt` says.

Most skills can be started by the agent on its own. These four cannot, and you have to type the command, because each changes something outside the working tree:

| Skill | Claude Code | Codex |
|---|---|---|
| [address-review](skills/address-review/SKILL.md) | `/address-review` | `$address-review` |
| [land](skills/land/SKILL.md) | `/land` | `$land` |
| [open-pr](skills/open-pr/SKILL.md) | `/open-pr` | `$open-pr` |
| [todo](skills/todo/SKILL.md) | `/todo` | `$todo` |

`commit` is deliberately not among them. Its hook blocks `git commit` itself, which is stronger than blocking the skill that wraps it, and making it explicit-only would stop `open-pr` and `address-review` from following it as a step.

The hooks and the `disallowed-tools` restrictions are Claude Code features with no Codex equivalent, so under Codex the read-only skills are held to their own wording rather than to the harness.

## Tests

```sh
tests/install.test.sh
tests/enforce-commit-skill.test.sh
tests/require-git-land-todo-tools.test.sh
tests/copy-prompt.test.sh
tests/validate-skills.test.sh
```

No dependencies and no network. Every install case runs against a throwaway `HOME`, so the suite never touches your real `~/.claude`; the hook cases only feed the hook a payload on stdin, plus a throwaway transcript where the hook reads one, and read its answer; and every validator case breaks one thing in a throwaway copy of the repo, so the copy it checks is never the one you are working in.

The validator itself runs on its own, and is worth running after changing how a skill is packaged rather than waiting for CI:

```sh
python3 scripts/validate_skills.py
```

## Using a skill somewhere that cannot load one

Claude Code and Codex both load these skills. Other tools cannot, and the only way to use one there is to paste it as a prompt. `make <skill>` puts it on the clipboard for you:

```sh
make local-review
# Copied to clipboard: local-review, comment-hygiene, plain-english
make list          # the skills you can copy
```

What lands on the clipboard is the skill's content without its frontmatter, headed by a title and wrapped in `"""`, followed by whatever it references in the same shape.

A reference travels with the prompt when the task cannot be done without it, and it travels all the way down. That covers the standards it has to obey while writing its output, and the odd skill whose procedure is the body of the work rather than a step beside it, as work-summary is inside daily-update.

A skill it merely names, like commit, is followed as its own step, so pasting it would bury the task in instructions for a different one. Those are listed in a closing block instead, which tells the model why the reference is there, why the text is not, and to ask you for it if the work reaches it.

## Skills

Each links to its full definition. The one-liner here is why it's useful and how it differs from what Claude does by default.

- **[commit](skills/commit/SKILL.md)** — enforces one commit per file, a single terse imperative message, and zero AI attribution. Unlike Claude's default committing it won't write paragraphs or slip in a `Co-Authored-By` trailer, and a hook blocks `git commit` until it's loaded.
- **[open-pr](skills/open-pr/SKILL.md)** — puts up a clean PR end to end: branches off the latest default branch (not whatever you're sitting on), commits via the commit skill, assigns you, and writes the description to a strict standard. More than `gh pr create`: it gets the branching, hygiene, and description right.
- **[local-review](skills/local-review/SKILL.md)** — a staff-engineer PR review delivered in the session and never posted. Unlike the native `/review` and `/code-review`, it is strictly read-only, sorts findings into five categories with a test for every boundary, ties the APPROVE / COMMENT / REQUEST CHANGES verdict to them, and can verify a PR actually fixes a given ticket. Each finding is split in two: a long *reasoning* that proves it to you, and a short *comment* you can post as written.
- **[address-review](skills/address-review/SKILL.md)** — works through the review comments on a PR, fixes the real ones and drafts replies to the rest, without ever posting. No native equivalent: it reads review threads over GraphQL so it can skip the ones already resolved, tells humans from bots by their actual account type rather than by guessing at logins, stays read-only toward the PR, and hands everything back to you to publish.
- **[second-opinion](skills/second-opinion/SKILL.md)** — asks what you make of a comment someone left on a PR, and answers with an opinion the code backs. Refetches every time instead of trusting what it read ten minutes ago, works out which comment you mean from what landed since you last touched the PR, and takes a side on the merits rather than siding with whoever is in the room.
- **[verify-replies](skills/verify-replies/SKILL.md)** — audits a PR discussion after you have posted your replies: checks every claim in them against the code and finds points nobody ever answered. No native equivalent, and the opposite direction from a review: it reviews the conversation rather than the diff, reads resolved threads too (resolving proves nothing), and flags without touching code, comments, or reactions.
- **[land](skills/land/SKILL.md)** — ships committed work with a single `git land` instead of a manual `gh pr create`/`merge` dance. Wraps the commits in a disposable, auto-merged PR so solo work lands with a paper trail and no ceremony, and can split a stack into several PRs (`--until`) or one PR per commit (`--each`).
- **[todo](skills/todo/SKILL.md)** — files a GitHub issue with `git todo`, auto-assigned to you with the right defaults, instead of recalling `gh issue create` flags.
- **[work-summary](skills/work-summary/SKILL.md)** — recaps your own PR activity in the current repo from a cutoff date to now, split into still open, merged, and closed without merging. Each PR gets a line saying what it actually does, plus review and CI state for the open ones and the stated closing reason (never a guessed one) for the closed ones.
- **[daily-update](skills/daily-update/SKILL.md)** — turns that same PR activity into the update you post to your team. Not a recap: it regroups the PRs into the two or three initiatives they belong to, drops the chores nobody gains from reading about, and hyperlinks a single word per PR inside the sentence. The rules for what belongs in such an update are external, so they are quoted in the skill rather than paraphrased, examples included.
- **[comment-hygiene](skills/comment-hygiene/SKILL.md)** — the shared rule for which comments are worth keeping (only what the code can't say itself). Used alone to strip noise, and referenced by the review skills and `CLAUDE.md`.
- **[pr-description](skills/pr-description/SKILL.md)** — the shared standard for PR descriptions: at most two short paragraphs, no formatting, no fluff. Used by open-pr when writing one.
- **[plain-english](skills/plain-english/SKILL.md)** — the shared standard for anything another person reads: B2-level English, technical terms allowed but metaphors and corporate fluff banned, no chains of function names, nothing that reads as AI-written. Referenced by local-review, address-review, and pr-description, so their output is postable as is instead of needing a rewrite first.

## Also included

- **`CLAUDE.md`** — global rules applied to every project: commit discipline, self-documenting code, single responsibility, DRY.
- **`hooks/`** — two `PreToolUse` hooks. One blocks `git commit` until the commit skill has been invoked this session; the other blocks `git land` / `git todo` until the git-tools executables are installed. Both encode a condition no permission rule can express, which is why they are hooks: one reads the session's history, the other the filesystem.
- **`settings.json.example`** — merged into `~/.claude/settings.json` on install, adding the hooks above without disturbing settings of your own. It grants no pre-approved commands: in auto mode the classifier reviews what the rules do not settle, and an allow rule would take those commands out of that review.
- **`scripts/validate_skills.py`** — fails CI when the packaging stops matching the skills. It holds both runtimes to one invocation policy, checks a skill's frontmatter names its own directory, checks every `[[reference]]` points at a skill that exists, and checks `copy_prompt.py` can title every skill, which otherwise only surfaces when `make <skill>` exits with an error. It parses YAML itself rather than pulling in PyYAML, so the repo and its tests stay dependency-free; the parser rejects duplicate keys and anything outside the small subset written here instead of guessing.
- **`explicit-only-skills.txt`** — the four skills you have to start yourself, listed once for [both runtimes](#both-runtimes) so the policy is reviewed in one place rather than inferred from two frontmatter keys.
- **`.claude-plugin/`, `.codex-plugin/`, `.agents/plugins/`** — manifests that let someone else install this repo as a plugin in either runtime. They are not how it is installed here, and deliberately so: a plugin install copies the tree and pins it to a commit, so it goes stale until someone remembers to update it, which is the drift the symlinks exist to avoid. The validator keeps them truthful anyway, since metadata nothing exercises is metadata that rots.
- **`ruff.toml`** — line length 120, `py312`, isort. CI checks formatting and lint on a pinned ruff.
