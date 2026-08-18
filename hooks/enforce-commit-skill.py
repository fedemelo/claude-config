#!/usr/bin/env python3
"""PreToolUse hook: require the `commit` skill to be invoked before `git commit`.

Reads the PreToolUse hook JSON from stdin. If the Bash command being run is a
`git commit`, checks this session's transcript for evidence that the `commit`
skill was already invoked. If not found, blocks the command and tells the model
to invoke the skill first.
"""

import json
import re
import sys

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
    if not COMMIT_COMMAND_RE.search(command):
        allow()
        return

    transcript_path = data.get("transcript_path")
    transcript_text = ""
    if transcript_path:
        try:
            with open(transcript_path, "r") as f:
                transcript_text = f.read()
        except OSError:
            transcript_text = ""

    if SKILL_INVOKED_RE.search(transcript_text):
        allow()
        return

    deny(
        "Blocked: you must invoke the `commit` skill before running `git commit`. "
        "Invoke the commit skill now, follow its instructions, then retry the commit."
    )


if __name__ == "__main__":
    main()
