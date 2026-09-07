#!/usr/bin/env bash
# Tests install.sh and merge_settings.py against a sandboxed HOME, so running these never
# touches the real ~/.claude. Each case starts from a fresh temp HOME, except where it is
# deliberately re-installing over a previous one.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT

pass=0; fail=0

check() {
  if [ "$2" = "$3" ]; then printf '  PASS %s\n' "$1"; pass=$((pass+1))
  else printf '  FAIL %s\n       got:  %s\n       want: %s\n' "$1" "$2" "$3"; fail=$((fail+1)); fi
}

# Counted from the repo rather than hardcoded, so adding a skill does not fail the suite.
skill_count="$(find "$repo_root/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"

new_home() { mktemp -d "$ROOT/home.XXXXXX"; }
install_into() { HOME="$1" "$repo_root/install.sh"; }
commands_in() {
  python3 -c "
import json, sys
settings = json.load(open(sys.argv[1]))
for group in settings['hooks']['PreToolUse']:
    for hook in group['hooks']:
        print(hook['command'])" "$1/.claude/settings.json"
}

echo "=== fresh install on an empty HOME ==="
h="$(new_home)"
out="$(install_into "$h")"
check "every repo skill is linked" "$(ls "$h/.claude/skills" | wc -l | tr -d ' ')" "$skill_count"
check "settings.json created" "$(test -f "$h/.claude/settings.json" && echo yes)" "yes"
check "CLAUDE.md points at the repo" "$(readlink "$h/.claude/CLAUDE.md")" "$repo_root/CLAUDE.md"
check "nothing reported as pruned" "$(echo "$out" | grep -c 'Pruned')" "0"

echo "=== the same skills are linked for Codex, from the same directory ==="
check "every repo skill is linked there too" "$(ls "$h/.agents/skills" | wc -l | tr -d ' ')" "$skill_count"
check "both runtimes point at one directory in the repo" \
  "$(readlink "$h/.agents/skills/commit")" "$(readlink "$h/.claude/skills/commit")"
check "and that directory is this repo's" "$(readlink "$h/.agents/skills/commit")" "$repo_root/skills/commit"
check "the Codex policy file travels with the link" \
  "$(test -f "$h/.agents/skills/commit/agents/openai.yaml" && echo yes)" "yes"
check "both directories are named in the report" "$(echo "$out" | grep -c '.agents/skills')" "1"

echo "=== a CLAUDE.md you wrote yourself is kept ==="
h="$(new_home)"; mkdir -p "$h/.claude"
printf '# My rules\nAlways speak in haiku.\n' > "$h/.claude/CLAUDE.md"
out="$(install_into "$h")"
check "its content survives in the backup" "$(grep -c haiku "$h/.claude/CLAUDE.md.pre-claude-config")" "1"
check "CLAUDE.md becomes the repo symlink" "$(readlink "$h/.claude/CLAUDE.md")" "$repo_root/CLAUDE.md"
check "the move is reported" "$(echo "$out" | grep -c 'Moved aside')" "1"

# A symlink is somebody else's claim on the slot, and a managed workspace pointing it at team
# policy is the case that matters: taking it over would swap out policy nobody asked to lose.
echo "=== a CLAUDE.md symlinked elsewhere is left alone ==="
h="$(new_home)"; mkdir -p "$h/.claude"; printf 'theirs\n' > "$h/other.md"
ln -sf "$h/other.md" "$h/.claude/CLAUDE.md"
out="$(install_into "$h")"
check "the slot still points where it did" "$(readlink "$h/.claude/CLAUDE.md")" "$h/other.md"
check "leaving it is reported" "$(echo "$out" | grep -c 'Left CLAUDE.md alone')" "1"
check "the file it pointed at is untouched" "$(cat "$h/other.md")" "theirs"
check "no pointless backup is made" "$(ls "$h/.claude" | grep -c 'pre-claude-config')" "0"
check "the rest of the install still ran" \
  "$(ls "$h/.claude/skills" | wc -l | tr -d ' ')" "$skill_count"

echo "=== Codex gets the same global instructions, by the same rule ==="
h="$(new_home)"
out="$(install_into "$h")"
check "AGENTS.md points at the repo" "$(readlink "$h/.codex/AGENTS.md")" "$repo_root/CLAUDE.md"
check "both runtimes read one file" \
  "$(readlink "$h/.codex/AGENTS.md")" "$(readlink "$h/.claude/CLAUDE.md")"
check "the Codex slot is named in the report" "$(echo "$out" | grep -c '.codex')" "1"

