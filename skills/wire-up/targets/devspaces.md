# Wire up a devspaces pod

For an ephemeral, prompt-seeded devspaces workspace. Reached from the [wire-up](../SKILL.md) skill, which decides that this is the right procedure.

## Read this first

**Do not run `install.sh` from either repo, and do not run this skill's owned-machine procedure.** They are written for a host you administer and they actively break a pod:

- They **symlink** skills into `~/.claude/skills/`. Claude Code's skill discovery does not follow symlinks, so a symlinked skill is silently never loaded. It appears installed and does nothing. **Copy, never symlink.**
- claude-config's installer symlinks `CLAUDE.md`, installs `PreToolUse` hooks, and merges entries into `~/.claude/settings.json`. In a pod, team policy comes from `/etc/claude-code/managed-settings.json`, and repo-level `.claude/settings.json` files are deliberately pinned to `{}` by a background guard. Writing into that machinery is how you break a session, and one of the hooks blocks bare `git commit`, which pods need.
- git-tools' installer sets `core.hooksPath` **globally** and installs a `commit-msg` hook that strips `Co-Authored-By` trailers. See the conflict below; it is not a preference here.
- Both installers prune links pointing into their repo, so a re-run after a pod rebuild deletes what it cannot see.

Everything here is done by hand instead: clone to a scratch directory, copy the files, let one small script re-copy them on each start. It is a handful of `cp` commands, and the manual path is the supported one.

## Why the layout is what it is

`~/.claude` is **rebuilt from the pod image on every start**, so anything written there directly is gone in the next workspace. `/mnt/personal` is the per-user persistent share, mounted into every one of that user's workspaces and surviving rebuilds, stops and deletes. So the durable copy lives on the share, and the user's dotfiles `install.sh` copies it into `~` on every start.

Two tempting shortcuts that do not work:

- **Symlinking `~/.claude/skills` at the share** — skill discovery does not follow symlinks (upstream bug).
- **`CLAUDE_CONFIG_DIR`** — it relocates *all* of `~/.claude`, including `.credentials.json`, onto a shared mount.

Confine everything to the share and the user's home. **Never install any of this into a repository** — not `canals`, not any repo under `~/repositories`. These are one person's tools; a repo checkout is shared with the whole team, and their `.claude/` directories are managed by the pod image.

## Procedure

Paths below assume the standard `$HOME` and share; take the share root from the `/mnt/personal` the router already confirmed.

### 1. Clone the sources to scratch, read-only

```sh
git clone --depth=1 https://github.com/fedemelo/claude-config /tmp/claude-config-src
git clone --depth=1 https://github.com/fedemelo/git-tools    /tmp/git-tools-src
```

Scratch, not a permanent checkout, and nothing in them is executed. Delete both when finished so no one later mistakes them for an install.

### 2. Copy the skills

```sh
mkdir -p /mnt/personal/claude/skills
cp -a /tmp/claude-config-src/skills/<name> /mnt/personal/claude/skills/
```

One directory per skill, `cp -a` to keep the tree and modes. Copy every skill **except `wire-up` itself**: it exists to wire up a machine, its owned-machine procedure is the thing that must not run here, and a pod is refreshed by redoing this file rather than by invoking a skill. Leaving it out removes the footgun entirely.

The `agents/openai.yaml` beside each `SKILL.md` is Codex's copy of the invocation policy. Claude ignores it, and Codex reads `~/.agents/skills/`, which nothing here populates. Copy it anyway — it is two lines, it keeps the skill whole, and it costs nothing.

Skip `CLAUDE.md`, `hooks/` and `settings.json.example` from claude-config. Those are global-instruction and harness changes, not skills; see the conflicts below.

### 3. Copy the git tools

```sh
mkdir -p /mnt/personal/claude/git-tools/bin
cp -a /tmp/git-tools-src/bin/git-land            /mnt/personal/claude/git-tools/bin/
cp -a /tmp/git-tools-src/bin/git-todo            /mnt/personal/claude/git-tools/bin/
cp -a /tmp/git-tools-src/bin/git-review-feedback /mnt/personal/claude/git-tools/bin/
```

These three are standalone scripts with no install step. `~/.local/bin` is already on `PATH` in the pod image, and git resolves an executable named `git-<name>` there as the subcommand `git <name>`, so copying them is the whole installation — no config key, nothing to set. Keep the executable bit (`cp -a` does); a copy that loses it fails as "command not found".

Optionally also copy `hooks/commit-msg` and `ignore` onto the share for reference, but **do not wire either one** — each needs a global `git config` key, and the hook conflicts with pod policy. Leave `core.hooksPath` and `core.excludesFile` unset.

### 4. Ensure the dotfiles install script

