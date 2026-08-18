#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path

example_path, target_path = Path(sys.argv[1]), Path(sys.argv[2])
example = json.loads(example_path.read_text())

if not target_path.exists():
    target_path.parent.mkdir(parents=True, exist_ok=True)
    target_path.write_text(json.dumps(example, indent=2) + "\n")
    print(f"Created {target_path}")
    sys.exit(0)

target = json.loads(target_path.read_text())

# Appended rather than replaced: the list also holds whatever you approved with "don't ask
# again", and those rules are yours.
for rule in example.get("permissions", {}).get("allow", []):
    allowed = target.setdefault("permissions", {}).setdefault("allow", [])
    if rule in allowed:
        print(f"Permission rule already present, left as-is: {rule}")
    else:
        allowed.append(rule)
        print(f"Added permission rule: {rule}")

target_groups = target.setdefault("hooks", {}).setdefault("PreToolUse", [])
target_groups_by_matcher = {g["matcher"]: g for g in target_groups}


def hook_identity(command):
    """The script a hook runs, so that changing its arguments updates the existing entry
    rather than appending a second copy that keeps running the stale form. Commands with no
    script fall back to the whole string, leaving unrelated hooks matched exactly."""
    script = re.search(r"([\w.-]+\.py)", command)
    return script.group(1) if script else command


for matcher_group in example["hooks"]["PreToolUse"]:
    matcher = matcher_group["matcher"]
    if matcher not in target_groups_by_matcher:
        target_groups.append(matcher_group)
        print(f"Added PreToolUse hook group for matcher '{matcher}'")
        continue

    hooks = target_groups_by_matcher[matcher]["hooks"]
    for hook in matcher_group["hooks"]:
        existing = [h for h in hooks if hook_identity(h["command"]) == hook_identity(hook["command"])]

        if not existing:
            hooks.append(hook)
            print(f"Added PreToolUse hook command for matcher '{matcher}': {hook['command']}")
            continue

        for duplicate in existing[1:]:
            hooks.remove(duplicate)
            print(f"Removed duplicate hook for matcher '{matcher}': {duplicate['command']}")

        if existing[0]["command"] == hook["command"]:
            print(f"PreToolUse hook command already present for matcher '{matcher}', left as-is: {hook['command']}")
        else:
            print(f"Updated hook for matcher '{matcher}': {existing[0]['command']} -> {hook['command']}")
            existing[0]["command"] = hook["command"]

target_path.write_text(json.dumps(target, indent=2) + "\n")
print(f"Merged into {target_path} (effortLevel/tui/attribution left untouched — set those yourself if wanted)")
