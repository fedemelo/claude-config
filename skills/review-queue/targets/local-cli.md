# A background session per PR

For any environment that is not a devspaces pod and has the `claude` CLI on `PATH`. Reached from the [review-queue](../SKILL.md) skill, which decides that this is the right procedure. Everything that skill says still holds; this file only says what a space is here and how to open one.

One background session each:

```sh
claude --bg -n "review-<n>" --permission-mode auto "/local-review <url>"
```

- `--bg` returns immediately with a short id, so opening eight of these costs eight lines here and nothing else. The session inherits this working directory, so it starts in the right repo.
- `--permission-mode auto` because a background session in manual mode stalls on its first `gh` call, waiting for someone to switch to it and approve.

If the CLI will not open a session, that is the end of this path. Stop and report it. No reviews here instead.

## Reading spaces back

`claude agents --json --all` is where the skip check and the cleanup step read the sessions. Hand back the line to delete one, and never run it yourself:

```sh
claude rm <id>
```

In the report, "how to reach it" is `claude attach <id>`, with the short id `claude --bg` returned.
