#!/usr/bin/env bash
# Tests allow-skill-commands.py, the hook that auto-approves the commands a skill declares.
# Every case feeds it one PreToolUse payload and asserts only whether it allowed the command,
# since the hook has no other effect and never denies.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
hook="$repo_root/hooks/allow-skill-commands.py"

pass=0; fail=0

check() {
  if [ "$2" = "$3" ]; then printf '  PASS %s\n' "$1"; pass=$((pass+1))
  else printf '  FAIL %s\n       got:  %s\n       want: %s\n' "$1" "$2" "$3"; fail=$((fail+1)); fi
}

# "allow" when the hook approved the command, "silent" when it left it to the normal
# permission flow. Prefixes are passed after the command, as a skill's frontmatter does.
verdict() {
  local command="$1"; shift
  local out
  out="$(python3 -c "
import json, sys
print(json.dumps({'tool_name': 'Bash', 'tool_input': {'command': sys.argv[1]}}))" "$command" \
    | python3 "$hook" "$@")"
  if printf '%s' "$out" | grep -q '"permissionDecision": "allow"'; then echo allow; else echo silent; fi
}

echo "=== commands a skill declared ==="
check "an exact match is allowed" "$(verdict "git status" "git status")" "allow"
check "a prefix match is allowed" "$(verdict "gh pr view 12 --json title" "gh pr view")" "allow"
check "every segment must be allowed" "$(verdict "git status && rm -rf /" "git status")" "silent"
check "all segments allowed passes" "$(verdict "git status && git diff" "git status" "git diff")" "allow"
check "an undeclared command is left alone" "$(verdict "git push" "git status")" "silent"
check "a prefix must end on a space" "$(verdict "git status" "git st")" "silent"
check "a prefix ending in / matches a path" \
  "$(verdict "gh api repos/x/y/pulls" "gh api repos/")" "allow"
check "a path prefix still has to match" "$(verdict "gh api reposx/y" "gh api repos/")" "silent"
check "redirection is never allowed" "$(verdict "git status > /tmp/x" "git status")" "silent"
check "substitution is never allowed" "$(verdict "git show \$(git rev-parse HEAD)" "git show")" "silent"

echo "=== a gh api call may read, never write ==="
check "a plain GET is allowed" \
  "$(verdict "gh api repos/{owner}/{repo}/pulls/1/comments" "gh api repos/")" "allow"
check "--template stays allowed" \
  "$(verdict "gh api repos/{owner}/{repo}/issues/1/timeline --template '{{.x}}'" "gh api repos/")" "allow"
check "-X POST is not allowed" \
  "$(verdict "gh api repos/{owner}/{repo}/issues/1/comments -X POST" "gh api repos/")" "silent"
check "-XPOST written without a space is not allowed" \
  "$(verdict "gh api repos/{owner}/{repo}/issues/1/comments -XPOST" "gh api repos/")" "silent"
check "--method=PATCH is not allowed" \
  "$(verdict "gh api repos/{owner}/{repo}/pulls/1 --method=PATCH" "gh api repos/")" "silent"
# The case a method-only guard would have missed: fields alone make gh send POST.
check "a field without -X is not allowed" \
  "$(verdict "gh api repos/{owner}/{repo}/issues/1/comments -f body=hi" "gh api repos/")" "silent"
check "--raw-field is not allowed" \
  "$(verdict "gh api repos/{owner}/{repo}/issues/1/comments --raw-field body=hi" "gh api repos/")" "silent"
check "--input is not allowed" \
  "$(verdict "gh api repos/{owner}/{repo}/issues/1/comments --input body.json" "gh api repos/")" "silent"
check "a write hidden behind a second segment is not allowed" \
  "$(verdict "gh api repos/{owner}/{repo}/pulls/1 && gh api repos/x -f body=hi" "gh api repos/")" "silent"

echo "=== graphql needs fields, so its query is what decides ==="
check "a graphql query is allowed" \
  "$(verdict "gh api graphql -F number=1 -f query='query(\$number:Int!){x}'" "gh api graphql")" "allow"
check "a graphql mutation is not allowed" \
  "$(verdict "gh api graphql -f query='mutation{addComment(x:1){y}}'" "gh api graphql")" "silent"

echo "=== the gh api rule touches nothing else ==="
check "a field flag on another command still passes" \
  "$(verdict "git commit -F msg.txt" "git commit")" "allow"
check "-X in a commit message still passes" \
  "$(verdict "git commit -m 'Document the -X flag'" "git commit")" "allow"

echo
echo "=== $pass passed, $fail failed ==="
[ "$fail" -eq 0 ]
