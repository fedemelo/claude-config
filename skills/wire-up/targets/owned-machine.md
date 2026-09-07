# Wire up a machine you own

For a host with a persistent home directory that you administer: your laptop, your desktop. Reached from the [wire-up](../SKILL.md) skill, which decides that this is the right procedure. Do not follow it in a devspaces pod; that has its own file beside this one.

Two repos hold everything, and each installs itself. Your job is to find them, pull them, run their installers, and check the few things the installers deliberately leave to a human. Never wire anything by hand: the links, `~/.claude/settings.json` and `core.hooksPath` belong to the installers, which are idempotent and verify their own work, so a second copy of that logic here would drift from the one that runs everywhere else.

## Find the repos

- **claude-config** — `dirname "$(readlink ~/.claude/CLAUDE.md)"`. If that link is missing, the repo is the one this skill was loaded from.
- **git-tools** — `dirname "$(dirname "$(readlink "$(command -v git-land)")")"`, else `~/git-tools`. If it is nowhere, clone `https://github.com/fedemelo/git-tools` beside claude-config: without it the `land`, `todo` and PR-review skills are inert, and a hook blocks their commands.

## Update each

git-tools first, then claude-config, because the skills over there call flags that only a current `git-land` has.

```sh
git -C <repo> pull --ff-only && <repo>/install.sh
```

`--ff-only` on purpose: a dirty tree, a branch that has diverged, or local commits mean someone was working in that repo, and a merge or rebase to get the pull through is a decision that is not yours. Stop, name the repo and what you found, and leave it untouched.

If an installer exits non-zero, report its output as it stands and stop. Both fail loudly at the one thing they cannot verify silently — a `commit-msg` hook that is not stripping trailers, a `settings.json` that no longer parses or names a hook that is not installed — and working around that leaves a setup that looks installed and is not.

## Claim a global-instructions slot the installer declined

Global instructions live at `~/.claude/CLAUDE.md` for Claude Code and `~/.codex/AGENTS.md` for Codex, and the installer links both at this repo's `CLAUDE.md`. It refuses one case: a slot that is already a symlink to something else. It reports that as `Left <file> alone: it is a symlink to <target>`, and the runtime then reads those other instructions instead of this repo's.

On a machine you own, finish the job rather than leaving it to the user. For each slot the installer left:

1. Read the target. If it is this repo's `CLAUDE.md` by another path, relink the slot at the canonical path and say so; there is nothing to preserve.
2. If it holds instructions of the user's own, move the target aside to `<name>.pre-claude-config` beside itself, relink the slot, and tell the user where their file went and what was in it. Never delete it, and never merge it into this repo's `CLAUDE.md`.
3. If the target is owned by something else — outside `$HOME`, not writable by the user, or provisioned by an environment that manages the machine — **stop and leave it.** Name the slot, the target, and that the runtime is reading those instructions instead. This is the case the installer is protecting, and taking the slot over would swap out instructions the user never asked to lose. A slot that is recreated on every boot would also revert, so a link made here would go stale without any error.

## Check what the installers leave out

Each of these fails at first use rather than at install time, so check all four and report them together:

1. `~/.local/bin` is on `PATH`, via `command -v git-land git-todo git-review-feedback`. If the files exist but the commands do not resolve, give the user the line to add to their shell rc and ask before editing it yourself.
2. `git config --global user.email` is set. A fresh machine has none and every commit fails. Point at git-tools' `gitconfig.example` and let the user fill in their name, email and signing key. Never guess any of the three.
3. `gh auth status` succeeds. Almost every skill drives `gh`.
4. Every skill in `<claude-config>/skills/` is linked in both `~/.claude/skills/` and `~/.agents/skills/`. A skill added upstream only appears once the installer has run, which is the whole reason this skill exists: editing a skill takes effect immediately through the symlinks, adding or removing one does not.
5. Both global-instruction slots point at this repo's `CLAUDE.md`, per the section above. A slot reading someone else's instructions is the one failure here that looks like nothing is wrong.

## Report

Say what each repo pulled or that it was already current, what the installers changed — new links, pruned links, settings merged — and, last, whatever the user still has to do themselves. If nothing changed and all four checks pass, say that in one line.
