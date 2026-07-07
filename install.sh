#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.claude/hooks" "$HOME/.claude/skills"

ln -sf "$repo_dir/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

for hook in "$repo_dir"/hooks/*.py; do
  ln -sf "$hook" "$HOME/.claude/hooks/$(basename "$hook")"
done

# -sfn (not -sf): don't follow an existing dir symlink, or re-runs nest the link inside it
for skill in "$repo_dir"/skills/*/; do
  skill="${skill%/}"
  ln -sfn "$skill" "$HOME/.claude/skills/$(basename "$skill")"
done

echo "Linked CLAUDE.md, hooks, and skills into ~/.claude"

python3 "$repo_dir/merge_settings.py" "$repo_dir/settings.json.example" "$HOME/.claude/settings.json"
