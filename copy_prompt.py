#!/usr/bin/env python3
"""Puts a skill's prompt on the clipboard, together with the documents it cannot run without.

For tools that cannot load skills, where the only way to use one is to paste it as a prompt.
"""

import re
import subprocess
import sys
from collections import deque
from functools import cache
from pathlib import Path


SKILLS_DIR = Path(__file__).resolve().parent / "skills"

# A title heads each block, because a pasted prompt arrives without the name and description the
# skill file carries.
#
# The two groups decide what travels with a prompt, and the test is whether the task survives the
# reference being missing. Included documents are the ones the prompt runs on: the standards it
# has to obey while writing its output, and a skill whose procedure is the body of the work, as
# work-summary is inside daily-update. Named-only documents are a procedure of their own, invoked
# as a separate step, so a prompt that names one still works without it: pasting it would only
# bury the task in instructions for another one.
INCLUDED = {
    "comment-hygiene": "COMMENT HYGIENE STANDARD",
    "plain-english": "PLAIN ENGLISH STANDARD",
    "pr-description": "PR DESCRIPTION STANDARD",
    "work-summary": "WORK SUMMARY GUIDELINES",
}

NAMED_ONLY = {
    "address-review": "ADDRESS REVIEW GUIDELINES",
    "commit": "COMMIT GUIDELINES",
    "daily-update": "DAILY UPDATE GUIDELINES",
    "land": "LAND GUIDELINES",
    "local-review": "LOCAL REVIEW GUIDELINES",
    "open-pr": "OPEN PR GUIDELINES",
    "second-opinion": "SECOND OPINION GUIDELINES",
    "todo": "TODO GUIDELINES",
    "verify-replies": "VERIFY REPLIES GUIDELINES",
}

TITLES = {**INCLUDED, **NAMED_ONLY}

OMISSION_TITLE = "REFERENCED DOCUMENTS NOT INCLUDED"

FRONTMATTER = re.compile(r"\A---\n.*?\n---\n", re.DOTALL)
REFERENCE = re.compile(r"\[\[([a-z0-9-]+)\]\]")


def available():
    return sorted(path.name for path in SKILLS_DIR.iterdir() if (path / "SKILL.md").is_file())


def title_of(skill):
    if not (SKILLS_DIR / skill / "SKILL.md").is_file():
        sys.exit(f"No skill named {skill}. Available: {', '.join(available())}")
    if skill not in TITLES:
        sys.exit(f"No title for {skill}. Add it to INCLUDED or NAMED_ONLY in {Path(__file__).name}")
    return TITLES[skill]


@cache
def prompt_of(skill):
    title_of(skill)
    return FRONTMATTER.sub("", (SKILLS_DIR / skill / "SKILL.md").read_text()).strip()


def references_of(skill):
    return REFERENCE.findall(prompt_of(skill))


def bundle(root):
    """The skill, the documents it reaches through [[references]] that it cannot run without,
    and the skills it merely names, which were left out. Order of first mention, each skill once."""
    included, queue = [], deque([root])
    while queue:
        skill = queue.popleft()
        if skill in included:
            continue
        included.append(skill)
        queue.extend(reference for reference in references_of(skill) if reference in INCLUDED)

    omitted = []
    for skill in included:
        for reference in references_of(skill):
            if reference not in included and reference not in omitted:
                omitted.append(reference)
    return included, omitted


def block(title, body):
    return f'"""\n{title}\n\n{body}\n"""'


def omission_note(omitted):
    named = ", ".join(f"[[{skill}]] ({title_of(skill)})" for skill in omitted)
    if len(omitted) == 1:
        left_out = (
            "That document was left out on purpose: it is a procedure of its own, followed as a "
            "separate step, and the task above can be completed without it."
        )
        reach = "If your work does reach it, ask the user to provide it and wait for their answer."
    else:
        left_out = (
            "Those documents were left out on purpose: each is a procedure of its own, followed "
            "as a separate step, and the task above can be completed without them."
        )
        reach = "If your work does reach one of them, ask the user to provide it and wait for their answer."
    return block(
        OMISSION_TITLE,
        f"The text above refers to {named} in double brackets. {left_out}\n\n"
        f"{reach} Do not guess at what it says. You cannot look it up from here, and the "
        "conventions it sets cannot be worked out from its name.",
    )


def render(root):
    included, omitted = bundle(root)
    blocks = [block(title_of(skill), prompt_of(skill)) for skill in included]
    if omitted:
        blocks.append(omission_note(omitted))
    return "\n\n".join(blocks), included, omitted


def main(argv):
    arguments = [argument for argument in argv if argument != "--stdout"]
    if len(arguments) != 1:
        sys.exit(f"usage: {Path(__file__).name} <skill> [--stdout]")

    text, included, omitted = render(arguments[0])

    if "--stdout" in argv:
        print(text)
        return

    subprocess.run(["pbcopy"], input=text, text=True, check=True)
    print(f"Copied to clipboard: {', '.join(included)}")
    if omitted:
        print(f"Named but not included: {', '.join(omitted)}")


if __name__ == "__main__":
    main(sys.argv[1:])