h="$(new_home)"; mkdir -p "$h/.codex"
printf '# My rules\nAlways speak in haiku.\n' > "$h/.codex/AGENTS.md"
out="$(install_into "$h")"
check "an AGENTS.md you wrote yourself survives in the backup" \
  "$(grep -c haiku "$h/.codex/AGENTS.md.pre-claude-config")" "1"
check "and the slot becomes the repo symlink" \
  "$(readlink "$h/.codex/AGENTS.md")" "$repo_root/CLAUDE.md"

# The devspaces case: the workspace points this slot at root-owned team policy and recreates
# the link every boot, so claiming it would both lose policy and not survive a restart.
h="$(new_home)"; mkdir -p "$h/.codex"; printf 'team policy\n' > "$h/managed.md"
ln -sf "$h/managed.md" "$h/.codex/AGENTS.md"
out="$(install_into "$h")"
check "a managed AGENTS.md symlink is left alone" \
  "$(readlink "$h/.codex/AGENTS.md")" "$h/managed.md"
check "leaving it is reported" "$(echo "$out" | grep -c 'Left AGENTS.md alone')" "1"
check "the policy it pointed at is untouched" "$(cat "$h/managed.md")" "team policy"
check "Claude's own slot was still claimed" \
  "$(readlink "$h/.claude/CLAUDE.md")" "$repo_root/CLAUDE.md"

echo "=== re-running over this repo's own links changes nothing ==="
h="$(new_home)"; install_into "$h" >/dev/null
out="$(install_into "$h")"
check "CLAUDE.md is not reported as foreign" "$(echo "$out" | grep -c 'Left CLAUDE.md alone')" "0"
check "AGENTS.md is not reported as foreign" "$(echo "$out" | grep -c 'Left AGENTS.md alone')" "0"
check "neither slot is backed up on a re-run" \
  "$(ls "$h/.claude" "$h/.codex" | grep -c 'pre-claude-config')" "0"

echo "=== links to skills and hooks removed upstream are pruned ==="
h="$(new_home)"; install_into "$h" >/dev/null
ln -sfn "$repo_root/skills/removed-skill" "$h/.claude/skills/removed-skill"
ln -sfn "$repo_root/skills/removed-skill" "$h/.agents/skills/removed-skill"
ln -sfn "$repo_root/hooks/removed-hook.py" "$h/.claude/hooks/removed-hook.py"
mkdir -p "$h/.claude/skills/my-own"; printf 'x\n' > "$h/.claude/skills/my-own/SKILL.md"
out="$(install_into "$h")"
check "the stale skill link is gone" "$(test -L "$h/.claude/skills/removed-skill" && echo present || echo gone)" "gone"
check "the stale Codex link is gone too" \
  "$(test -L "$h/.agents/skills/removed-skill" && echo present || echo gone)" "gone"
check "the stale hook link is gone" "$(test -L "$h/.claude/hooks/removed-hook.py" && echo present || echo gone)" "gone"
check "all three prunes are reported" "$(echo "$out" | grep -c 'Pruned stale link')" "3"
check "a real skill directory of your own is kept" "$(test -f "$h/.claude/skills/my-own/SKILL.md" && echo yes)" "yes"
check "the repo skills are still linked" "$(ls "$h/.claude/skills" | grep -vc my-own)" "$skill_count"

echo "=== links owned by anything else are left alone, broken or not ==="
h="$(new_home)"; install_into "$h" >/dev/null
ln -sfn "/nonexistent/elsewhere/skills/theirs" "$h/.claude/skills/theirs"
ln -sfn "/nonexistent/elsewhere/hooks/theirs.py" "$h/.claude/hooks/theirs.py"
out="$(install_into "$h")"
check "a broken skill link from elsewhere survives" "$(test -L "$h/.claude/skills/theirs" && echo kept)" "kept"
check "a broken hook link from elsewhere survives" "$(test -L "$h/.claude/hooks/theirs.py" && echo kept)" "kept"
check "nothing is reported as pruned" "$(echo "$out" | grep -c 'Pruned')" "0"

echo "=== a hook whose arguments changed upstream is updated in place ==="
h="$(new_home)"; install_into "$h" >/dev/null
python3 - "$h/.claude/settings.json" <<'PY'
import json, sys
path = sys.argv[1]
settings = json.load(open(path))
settings["hooks"]["PreToolUse"][0]["hooks"][0]["command"] += " --old-flag"
json.dump(settings, open(path, "w"), indent=2)
PY
out="$(install_into "$h")"
check "it is reported as an update" "$(echo "$out" | grep -c 'Updated hook')" "1"
check "the stale argument form is gone" "$(commands_in "$h" | grep -c 'old-flag')" "0"
check "no second copy is left behind" "$(commands_in "$h" | grep -c 'enforce-commit-skill')" "1"

