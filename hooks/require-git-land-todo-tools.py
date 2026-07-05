#!/usr/bin/env python3
"""PreToolUse hook: require git-land / git-todo to exist before running them.

Reads the PreToolUse hook JSON from stdin. If the Bash command invokes
`git land` or `git todo`, checks (via shutil.which) that the corresponding
git-land / git-todo executable is actually on PATH. If not, blocks the
command and tells the model the tool is missing rather than letting it
fall back to manually replicating the behavior with raw `gh`/git commands.
"""

import json
import re
import shutil
import sys

GIT_LAND_RE = re.compile(r"(^|;|&&|\|\||\|)\s*git\s+land(\s|$)")
GIT_TODO_RE = re.compile(r"(^|;|&&|\|\||\|)\s*git\s+todo(\s|$)")


def allow():
    print(json.dumps({}))
    sys.exit(0)


def deny(reason):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        },
        "systemMessage": reason,
    }))
    sys.exit(0)


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        allow()
        return

    if data.get("tool_name") != "Bash":
        allow()
        return

    command = data.get("tool_input", {}).get("command", "")

    if GIT_LAND_RE.search(command) and shutil.which("git-land") is None:
        deny(
            "Blocked: 'git-land' is not installed on this machine (not found on PATH). "
            "Reinstall it at ~/.local/bin/git-land before retrying."
        )
        return

    if GIT_TODO_RE.search(command) and shutil.which("git-todo") is None:
        deny(
            "Blocked: 'git-todo' is not installed on this machine (not found on PATH). "
            "Reinstall it at ~/.local/bin/git-todo before retrying."
        )
        return

    allow()


if __name__ == "__main__":
    main()
