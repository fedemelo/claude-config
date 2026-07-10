#!/usr/bin/env python3
"""PreToolUse hook: auto-approve a fixed set of Bash commands.

Declared in a skill's frontmatter, so it is active only while that skill is in
use. Reads the PreToolUse hook JSON from stdin; the allowed command prefixes are
passed as arguments. If the Bash command consists solely of allowed commands
(every segment between shell operators starts with an allowed prefix, and the
command has no substitution or redirection), it returns permissionDecision
"allow" to skip the prompt. Otherwise it stays silent, so the normal permission
flow and any other hooks still apply. It never denies.
"""

import json
import re
import sys

SEGMENT_SPLIT_RE = re.compile(r"&&|\|\||;|\||\n")
DANGEROUS_RE = re.compile(r"`|\$\(|>|<")


def silent():
    print(json.dumps({}))
    sys.exit(0)


def allow():
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "permissionDecisionReason": "Command permitted by the active skill.",
        }
    }))
    sys.exit(0)


def normalize(text):
    return " ".join(text.split())


def segment_allowed(segment, prefixes):
    seg = normalize(segment)
    if not seg:
        return True
    return any(seg == p or seg.startswith(p + " ") for p in prefixes)


def main():
    prefixes = [normalize(p) for p in sys.argv[1:] if p.strip()]
    if not prefixes:
        silent()

    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        silent()

    if data.get("tool_name") != "Bash":
        silent()

    command = data.get("tool_input", {}).get("command", "")
    if not command.strip() or DANGEROUS_RE.search(command):
        silent()

    if all(segment_allowed(seg, prefixes) for seg in SEGMENT_SPLIT_RE.split(command)):
        allow()
    silent()


if __name__ == "__main__":
    main()
