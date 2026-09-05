#!/usr/bin/env python3
"""PreToolUse hook: require the `commit` skill to be invoked before `git commit`.

If the Bash command being run is a `git commit`, checks this session's transcript for evidence
that the `commit` skill was already invoked. If not found, blocks the command and tells the
model to invoke the skill first.
"""

import re

from _pretooluse import guard_bash


COMMIT_COMMAND_RE = re.compile(r"(^|;|&&|\|\||\|)\s*git\s+commit(\s|$)")

# Installed as a plugin, the skill is namespaced as <plugin>:commit everywhere below.
SKILL_NAME = r"(?:[\w-]+:)?commit"

# The two ways the skill gets loaded leave different traces. Claude invoking it leaves a
# Skill tool call; the user typing /commit leaves none, since the CLI expands the skill
# itself and only records the command name.
SKILL_INVOKED_RE = re.compile(
    r'"name"\s*:\s*"Skill".{0,200}?"skill"\s*:\s*"' + SKILL_NAME + r'"'
    r"|<command-name>/" + SKILL_NAME + r"</command-name>"
)


def transcript_of(payload):
    path = payload.get("transcript_path")
    if not path:
        return ""
    try:
        with open(path) as f:
            return f.read()
    except OSError:
        return ""


def veto(command, payload):
    if not COMMIT_COMMAND_RE.search(command):
        return None
    if SKILL_INVOKED_RE.search(transcript_of(payload)):
        return None
    return (
        "Blocked: you must invoke the `commit` skill before running `git commit`. "
        "Invoke the commit skill now, follow its instructions, then retry the commit."
    )


if __name__ == "__main__":
    guard_bash(veto)
