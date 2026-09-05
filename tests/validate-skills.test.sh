#!/usr/bin/env bash
# Tests validate_skills.py, which holds the two runtimes to one invocation policy and keeps the
# manifests and copy_prompt.py honest about the skills that exist. Each case copies the repo to a
# throwaway directory and breaks exactly one thing there, so the real repo is never modified.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pass=0; fail=0

check() {
  if [ "$2" = "$3" ]; then printf '  PASS %s\n' "$1"; pass=$((pass+1))
  else printf '  FAIL %s\n       got:  %s\n       want: %s\n' "$1" "$2" "$3"; fail=$((fail+1)); fi
}

# A copy of the repo without .git, so a case can edit it freely and is thrown away after.
fixture() {
  local dir; dir="$(mktemp -d)"
  cp -R "$repo_root/." "$dir/" 2>/dev/null
  rm -rf "$dir/.git"
  printf '%s' "$dir"
}

# Runs the validator over a fixture and prints only the reported problems.
errors() { python3 "$repo_root/scripts/validate_skills.py" "$1" 2>&1 | grep -E '^- ' || true; }

# Whether the reported problems mention the given text, as 1 or 0.
reports() { errors "$1" | grep -cF "$2" | tr -d ' '; }

status() { python3 "$repo_root/scripts/validate_skills.py" "$1" >/dev/null 2>&1; echo $?; }

echo "=== the repo as committed is valid ==="
check "the real repo passes" "$(status "$repo_root")" "0"
check "and reports nothing" "$(errors "$repo_root")" ""

echo "=== the two runtimes must reach the same policy ==="
d=$(fixture)
sed -i.bak 's/allow_implicit_invocation: false/allow_implicit_invocation: true/' "$d/skills/land/agents/openai.yaml"
check "Claude explicit-only with Codex implicit is caught" "$(reports "$d" "land: the runtimes disagree")" "1"
check "and it fails" "$(status "$d")" "1"
rm -rf "$d"

d=$(fixture)
sed -i.bak '/^disable-model-invocation: true$/d' "$d/skills/todo/SKILL.md"
check "Codex explicit-only with Claude implicit is caught" "$(reports "$d" "todo: the runtimes disagree")" "1"
rm -rf "$d"

echo "=== the allowlist is the one place the policy is stated ==="
d=$(fixture)
sed -i.bak '/^land$/d' "$d/explicit-only-skills.txt"
check "explicit-only in both runtimes but off the list is caught" \
  "$(reports "$d" "land: explicit-only is True but the skill is absent from")" "1"
rm -rf "$d"

d=$(fixture)
printf 'work-summary\n' >> "$d/explicit-only-skills.txt"
check "listed but implicit in both runtimes is caught" \
  "$(reports "$d" "work-summary: explicit-only is False but the skill is listed in")" "1"
rm -rf "$d"

d=$(fixture)
printf 'no-such-skill\n' >> "$d/explicit-only-skills.txt"
check "a listed name that is not a skill is caught" "$(reports "$d" "which is not a skill")" "1"
rm -rf "$d"

echo "=== every skill carries a Codex policy, or Codex silently ignores the Claude one ==="
d=$(fixture)
rm -rf "$d/skills/open-pr/agents"
check "a missing openai.yaml is caught" "$(reports "$d" "open-pr: agents/openai.yaml is required")" "1"
rm -rf "$d"

d=$(fixture)
printf 'interface:\n  display_name: "x"\n  short_description: "y"\n' > "$d/skills/commit/agents/openai.yaml"
check "openai.yaml without a policy section is caught" \
  "$(reports "$d" "commit: agents/openai.yaml needs policy.allow_implicit_invocation")" "1"
rm -rf "$d"

d=$(fixture)
sed -i.bak 's/  display_name: .*/  display_name: ""/' "$d/skills/commit/agents/openai.yaml"
check "an empty display_name is caught" \
  "$(reports "$d" "commit: agents/openai.yaml needs a non-empty interface.display_name")" "1"
