#!/usr/bin/env python3
"""PreToolUse hook: require a git-tools subcommand to exist before running it.

If the Bash command invokes one of them, checks that the corresponding executable is actually
on PATH. If not, blocks the command and tells the model the tool is missing rather than letting
it fall back to manually replicating the behavior with raw `gh`/git commands. That fallback is
the real risk: for `git review-feedback` it means reading some of a PR's review feedback and
believing that was all of it, which is the reason the skills name the tool and nothing else.
"""

import re
import shutil

from _pretooluse import guard_bash


TOOLS = ("land", "todo", "review-feedback")

SUBCOMMAND_RES = {tool: re.compile(rf"(^|;|&&|\|\||\|)\s*git\s+{tool}(\s|$)") for tool in TOOLS}


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