The pod runs the first of `install.sh`, `bootstrap.sh`, `setup.sh` found **directly** in `/mnt/personal/dotfiles/` on every start. Discovery keys on the script, not the directory. If the user already has one, **add to it** rather than replacing it — it may carry shell config, gitconfig and more.

The three blocks this setup needs:

```bash
# Personal skills + slash commands: copy from the persistent share into
# ~/.claude on every start. Copy, don't symlink — Claude Code's skill and
# command discovery doesn't follow symlinks.
if [ -d /mnt/personal/claude/skills ]; then
  mkdir -p "$HOME/.claude/skills"
  cp -a /mnt/personal/claude/skills/. "$HOME/.claude/skills/"
fi

if [ -d /mnt/personal/claude/commands ]; then
  mkdir -p "$HOME/.claude/commands"
  cp -a /mnt/personal/claude/commands/. "$HOME/.claude/commands/"
fi

# git-tools subcommands (git land / git todo / git review-feedback), which the
# land, todo and PR-review skills call. ~/.local/bin is already on PATH and git
# finds a `git-<name>` executable there as the subcommand `git <name>`.
if [ -d /mnt/personal/claude/git-tools/bin ]; then
  mkdir -p "$HOME/.local/bin"
  cp -a /mnt/personal/claude/git-tools/bin/. "$HOME/.local/bin/"
fi
```

It runs on **every** start, so it has to stay idempotent: guard on the source directory, `mkdir -p`, `cp -a` over whatever is there. A failing install script does not block pod startup, so a broken one fails quietly — which is why step 6 verifies rather than trusts.

Note this copies in one direction, share to home. A skill edited in `~/.claude/skills/` is overwritten on the next start; the share is the source of truth.

### 5. Apply it

```sh
workspace-utils dotfiles
```

Same command the pod runs at startup, so no restart is needed. It reports `using local dotfiles in /mnt/personal/dotfiles` when it picks the script up; if it does not say that, the script is misnamed or not directly in that directory.

**Skills are loaded when a session starts, so newly copied ones are not callable in the session that copied them.** Say so rather than letting the user think it failed. Everything else, the git subcommands included, works immediately.

### 6. Verify, then clean up

Check, do not assume:

1. **No symlinks:** `find ~/.claude/skills -type l` prints nothing.
2. **Content matches:** `diff -r /tmp/claude-config-src/skills ~/.claude/skills` reports only the skills deliberately not copied.
3. **Frontmatter matches directory:** each `SKILL.md`'s `name:` equals its directory name, or Claude will not load it.
4. **References resolve:** every `[[name]]` in a copied skill names a skill that was also copied. Missing ones are dangling.
5. **Tools resolve:** `command -v git-land git-todo git-review-feedback`, then a real read, e.g. `git review-feedback <a recent PR number>` from a repo. `--help` through the `git` subcommand form hits a man-page error on the minimized pod image, which is git, not a broken tool; use `git-land --help` with the hyphen.
6. **Nothing leaked into a repo:** `git status --short` in each repo you touched is clean, and none of the skill names appear in any repo's `.claude/skills/`.

Then `rm -rf /tmp/claude-config-src /tmp/git-tools-src`.

## Conflicts to raise, not resolve

Both of these are real disagreements between the user's conventions and pod policy. Name them and let the user decide; do not quietly pick a side.

- **Commit attribution.** The `commit` skill forbids a `Co-Authored-By` trailer, and git-tools' `commit-msg` hook strips one. The pod's managed settings (`/etc/claude-code/managed-settings.json`, key `attribution.commit`) inject exactly that trailer, and organization policy requires it. Managed settings outrank a user-scope skill. Installing the hook would also rewrite commit messages in **every** repo in the pod, since `core.hooksPath` is global.
- **Repo-specific delivery skills.** A repo may mandate its own PR workflow — `canals` tells every agent to use `/canals:ship-it` — which overlaps `commit`, `open-pr` and `sync`. Both sets are installed; which wins is the user's call, per repo.

Also worth stating plainly: without git-tools, `land` and `todo` are inert and the four review skills (`local-review`, `address-review`, `second-opinion`, `verify-replies`) lose the `git review-feedback` read they are built on. The skills expect a hook to explain that; no hooks are installed here, so the failure is a raw `git: 'review-feedback' is not a git command`.

## Updating later

No symlinks means no automatic propagation. To pick up upstream changes, redo steps 1, 2, 3, then 5 — re-clone to scratch, copy over the changed skills, `workspace-utils dotfiles`, and start a fresh session. To edit a skill for yourself, edit it under `/mnt/personal/claude/skills/` and re-run `workspace-utils dotfiles`; the `~/.claude` copy is disposable.

## Report

Say which skills and tools were copied, that the dotfiles script was created or extended, what the verification showed, and that a new session is needed before the skills are callable. List the conflicts above last, as decisions waiting on the user.
