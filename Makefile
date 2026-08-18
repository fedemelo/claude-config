# One target per skill: `make local-review` puts that skill's prompt, plus every prompt it
# references, on the clipboard, ready to paste into a tool that cannot load skills.

repo := $(dir $(lastword $(MAKEFILE_LIST)))
skills := $(notdir $(patsubst %/,%,$(wildcard $(repo)skills/*/)))

.DEFAULT_GOAL := help
.PHONY: help list $(skills)

help:
	@echo "make <skill>  copy a skill's prompt, and the prompts it references, to the clipboard"
	@echo "make list     list the skills"

list:
	@printf '%s\n' $(skills)

$(skills):
	@python3 $(repo)copy_prompt.py $@
