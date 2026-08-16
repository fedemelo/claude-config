#!/usr/bin/env bash
# Asserts that a skill's declared allowlist cannot auto-approve a command that changes
# something, unless changing that thing is what the skill is for.
#
# Sampled, not exhaustive. MUTATIONS below is a denylist, so a pass means none of the shapes
# that have gone wrong before are present, never that no mutation can slip through. Closing
# that properly would need skills to declare their intent in frontmatter instead.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

python3 - <<'PY'
import json
import re
import subprocess
import sys
from pathlib import Path

HOOK = "hooks/allow-skill-commands.py"

MUTATIONS = [
    "git commit -m x",
    "git push origin main",
    "git reset --hard HEAD~1",
    "git rebase origin/main",
    "git cherry-pick abc123",
    "git land",
    "git todo Something",
    "gh pr merge 1 --merge",
    "gh pr close 1",
    "gh pr comment 1 --body hi",
    "gh pr review 1 --approve",
    "gh pr edit 1 --title x",
    "gh pr create --title x --body y",
    "gh issue close 1",
    "gh issue create --title x",
    "gh api -X POST repos/o/r/issues/1/comments -f body=hi",
    "gh api repos/o/r/issues/1/comments -f body=hi",
    "gh release create v1",
    "gh repo delete o/r --yes",
]

# Written out here rather than inferred from each skill's own text: prose that forbids a command
# reads exactly like prose that uses it, so the land skill saying "never git push first" would
# justify allowing it. A new skill that admits a mutation therefore fails until it is listed,
# which is the point.
EXPECTED = {
    "commit": {"git commit -m x"},
    "land": {"git land"},
    "todo": {"git todo Something"},
    "open-pr": {
        "git push origin main",
        "git rebase origin/main",
        "git cherry-pick abc123",
        "gh pr create --title x --body y",
    },
}

passed = failed = 0


def check(label, got, want):
    global passed, failed
    if got == want:
        print(f"  PASS {label}")
        passed += 1
    else:
        print(f"  FAIL {label}\n       got:  {got}\n       want: {want}")
        failed += 1


def approves(prefixes, command):
    result = subprocess.run(
        ["python3", HOOK, *prefixes],
        input=json.dumps({"tool_name": "Bash", "tool_input": {"command": command}}),
        capture_output=True,
        text=True,
    )
    return bool(json.loads(result.stdout or "{}"))


def prefixes_of(path):
    declared = re.search(r"allow-skill-commands\.py (.+?)'", path.read_text())
    return re.findall(r'"([^"]+)"', declared.group(1)) if declared else None


print("=== no skill auto-approves a mutation it does not exist to perform ===")
for path in sorted(Path("skills").glob("*/SKILL.md")):
    prefixes = prefixes_of(path)
    if prefixes is None:
        continue
    name = path.parent.name
    admitted = sorted(c for c in MUTATIONS if approves(prefixes, c))
    check(f"{name}", admitted, sorted(EXPECTED.get(name, set())))

print("=== the skills that do change things are still able to ===")
for name, expected in sorted(EXPECTED.items()):
    prefixes = prefixes_of(Path("skills") / name / "SKILL.md")
    if prefixes is None:
        check(f"{name} declares an allowlist", False, True)
        continue
    for command in sorted(expected):
        check(f"{name} still auto-approves {command.split(' -')[0]}", approves(prefixes, command), True)

print("=== a skill with no allowlist cannot be waved through at all ===")
for command in ["git commit -m x", "gh pr merge 1 --merge"]:
    check(f"no prefixes rejects {command.split(' -')[0]}", approves([], command), False)

print(f"\n=== {passed} passed, {failed} failed ===")
sys.exit(0 if failed == 0 else 1)
PY
