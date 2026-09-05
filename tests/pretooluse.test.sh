#!/usr/bin/env bash
# Tests _pretooluse.py, the plumbing both PreToolUse hooks share. Each case drives it through a
# throwaway probe hook whose veto is spelled out by the case itself, so the shared behaviour is
# checked once here rather than twice through the two real hooks.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
probe="$(mktemp -d)/probe.py"
trap 'rm -rf "$(dirname "$probe")"' EXIT

pass=0; fail=0

check() {
  if [ "$2" = "$3" ]; then printf '  PASS %s\n' "$1"; pass=$((pass+1))
  else printf '  FAIL %s\n       got:  %s\n       want: %s\n' "$1" "$2" "$3"; fail=$((fail+1)); fi
}

# A probe that blocks any command holding "boom", and records what the veto was handed.
cat > "$probe" <<'PY'
import sys

from _pretooluse import guard_bash


def veto(command, payload):
    print(f"veto saw command={command!r} keys={sorted(payload)}", file=sys.stderr)
    return f"blocked: {command}" if "boom" in command else None


guard_bash(veto)
PY

# The hook's answer on stdout, with PYTHONPATH standing in for the sibling import.
run() { printf '%s' "$1" | PYTHONPATH="$repo_root/hooks" python3 "$probe" 2>/dev/null; }

# What the veto was handed, or nothing when it was never called.
veto_saw() { printf '%s' "$1" | PYTHONPATH="$repo_root/hooks" python3 "$probe" 2>&1 >/dev/null; }

exit_code() { printf '%s' "$1" | PYTHONPATH="$repo_root/hooks" python3 "$probe" >/dev/null 2>&1; echo $?; }

bash_payload='{"tool_name":"Bash","tool_input":{"command":"boom"}}'

echo "=== a veto returning nothing leaves the command to the normal permission rules ==="
check "an allowed command answers with an empty object" \
  "$(run '{"tool_name":"Bash","tool_input":{"command":"ls"}}')" "{}"
check "and not with an approve decision" \
  "$(run '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | grep -c 'permissionDecision')" "0"

echo "=== a veto returning a reason blocks, and says so twice ==="
check "the decision is a deny" \
  "$(run "$bash_payload" | python3 -c 'import json,sys; print(json.load(sys.stdin)["hookSpecificOutput"]["permissionDecision"])')" \
  "deny"
check "the event name is reported back" \
  "$(run "$bash_payload" | python3 -c 'import json,sys; print(json.load(sys.stdin)["hookSpecificOutput"]["hookEventName"])')" \
  "PreToolUse"
check "the reason reaches the model" \
  "$(run "$bash_payload" | python3 -c 'import json,sys; print(json.load(sys.stdin)["hookSpecificOutput"]["permissionDecisionReason"])')" \
  "blocked: boom"
check "and the user sees the same text" \
  "$(run "$bash_payload" | python3 -c 'import json,sys; print(json.load(sys.stdin)["systemMessage"])')" \
  "blocked: boom"

echo "=== anything that is not a Bash call never reaches the veto ==="
check "another tool is allowed" "$(run '{"tool_name":"Edit","tool_input":{"command":"boom"}}')" "{}"
check "and the veto is not called" "$(veto_saw '{"tool_name":"Edit","tool_input":{"command":"boom"}}')" ""
check "a payload with no tool_name is allowed" "$(run '{"tool_input":{"command":"boom"}}')" "{}"

echo "=== a payload the hook cannot read is left alone rather than failing the command ==="
check "unparseable JSON is allowed" "$(run 'not json at all')" "{}"
check "and the veto is not called" "$(veto_saw 'not json at all')" ""
check "empty input is allowed" "$(run '')" "{}"
check "valid JSON that is not an object is allowed" "$(run '["boom"]')" "{}"
check "a bare JSON string is allowed" "$(run '"boom"')" "{}"

echo "=== a Bash call with no readable command reaches the veto with an empty one ==="
check "a missing tool_input gives an empty command" \
  "$(veto_saw '{"tool_name":"Bash"}')" "veto saw command='' keys=['tool_name']"
check "a tool_input that is not an object gives an empty command" \
  "$(veto_saw '{"tool_name":"Bash","tool_input":"boom"}')" "veto saw command='' keys=['tool_input', 'tool_name']"
check "a missing command gives an empty command" \
  "$(veto_saw '{"tool_name":"Bash","tool_input":{}}')" "veto saw command='' keys=['tool_input', 'tool_name']"

echo "=== the whole payload is handed to the veto, not just the command ==="
check "a hook can reach fields beside the command" \
  "$(veto_saw '{"tool_name":"Bash","tool_input":{"command":"x"},"transcript_path":"/t"}')" \
  "veto saw command='x' keys=['tool_input', 'tool_name', 'transcript_path']"

echo "=== the hook always exits cleanly, or the harness treats it as broken ==="
check "exit 0 when allowing" "$(exit_code '{"tool_name":"Bash","tool_input":{"command":"ls"}}')" "0"
check "exit 0 when blocking" "$(exit_code "$bash_payload")" "0"
check "exit 0 on unparseable input" "$(exit_code 'not json')" "0"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
