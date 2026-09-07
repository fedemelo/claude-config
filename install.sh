#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

hooks_dir="$HOME/.claude/hooks"
# Claude Code reads ~/.claude/skills; Codex, Copilot and OpenCode read ~/.agents/skills. Each
# skill is linked into both from the one directory in this repo, so there is still a single copy.
skill_dirs=("$HOME/.claude/skills" "$HOME/.agents/skills")

mkdir -p "$hooks_dir" "${skill_dirs[@]}"

# Each runtime reads global instructions from its own path, and both get a link to this repo's
# CLAUDE.md: Claude Code reads ~/.claude/CLAUDE.md, Codex ~/.codex/AGENTS.md.
#
# Same rule for both, and it never writes over something this repo does not own. A regular file
# there holds instructions written by hand, so it is moved aside rather than replaced without a
# trace. A symlink pointing anywhere else belongs to whoever made it: an environment that
# provisions its own base instructions (a managed workspace pointing the slot at team policy)
# owns that slot, and taking it over would swap out policy the user never asked to lose. Report
# and skip, since a slot this repo declines to claim degrades nothing but its own reach.
link_instructions() {
  local slot="$1" label="$2"

  if [ -L "$slot" ]; then
    local current; current="$(readlink "$slot")"
    if [ "$current" != "$repo_dir/CLAUDE.md" ]; then
      echo "Left $label alone: it is a symlink to $current, which this repo does not own"
      return
    fi
  elif [ -e "$slot" ]; then
    mv "$slot" "$slot.pre-claude-config"
    echo "Moved aside your existing $label to $(basename "$slot").pre-claude-config"
  fi

  mkdir -p "$(dirname "$slot")"
  ln -sf "$repo_dir/CLAUDE.md" "$slot"
}

link_instructions "$HOME/.claude/CLAUDE.md" "CLAUDE.md"
link_instructions "$HOME/.codex/AGENTS.md" "AGENTS.md"

# Links whose target no longer exists are skills and hooks renamed or removed upstream.
# Nothing else prunes them, and a stale skill stays listed as one Claude cannot load. Only
# links pointing back into this repo are touched: a skill symlinked in from somewhere else can
# be temporarily unresolvable, and deleting it then would break an install this does not own.
pruned=0
pruned_hooks=()
for dir in "$hooks_dir" "${skill_dirs[@]}"; do
  for link in "$dir"/*; do
    if [ -L "$link" ] && [ ! -e "$link" ]; then
      case "$(readlink "$link")" in
        "$repo_dir"/*)
          echo "Pruned stale link $(basename "$link") -> $(readlink "$link")"
          [ "$dir" = "$hooks_dir" ] && pruned_hooks+=("$(basename "$link")")
          rm "$link"
          pruned=$((pruned + 1))
          ;;
      esac
    fi
  done
done

for hook in "$repo_dir"/hooks/*.py; do
  ln -sf "$hook" "$hooks_dir/$(basename "$hook")"
done

# -sfn (not -sf): don't follow an existing dir symlink, or re-runs nest the link inside it
for skill in "$repo_dir"/skills/*/; do
  skill="${skill%/}"
  for dir in "${skill_dirs[@]}"; do
    ln -sfn "$skill" "$dir/$(basename "$skill")"
  done
done

echo "Linked hooks into ~/.claude, global instructions into ~/.claude and ~/.codex, and skills into ~/.claude/skills and ~/.agents/skills"
[ "$pruned" -eq 0 ] || echo "Pruned $pruned stale link(s)"

python3 "$repo_dir/merge_settings.py" "$repo_dir/settings.json.example" "$HOME/.claude/settings.json" "${pruned_hooks[@]+"${pruned_hooks[@]}"}"

# The merge rewrites settings.json in place, and hooks name their script by path, so a file
# Claude cannot parse or a hook pointing at a script that is not installed both fail silently
# at the point of use rather than here.
python3 - "$HOME/.claude/settings.json" "$HOME/.claude/hooks" <<'PY'
import json, os, re, sys

settings_path, hooks_dir = sys.argv[1], sys.argv[2]

try:
    with open(settings_path) as f:
        settings = json.load(f)
except (OSError, json.JSONDecodeError) as error:
    sys.exit(f"FAILED: {settings_path} does not parse after the merge: {error}")

missing = []
for event, groups in settings.get("hooks", {}).items():
    for group in groups:
        for hook in group.get("hooks", []):
            for script in re.findall(r"\.claude/hooks/([\w.-]+)", hook.get("command", "")):
                if not os.path.exists(os.path.join(hooks_dir, script)):
                    missing.append(f"{event} -> {script}")

if missing:
    sys.exit("FAILED: settings.json names hooks that are not installed: " + ", ".join(missing))

print("Verified: settings.json parses and every hook it names is installed")
PY