echo "=== duplicates already in settings.json are collapsed ==="
h="$(new_home)"; install_into "$h" >/dev/null
python3 - "$h/.claude/settings.json" <<'PY'
import json, sys
path = sys.argv[1]
settings = json.load(open(path))
settings["hooks"]["PreToolUse"][0]["hooks"].append(
    {"type": "command", "command": "python3 $HOME/.claude/hooks/enforce-commit-skill.py --stale"})
json.dump(settings, open(path, "w"), indent=2)
PY
out="$(install_into "$h")"
check "the duplicate is removed" "$(echo "$out" | grep -c 'Removed duplicate')" "1"
check "one entry remains" "$(commands_in "$h" | grep -c 'enforce-commit-skill')" "1"

echo "=== a hook renamed upstream is pruned, not left as a stale duplicate ==="
h="$(new_home)"; install_into "$h" >/dev/null
ln -sfn "$repo_root/hooks/renamed-away.py" "$h/.claude/hooks/renamed-away.py"
python3 - "$h/.claude/settings.json" <<'PY'
import json, sys
path = sys.argv[1]
settings = json.load(open(path))
settings["hooks"]["PreToolUse"][0]["hooks"].append(
    {"type": "command", "command": "python3 $HOME/.claude/hooks/renamed-away.py"})
json.dump(settings, open(path, "w"), indent=2)
PY
out="$(install_into "$h")"
check "the dangling symlink prune is reported" "$(echo "$out" | grep -c 'Pruned stale link renamed-away.py')" "1"
check "the settings.json entry is pruned too" "$(echo "$out" | grep -c 'Pruned stale hook.*renamed-away')" "1"
check "the old name is gone from settings.json" "$(commands_in "$h" | grep -c 'renamed-away')" "0"
check "the current hook is still present" "$(commands_in "$h" | grep -c 'enforce-commit-skill')" "1"

echo "=== settings of your own are left alone ==="
h="$(new_home)"; install_into "$h" >/dev/null
python3 - "$h/.claude/settings.json" <<'PY'
import json, sys
path = sys.argv[1]
settings = json.load(open(path))
settings["hooks"]["PreToolUse"][0]["hooks"].append({"type": "command", "command": "echo my-own-hook"})
settings["hooks"]["PostToolUse"] = [{"matcher": "Bash", "hooks": [{"type": "command", "command": "echo mine"}]}]
settings["effortLevel"] = "high"
json.dump(settings, open(path, "w"), indent=2)
PY
install_into "$h" >/dev/null
check "your own PreToolUse hook is kept" "$(commands_in "$h" | grep -c 'my-own-hook')" "1"
check "your PostToolUse block is kept" "$(python3 -c "
import json; print('PostToolUse' in json.load(open('$h/.claude/settings.json'))['hooks'])")" "True"
check "your effortLevel is kept" "$(python3 -c "
import json; print(json.load(open('$h/.claude/settings.json'))['effortLevel'])")" "high"

echo "=== the merged settings.json is verified, not assumed ==="
h="$(new_home)"
out="$(install_into "$h")"
check "the verification runs on a fresh install" "$(echo "$out" | grep -c 'Verified: settings.json parses')" "1"
python3 - "$h/.claude/settings.json" <<'PY'
import json, sys
path = sys.argv[1]
settings = json.load(open(path))
settings["hooks"]["PreToolUse"][0]["hooks"].append(
    {"type": "command", "command": "python3 $HOME/.claude/hooks/never-installed.py"})
json.dump(settings, open(path, "w"), indent=2)
PY
out="$(install_into "$h" 2>&1)"; code=$?
check "a hook naming a missing script fails the install" "$code" "1"
check "and says which one" "$(echo "$out" | grep -c 'never-installed.py')" "1"
python3 -c "
import json, sys
path = '$h/.claude/settings.json'
settings = json.load(open(path))
settings['hooks']['PreToolUse'][0]['hooks'] = [
    h for h in settings['hooks']['PreToolUse'][0]['hooks'] if 'never-installed' not in h['command']]
json.dump(settings, open(path, 'w'), indent=2)"
check "removing it makes the install pass again" "$(install_into "$h" >/dev/null 2>&1; echo $?)" "0"

echo "=== re-running changes nothing ==="
h="$(new_home)"; install_into "$h" >/dev/null
before="$(cat "$h/.claude/settings.json")"
out="$(install_into "$h")"
check "settings.json is byte-identical" "$([ "$before" = "$(cat "$h/.claude/settings.json")" ] && echo same)" "same"
check "no change is reported" "$(echo "$out" | grep -c 'Added\|Updated\|Pruned\|Removed')" "0"

printf '\n=== %d passed, %d failed ===\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
