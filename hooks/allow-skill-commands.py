#!/usr/bin/env python3
"""PreToolUse hook: auto-approve a fixed set of Bash commands.

Declared in a skill's frontmatter, so it is active only while that skill is in
use. Reads the PreToolUse hook JSON from stdin; the allowed command prefixes are
passed as arguments. If the Bash command consists solely of allowed commands
(every segment between shell operators starts with an allowed prefix, and the
command has no substitution or redirection), it returns permissionDecision
"allow" to skip the prompt. A `gh api` call is allowed only when it can read and
not write, so an allowed prefix like "gh api repos/" cannot be turned into a
write. Otherwise it stays silent, so the normal permission flow and any other
hooks still apply. It never denies.
"""

import json
import re
import sys

# Every separator Claude Code's own Bash permission matching recognises, so a command cannot
# smuggle a second one past a declared prefix. `&&` and `||` precede `&` and `|` in the
# alternation to be consumed first, and `|&` splits on both, leaving a harmless empty segment.
SEGMENT_SPLIT_RE = re.compile(r"&&|\|\||;|\||&|\n")
DANGEROUS_RE = re.compile(r"`|\$\(|>|<")
GH_API_RE = re.compile(r"gh api\b")
GRAPHQL_RE = re.compile(r"gh api graphql\b")
METHOD_FLAG_RE = re.compile(r"(?<![\w-])(-X|--method)")
BODY_FLAG_RE = re.compile(r"(?<![\w-])(-f|-F|--field|--raw-field|--input)")
MUTATION_RE = re.compile(r"\bmutation\b")


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


def reads_only(seg):
    """Whether a `gh api` call can only read.

    `gh api` sends POST as soon as any field is passed, so an unwritten method
    proves nothing on its own and the call counts as a read only when it carries
    no body either. GraphQL is the exception, since it needs fields to carry its
    query, so there the query itself has to be a query and not a mutation.
    """
    if METHOD_FLAG_RE.search(seg):
        return False
    if GRAPHQL_RE.match(seg):
        return not MUTATION_RE.search(seg)
    return not BODY_FLAG_RE.search(seg)


def prefix_matches(seg, prefix):
    """Whether a segment starts with an allowed prefix.

    A prefix normally has to end on a space, so "git st" never stands in for
    "git status". One ending in "/" is a path prefix instead, since an API path is
    a single token and could not be matched on a space boundary at all.
    """
    if seg == prefix:
        return True
    if prefix.endswith("/"):
        return seg.startswith(prefix)
    return seg.startswith(prefix + " ")


def segment_allowed(segment, prefixes):
    seg = normalize(segment)
    if not seg:
        return True
    if not any(prefix_matches(seg, p) for p in prefixes):
        return False
    return reads_only(seg) if GH_API_RE.match(seg) else True


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
