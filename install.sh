#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.claude/hooks" "$HOME/.claude/skills"

claude_md="$HOME/.claude/CLAUDE.md"
# A regular file here holds global instructions written by hand, which the symlink below
# would replace without a trace.
if [ -f "$claude_md" ] && [ ! -L "$claude_md" ]; then
  mv "$claude_md" "$claude_md.pre-claude-config"
  echo "Moved aside your existing CLAUDE.md to CLAUDE.md.pre-claude-config"
elif [ -L "$claude_md" ] && [ "$(readlink "$claude_md")" != "$repo_dir/CLAUDE.md" ]; then
  echo "Replaced a CLAUDE.md symlink that pointed at $(readlink "$claude_md")"
fi

ln -sf "$repo_dir/CLAUDE.md" "$claude_md"

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
