---
name: plain-english
description: "The standard for prose meant for another person to read: B2-level English, no jargon or corporate fluff, no reference chains, nothing that reads as AI-written. Other skills reference it when writing review comments, replies, and descriptions. Use when writing or judging text someone else will read."
---

Write the draft you would write anyway, then rewrite it against every rule below. Write for a competent developer who is reading in a second language and was not present for the reasoning behind the text. Whatever they need to act is in the text; everything else is noise that costs them time.

Sentences and words:

1. B2-level English: the common word over the rare one. "wrong" not "erroneous", "use" not "leverage", "same" not "identical", "so" not "hence".
2. Active voice with a concrete subject. "This reads the config twice", not "the configuration ends up being read twice".
3. Verbs over nominalizations. "This duplicates the data", not "this introduces duplication of the data".
4. One idea per sentence, with no clause stacked inside another. A "which", "while", "although", "given that", or an opening "Having ..." is the signal to break the sentence in two. Joining two short statements with "and", "but", or "so" is fine. A period costs the reader nothing, while a nested clause makes them hold the first half in mind to parse the second.
5. Unroll hyphenated compounds unless the compound is a fixed term. Established ones stay as they are: read-only, off-by-one, type-safe, non-null. Invented ones go back into ordinary word order, so "hard-to-follow logic" becomes "logic that is hard to follow", and "a single-source-of-truth problem" becomes "this value is now stored in two places". A non-native reader who is translating in their head has to undo the hyphens before they can start.

No fluff. A word earns its place when it names something with a definition, and knowing that definition changes what the reader should do. Technical terms qualify and should be used plainly: cache, coupling, cohesion, encapsulation, race condition, side effect, idempotent, invariant, off-by-one, N+1 query, memory leak, deadlock. These do not:

1. Metaphors standing in for the mechanism: plumbing, thread through, wire up, surface (as a verb), blast radius, surface area, footgun, reach into, bleeds into, in the wild. A non-native reader cannot decode them. Replace each with what actually happens.
2. Quality words that measure nothing: brittle, fragile, robust, resilient, hardening, clean, elegant, seamless, holistic, first-class, non-trivial, orthogonal, opinionated, canonical, sane defaults, gracefully. "Brittle" becomes "breaks when the list is empty".
3. Labels that replace the argument: code smell, anti-pattern, tech debt, best practice. Say what goes wrong rather than naming a category it belongs to.
4. Padding: utilize, facilitate, ensure that, in order to, it is worth noting, at the end of the day.

Keep the reader's memory free:

1. Name only the symbols the reader must act on. Every extra function, module, or file name is one more thing to hold in mind while reading the rest of the sentence.
2. Give the conclusion and its consequence, not the path taken to reach them. No chain of hops through the codebase.
3. Cut the investigation: what was checked first, what was ruled out, what turned out fine.

Do not read as AI-written:

1. Plain prose. No bold, no headers, no bullet list for a single point.
2. Never restate the reader's own code or words back to them before making the point.
3. No praise and no softening ritual: "great catch", "nice work", "just a thought".
4. One hedge at most, and only where the uncertainty is real. Never "it might potentially be worth considering".
5. When it is a question, ask it. "Why not X?" is a complete message.
6. No sign-off, no summary of what was just said, no offer to help further.

What this looks like. Before:

> This introduces a fairly brittle coupling: `resolveTenantConfig` reaches into the `SessionContext` singleton to surface the tenant id, which is then threaded through `buildQueryPlan` and `executePlan`, so any caller that instantiates the planner outside a request lifecycle hits a hard-to-diagnose null deref.

After:

> This only works inside a request. In a background job there is no session, so the tenant id is null and the planner crashes. Pass the tenant id in as an argument instead.

Applying this: invoked directly, rewrite the given text against these rules and return it. Referenced from another skill, apply it to every part of the output that a person other than the user will read. It governs prose only, never code, identifiers, quoted text, or command output.
