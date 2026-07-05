#!/usr/bin/env python3
import json
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

target_groups = target.setdefault("hooks", {}).setdefault("PreToolUse", [])
target_groups_by_matcher = {g["matcher"]: g for g in target_groups}

for matcher_group in example["hooks"]["PreToolUse"]:
    matcher = matcher_group["matcher"]
    if matcher not in target_groups_by_matcher:
        target_groups.append(matcher_group)
        print(f"Added PreToolUse hook group for matcher '{matcher}'")
        continue

    existing_commands = [h["command"] for h in target_groups_by_matcher[matcher]["hooks"]]
    for hook in matcher_group["hooks"]:
        if hook["command"] not in existing_commands:
            target_groups_by_matcher[matcher]["hooks"].append(hook)
            print(f"Added PreToolUse hook command for matcher '{matcher}': {hook['command']}")
        else:
            print(f"PreToolUse hook command already present for matcher '{matcher}', left as-is: {hook['command']}")

target_path.write_text(json.dumps(target, indent=2) + "\n")
print(f"Merged into {target_path} (effortLevel/tui/attribution left untouched — set those yourself if wanted)")
