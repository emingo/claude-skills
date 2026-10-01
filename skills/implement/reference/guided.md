# Guided mode

One work package at a time, in this session, on the current branch — pausing for the user after each. The user reviews every step; nothing is decided silently.

For each work package of the milestone, in `After:` order (`.0` first, the verification WP last):

1. **Announce:** WP id + title, files owned, definition of done, and the reviewer decisions that apply. If the doc doesn't settle a design question this WP hits, ask now with AskUserQuestion — the doc's Proposal (Recommended) vs the Alternative. Never decide silently in guided mode.
2. **Implement** within the WP's files owned. Under TDD, write the test first and confirm it fails for the right reason. A file outside ownership needs a reason; say so in the pause summary (doc-sync records it as a deviation).
3. **Build and test** — the project's commands, full suite.
4. **Stack reviewer** on the WP's diff (the agent named in the run plan — SKILL.md rule 6). Fix its findings. A finding you and the user decide not to fix becomes a follow-up in step 6 (`Kind: compromise`, **Why accepted**) — not now, so the ledger edit lands in the doc-sync commit rather than the code commit. Keep the reviewer's output — doc-sync needs it as evidence.
5. **Commit** `<Imperative summary> (<M> WPx.y)`. A bug found in older, unrelated code gets its own `Fix …` commit, not folded into the WP.
6. **Follow-ups:** `/followup` for each deferred item, accepted limitation, compromise (incl. declined review findings) or decision that surfaced, with its Kind. When the user accepts a recommendation that carries a compromise or a decision they may want to revisit, record it without being asked.
7. **doc-sync** with: the commit sha(s), WP id, reviewer output, test evidence, deviations, decisions, follow-up ids opened/resolved (they already exist — Updates and status flips only), and the next WP (for the `in progress (…)` line). Commit its edits as `Sync docs for <M> WPx.y (<sha>)`. Every WP, never batched — deviations go into doc-sync's "As built" notes, not a separate commit.
8. **Pause.** Show, compactly:
   - commits (sha + subject) and test counts (before → after);
   - reviewer findings and what happened to each;
   - deviations from the doc, decisions taken;
   - follow-ups opened (id · Kind · title);
   - doc-sync's "could not fix" list;
   - the next WP and anything it needs from the user.

   Then wait. "continue" → next WP. "continue to the end of <M>" → keep going without pausing for the rest of that milestone in this session only (the per-WP review and doc-sync still happen). Anything else → act on it first.

**The verification WP** (last): run every acceptance criterion. For interactive criteria, give the user the exact command and what to look for, and wait — record their words as evidence for doc-sync (`— user confirmed: "<quote>"`). If they can't check now, doc-sync sets `in progress (awaiting user check)`; a later `/implement` (no args, `next` or `<id>`) offers the checks again and lands on confirmation. A criterion that can't pass here and belongs to a later milestone → `/followup` `Kind: deferred`, `Revisit when: <that later milestone>` (never this one — that would block its own landing). Then doc-sync lands the milestone if everything qualifies.

**Resume:** a dirty tree whose changes fall inside the in-progress WP's files owned is an interrupted guided WP — show `git diff --stat` and ask whether to continue from it. This skill never discards uncommitted work; if the user wants it gone, they do that themselves.
