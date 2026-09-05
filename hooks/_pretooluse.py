"""The plumbing every `PreToolUse` hook here shares: read the payload, answer the harness.

Imported, never run, so it carries no shebang and is not executable. A hook imports it as a
sibling module, which resolves because Python sets `sys.path[0]` to the directory the script
really lives in rather than the one it was invoked through: the symlink in ~/.claude/hooks
reaches back into this repo, so the module can never be a stale copy of itself.
"""

import json
import sys


def guard_bash(veto):
    """Let `veto` decide whether to block the Bash command in the payload on stdin.

    `veto(command, payload)` returns the reason to block, or None to stay out of the way. Both
    are reported the way the harness expects: a reason as a deny decision plus a message the
    user sees, and None as an empty object, which leaves the command to the normal permission
    rules rather than approving it.

    Anything that is not a Bash call, and any payload that will not parse, is left alone. A hook
    that cannot read its own input must not be the reason a command fails.
    """
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        payload = {}

    reason = None
    if isinstance(payload, dict) and payload.get("tool_name") == "Bash":
        tool_input = payload.get("tool_input")
        command = tool_input.get("command", "") if isinstance(tool_input, dict) else ""
        reason = veto(command, payload)

    print(json.dumps(_decision(reason) if reason else {}))
    sys.exit(0)


def _decision(reason):
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        },
        "systemMessage": reason,
    }
