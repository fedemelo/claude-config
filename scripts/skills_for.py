#!/usr/bin/env python3
"""Print the skills that belong in one kind of environment, one name per line.

Both installers select with this rather than reading the frontmatter themselves: install.sh on a
machine you own, and the devspaces procedure in a pod. One place knows the key, so the two cannot
drift into disagreeing about which skills an environment gets.
"""

import sys
from pathlib import Path

from validate_skills import (
    ENVIRONMENT_ANY,
    ENVIRONMENT_KEY,
    ENVIRONMENT_TARGETS,
    YamlError,
    parse_frontmatter,
)


def environment_of(path):
    """The environment a skill declares, or `any` when it declares none.

    Frontmatter that will not parse is treated as `any`, which installs the skill everywhere, the
    way it was installed before this key existed. The validator is what fails on a malformed
    skill; an installer that refused to run until CI was green would be the worse trade.
    """
    try:
        return parse_frontmatter(path.read_text()).get(ENVIRONMENT_KEY, ENVIRONMENT_ANY)
    except (OSError, YamlError):
        return ENVIRONMENT_ANY


def selection(skills_dir, environment):
    """The skills this environment gets, and the ones it leaves out."""
    included, excluded = [], []
    for path in sorted(skills_dir.iterdir()):
        skill = path / "SKILL.md"
        if not skill.is_file():
            continue
        scope = environment_of(skill)
        chosen = included if scope in (ENVIRONMENT_ANY, environment) else excluded
        chosen.append(path.name)
    return included, excluded


def main(argv):
    arguments = [argument for argument in argv if argument != "--excluded"]
    if len(arguments) not in (1, 2):
        sys.exit(f"usage: {Path(__file__).name} <environment> [skills-dir] [--excluded]")

    environment = arguments[0]
    if environment not in ENVIRONMENT_TARGETS:
        sys.exit(f"unknown environment {environment!r}; expected one of {', '.join(ENVIRONMENT_TARGETS)}")

    default = Path(__file__).resolve().parents[1] / "skills"
    skills_dir = Path(arguments[1]) if len(arguments) == 2 else default
    if not skills_dir.is_dir():
        sys.exit(f"no skills directory at {skills_dir}")

    included, excluded = selection(skills_dir, environment)
    for name in excluded if "--excluded" in argv else included:
        print(name)


if __name__ == "__main__":
    main(sys.argv[1:])