rm -rf "$d"

echo "=== the YAML parser refuses what it cannot read rather than guessing ==="
d=$(fixture)
printf 'policy:\n  allow_implicit_invocation: true\n  allow_implicit_invocation: false\n' \
  > "$d/skills/commit/agents/openai.yaml"
check "a duplicate key is caught" "$(reports "$d" "duplicate key 'allow_implicit_invocation'")" "1"
rm -rf "$d"

d=$(fixture)
printf 'policy:\n  allow_implicit_invocation: [true]\n' > "$d/skills/commit/agents/openai.yaml"
check "a value the parser does not support is caught" "$(reports "$d" "unsupported YAML value")" "1"
rm -rf "$d"

d=$(fixture)
printf 'interface:\n    display_name: "x"\n' > "$d/skills/commit/agents/openai.yaml"
check "an unexpected indent is caught" "$(reports "$d" "indented 4, expected 0 or 2")" "1"
rm -rf "$d"

echo "=== a skill's frontmatter must describe that skill ==="
d=$(fixture)
sed -i.bak 's/^name: commit$/name: committing/' "$d/skills/commit/SKILL.md"
check "a name not matching the directory is caught" \
  "$(reports "$d" "commit: frontmatter name must match the directory")" "1"
rm -rf "$d"

d=$(fixture)
sed -i.bak 's/^description: .*/description: ""/' "$d/skills/land/SKILL.md"
check "an empty description is caught" "$(reports "$d" "land: frontmatter needs a non-empty description")" "1"
rm -rf "$d"

d=$(fixture)
mkdir -p "$d/skills/orphan"
check "a skill directory with no SKILL.md is caught" \
  "$(reports "$d" "orphan: skill directory has no SKILL.md")" "1"
rm -rf "$d"

echo "=== a reference has to point at a skill that exists ==="
d=$(fixture)
sed -i.bak 's/\[\[commit\]\]/[[commits]]/' "$d/skills/open-pr/SKILL.md"
check "a dangling reference is caught" "$(reports "$d" "open-pr: [[commits]] does not name a skill")" "1"
rm -rf "$d"

echo "=== a skill copy_prompt.py cannot title would only fail when someone runs make ==="
d=$(fixture)
sed -i.bak '/"land": "LAND GUIDELINES",/d' "$d/copy_prompt.py"
check "a skill missing from both tables is caught" \
  "$(reports "$d" "land: copy_prompt.py has no title for it")" "1"
rm -rf "$d"

echo "=== the manifests have to keep naming the plugin they ship ==="
d=$(fixture)
sed -i.bak 's/"skills": ".\/skills\/"/"skills": ".\/workflows\/"/' "$d/.codex-plugin/plugin.json"
check "a Codex manifest pointing elsewhere is caught" \
  "$(reports "$d" ".codex-plugin/plugin.json: skills must be './skills/'")" "1"
rm -rf "$d"

d=$(fixture)
sed -i.bak 's/"name": "fedemelo",/"name": "renamed",/' "$d/.claude-plugin/plugin.json"
check "a renamed Claude plugin is caught" "$(reports "$d" ".claude-plugin/plugin.json: name must be")" "1"
rm -rf "$d"

d=$(fixture)
rm -f "$d/.agents/plugins/marketplace.json"
check "a missing Codex marketplace is caught" \
  "$(reports "$d" ".agents/plugins/marketplace.json: required file is missing")" "1"
rm -rf "$d"

d=$(fixture)
printf '{"name": "x", "name": "y"}\n' > "$d/.claude-plugin/plugin.json"
check "a duplicate JSON key is caught" "$(reports "$d" "invalid JSON")" "1"
rm -rf "$d"

echo "=== a workflow belongs in skills/, not in a custom command ==="
d=$(fixture)
mkdir -p "$d/commands" && printf 'x\n' > "$d/commands/ship.md"
check "a commands/ directory is caught" "$(reports "$d" "commands/ is reserved")" "1"
rm -rf "$d"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
