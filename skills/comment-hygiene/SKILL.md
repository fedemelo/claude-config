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
5. An explanation of an algorithm that stays hard to follow after you tried to simplify it and could not. Try the four fixes below first; this is what is left when they all fail.

Remove:

1. Any comment that merely restates what the code does.
2. Any comment referencing something external and mutable, such as a specific ticket, a doc or wiki page, or a record ID like an order ID, since those go stale.
3. Any comment about former behavior or hypotheticals; a reader needs the current behavior, not what the code used to do or what would happen without it.

Removing such a comment is not always just deleting a line. A comment that restates the code is usually there because the code is hard to read, and the best comment is a good name. So change the code until the comment has nothing left to say, then drop it. Four cases cover almost all of them:

1. The comment explains a complex expression, such as a long condition or a calculation with no intermediate steps. Extract variables. Declare a variable above the expression, assign one part of the expression to it, and replace that part with the variable. Repeat for each part that needed explaining, and pick names that say what the part means. One caution: splitting `a() || b()` into variables makes both calls run, since the short circuit is gone. Keep the expression as it is when either call is slow or has a side effect. If the same expression shows up elsewhere, extract a function instead of a variable.
2. The comment explains a block of code inside a longer function. Extract that block into its own function, and take the name from the comment text, which usually already says what the block is for. Pass in the variables the block uses but does not declare. If the block changes a local variable the caller still needs afterward, return it.
3. The block is already its own function and the comment says what the function does. Rename the function to say that itself. Rename it everywhere, including any superclass or subclass that declares the same method, and update every call. If the old name is part of a public interface, leave it in place as a deprecated wrapper that calls the new one instead of deleting it.
4. The comment states a condition that has to hold for the code to work, such as a precondition on a parameter or on object state. Assert it. The assertion must not change behavior while the condition holds, and it should cover only what correctness really needs; if the code behaves the same without it, drop it. Use an assertion only for a programmer error that should never happen. When a user action or a reachable system state can produce the condition, raise or handle an error instead.

Applying this: when editing code, whether directly or from another skill, refactor away or delete the comments this standard rejects, and write no new ones that would fail it. When reviewing without editing, flag them instead, and name the fix that removes the need for the comment rather than only asking for the line to go. Never strip a comment that carries genuine external knowledge just to cut lines.
