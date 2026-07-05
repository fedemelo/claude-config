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

for matcher_group in example["hooks"]["PreToolUse"]:
    existing_matchers = [g["matcher"] for g in target.setdefault("hooks", {}).setdefault("PreToolUse", [])]
    if matcher_group["matcher"] not in existing_matchers:
        target["hooks"]["PreToolUse"].append(matcher_group)
        print(f"Added PreToolUse hook for matcher '{matcher_group['matcher']}'")
    else:
        print(f"PreToolUse hook for matcher '{matcher_group['matcher']}' already present, left as-is")

target_path.write_text(json.dumps(target, indent=2) + "\n")
print(f"Merged into {target_path} (effortLevel/tui/attribution left untouched — set those yourself if wanted)")
