---
name: comment-hygiene
description: "Defines which code comments are worth keeping: only those carrying knowledge that cannot be inferred from the code, not restatements of it. Strips unnecessary comments from a diff or file when invoked directly; other skills reference it as the rule for judging comments. Use when removing, reviewing, or writing comments."
---

A comment earns its place only when it carries information that cannot be deduced from the code itself. Judge every comment against a developer who knows the language, common patterns (such as what "factory" or "wrapper" imply), and this codebase's conventions, but not its business or domain. If that developer could infer the comment from the code alone, it adds nothing. When in doubt, remove.

Keep only comments that carry knowledge living outside the code:

1. Business rules or domain knowledge.
2. Product or business decisions and their rationale.
3. External constraints, such as third-party API quirks, protocol requirements, or regulatory requirements.
4. Design rationale the implementation does not reveal, such as performance trade-offs or security considerations.

Remove:

1. Any comment that merely restates what the code does.
2. Any comment referencing something external and mutable, such as a specific ticket, a doc or wiki page, or a record ID like an order ID, since those go stale.
3. Any comment about former behavior or hypotheticals; a reader needs the current behavior, not what the code used to do or what would happen without it.

Applying this: when editing code, whether directly or from another skill, delete the comments this standard rejects and write no new ones that would fail it. When reviewing without editing, flag them for removal instead of deleting. Never strip a comment that carries genuine external knowledge just to cut lines.
