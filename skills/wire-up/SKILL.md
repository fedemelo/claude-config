---
name: wire-up
description: Wires an environment's Claude and Codex setup up to date, following the procedure for the kind of environment it is run in. Detects whether this is a machine you own or an ephemeral devspaces pod, and follows only that procedure.
disable-model-invocation: true
---

Bring this environment's setup up to date: the skills, the hooks, `CLAUDE.md`, the settings entries, and the `git` subcommands the skills drive.

**How that is done depends on the environment, and the procedures are not interchangeable.** On a machine you own, the two repos install themselves through symlinks and their own installers. In an ephemeral pod there is no persistent `~`, symlinked skills silently fail to load, and running those installers damages a working setup. Applying the wrong one leaves an environment that looks installed and is not.

So this skill only routes. Work out which environment you are in, read the one file for it, and follow that file alone. Do not blend two procedures, and do not fall back on what you remember about the other.

## Pick the target

| Target | Procedure | It is this one when |
|---|---|---|
| A machine you own | `targets/owned-machine.md` | Your own laptop or desktop, or any host with a persistent home directory that you administer. |
| A devspaces pod | `targets/devspaces.md` | An ephemeral, prompt-seeded devspaces workspace. |

Detect it rather than asking, when the environment answers plainly. A devspaces pod has all of `/mnt/personal`, `/etc/claude-code/`, and a `devspaces` executable on `PATH`; any host with none of those is a machine you own.

If the signals disagree — some present, some not — that is a pod whose image has moved, or a host that resembles one. **Stop and ask the user which procedure to follow.** Do not guess: the cost of guessing wrong is a broken setup on a machine you cannot reset, and the question costs one round trip.

Nothing outside the chosen file applies. Read it in full before acting on any part of it, then report as it says.

If you cannot read files here (this skill was pasted as a prompt rather than loaded), say so and ask the user for the target file, naming the one you need. Do not reconstruct the procedure from memory.
