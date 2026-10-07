# Guided mode

One work package at a time, in this session, on the current branch — pausing for the user after each. The user reviews every step; nothing is decided silently.

For each work package of the milestone, in `After:` order (`.0` first):

1. **Announce:** WP id + title, files owned, definition of done, and the decisions that apply. If the doc doesn't settle a design question this WP hits, ask now with AskUserQuestion — the doc's Proposal (Recommended) vs the Alternative. Never decide silently in guided mode.
2. **Implement** within the WP's files owned. Under TDD, write the test first and confirm it fails for the right reason. A file outside ownership needs a reason; it is a deviation (step 7).
3. **Build and test** — the project's commands, full suite, output to a log with only the summary lines shown (SKILL.md rule 13).
4. **Stack reviewer** on the WP's diff (the agent named in the run plan, on the model the WP's `Review:` depth sets — SKILL.md rule 6). Fix its findings. A finding you and the user decide not to fix becomes a follow-up in step 5 (`Kind: compromise`, **Why accepted**).
5. **Follow-ups:** `/followup` for each deferred item, accepted limitation, compromise (incl. declined review findings) or decision that surfaced, with its Kind. When the user accepts a recommendation that carries a compromise or a decision they may want to revisit, record it without being asked.
6. **Marker:** write `☑ landed` in the WP's row of the overview's table and move the milestone's `in progress (…)` line to the next WP (first WP: also the plan gate and header).
7. **Commit once** — code, tests, ledger entries with their regenerated index, and the marker together: `<Imperative summary> (<M> WPx.y)`. The body carries what doc-sync needs at landing, one line each: `Review: <agent> — <findings and what happened to each>`, and `Deviation: <what differs from the WP file, and why>` when there is one. No doc-sync here — it runs once, when the milestone lands. A bug found in older, unrelated code gets its own `Fix …` commit, not folded into the WP.
8. **Pause.** Show, compactly:
   - the commit (sha + subject) and test counts (before → after);
   - reviewer findings and what happened to each;
   - deviations from the doc, decisions taken;
   - follow-ups opened (id · Kind · title);
   - the next WP and anything it needs from the user.

   Then wait. "continue" → next WP. "continue to the end of <M>" → keep going without pausing for the rest of that milestone in this session only (the per-WP review still happens). Anything else → act on it first.

**Verification and landing** (once every WP is landed): set the milestone's line to `in progress (verification)` and run every acceptance criterion. For interactive criteria, give the user the exact command and what to look for, and wait — record their words as evidence (`— user confirmed: "<quote>"`). A criterion that can't pass here and belongs to a later milestone → `/followup` `Kind: deferred`, `Revisit when: <that later milestone>` (never this one — that would block its own landing). Then **doc-sync, once**, with: the milestone's commit range (its WP commits carry the `Review:` and `Deviation:` lines), the acceptance output as literal summary lines and user quotes, and the follow-up ids opened or resolved (they already exist — Updates and status flips only). It ticks the criteria, records deviations in `as-built.md`, updates README and CLAUDE.md, and lands the milestone — or sets `in progress (awaiting user check)` when the user can't check now; a later `/implement` (no args, `next` or `<id>`) offers the checks again and lands on confirmation. Commit `Sync docs for <M> (<first sha>..<last sha>)` and show doc-sync's "could not fix" list.

**Resume:** a dirty tree whose changes fall inside the in-progress WP's files owned (plus its overview marker or new ledger entries) is an interrupted guided WP — show `git diff --stat` and ask whether to continue from it. This skill never discards uncommitted work; if the user wants it gone, they do that themselves.
