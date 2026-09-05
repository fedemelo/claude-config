#!/usr/bin/env python3
"""PreToolUse hook: require git-land / git-todo to exist before running them.

If the Bash command invokes `git land` or `git todo`, checks that the corresponding executable
is actually on PATH. If not, blocks the command and tells the model the tool is missing rather
than letting it fall back to manually replicating the behavior with raw `gh`/git commands.
"""

import re
import shutil

from _pretooluse import guard_bash


SUBCOMMAND_RES = {tool: re.compile(rf"(^|;|&&|\|\||\|)\s*git\s+{tool}(\s|$)") for tool in ("land", "todo")}


def veto(command, _payload):
    for tool, pattern in SUBCOMMAND_RES.items():
        executable = f"git-{tool}"
        if pattern.search(command) and shutil.which(executable) is None:
            return (
                f"Blocked: '{executable}' is not installed on this machine (not found on PATH). "
                f"Reinstall it at ~/.local/bin/{executable} before retrying."
            )
    return None


if __name__ == "__main__":
    guard_bash(veto)
