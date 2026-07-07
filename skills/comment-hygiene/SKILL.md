---
name: comment-hygiene
description: Defines which code comments are worth keeping — only those carrying knowledge that can't be inferred from the code, not restatements of it. Strips unnecessary comments from a diff or file when invoked directly; other skills reference it as the rule for judging comments. Use when removing, reviewing, or writing comments.
---

A comment earns its place only if it carries information that cannot be deduced from the code itself. Judge every comment against a developer who knows the language, common patterns (e.g. what "factory" or "wrapper" imply), and this codebase's conventions, but not its business or domain: if they could infer the comment by reading the code alone, it adds nothing. When in doubt, remove.

**Keep** only comments that convey knowledge living outside the code:
- Business rules or domain knowledge.
- Product or business decisions and the rationale behind them.
- External constraints — third-party API quirks, protocol requirements, regulatory requirements.
- Non-obvious design rationale: why the implementation is the way it is when that reason isn't visible in it — performance trade-offs, security considerations, and the like.

**Remove**:
- Any comment that merely restates what the code does.
- Comments referencing something external and mutable — a specific ticket, doc or wiki page, or record ID (e.g. an order ID) — since those go stale.
- Comments about former behavior or hypotheticals: a reader only needs the current behavior, not what the code used to do or what would happen without it.

Applying this: when editing code (directly or from another skill), delete the comments this standard rejects and don't write new ones that would fail it. When reviewing without editing, flag them for removal instead of deleting. Never strip a comment that carries genuine external knowledge just to cut lines.
