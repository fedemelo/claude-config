#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.claude/hooks" "$HOME/.claude/skills"

ln -sf "$repo_dir/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
ln -sf "$repo_dir/hooks/enforce-commit-skill.py" "$HOME/.claude/hooks/enforce-commit-skill.py"
ln -sf "$repo_dir/hooks/require-git-land-todo-tools.py" "$HOME/.claude/hooks/require-git-land-todo-tools.py"
ln -sf "$repo_dir/skills/commit" "$HOME/.claude/skills/commit"
ln -sf "$repo_dir/skills/land" "$HOME/.claude/skills/land"
ln -sf "$repo_dir/skills/todo" "$HOME/.claude/skills/todo"

echo "Linked CLAUDE.md, hooks, and skills into ~/.claude"

python3 "$repo_dir/merge_settings.py" "$repo_dir/settings.json.example" "$HOME/.claude/settings.json"
