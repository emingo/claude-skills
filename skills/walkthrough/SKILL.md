---
name: walkthrough
description: Work through a list point by point with the user — open questions, review findings, plan sections, options — one at a time, each with a short brief, a recommendation and a quick picker, tracked in a visible decision log so nothing is skipped or forgotten. Also runs information-only guided tours of a large document or a repo (`/walkthrough tour …`): stops explained briefly, with a picker to continue, expand, skip for later or ask a question. Not for a plain "explain X", "how does X work" or "walk me through this function" question — those get a normal answer. Use when the user says "let's go through these one by one", "point by point", "walk me through the review/plan/questions", "guide me through this document/repo step by step", "give me a tour of", "/walkthrough", "continue the walkthrough/review", or accepts an offer to walk through a long list or take a tour.
argument-hint: "[<file> | <file>#<section> | tour [<file|dir|topic>] [goal] | resume [<log>]] [--only 2,5,7]"
allowed-tools: Bash(git log *) Bash(git status *) Bash(git diff *) Bash(git show *) Bash(git rev-parse *)
---

# /walkthrough — point-by-point review and guided tours

Arguments: $ARGUMENTS

## Hard rules

- **One point at a time**, each with a progress header — the user never faces a wall of questions. Only clear-cut ✓ points may be batched (≤4, a 1–2 line brief each, header `Points 4–7/10`).
- **No point is dropped.** The walkthrough ends only when every agenda item has an outcome, or the user explicitly leaves it open (recorded as open).
- **The log is visible:** state its path at the start and in every "recorded" line.
- **Re-check facts against the real code and docs before presenting each point**; correct earlier claims openly ("Correction: …"), including your own earlier review.
- **Never change a `Status:` line or a plan gate line**, and follow `${CLAUDE_SKILL_DIR}/../impl-plan/reference/doc-model.md` whenever the source is a plan or milestone doc (where to record: §3.5).
- **Never smuggle in content:** apply only what was decided; report anything added or dropped that wasn't. Never copy credentials or tokens into a log.
- **Ledger only via `/followup`. Never commit** — suggest the message (or, when invoked from another skill's flow, leave the commit to that flow).
- **Edits outside the decisions section wait for confirmation** (checkpoint or end). **Hands-off files** are never edited — flag them instead: anything outside the repo root, submodules, paths the project CLAUDE.md marks hands-off or as frozen specs, doc-sync's declared no-touch docs, generated files.
- **Plan mode active → write nothing** (no log file, no doc edits, no `/followup`): keep the log in the conversation and, at the end, list the log, decisions and follow-ups to write once plan mode is off.
- **Tour mode is information-only** — follow `${CLAUDE_SKILL_DIR}/reference/tour.md`, which replaces §2–§4. It decides nothing and edits no source; it writes only on request (a notes file, or `/followup` entries for parked decisions at the end). All hard rules still apply, except that there is no log unless notes are saved — then "the log is visible" applies to the notes file.

## 1. Source

| Argument | List to walk through |
|---|---|
| *(none)* | The list in the most recent substantive response or relayed agent report — questions, findings, plan points, options. If the last response offered a tour, start that tour on the offered target. No list (or two, or fewer than 3 items) → ask what to walk through, offering candidates: the last agent report, open `D<n>` in the active milestone doc, open `Kind: decision` ledger entries, a file path, a tour of a file or this repo. |
| `<file>` | Its open items: undecided design questions (`D<n>` / `Q<n>`), review findings, proposed changes, plan sections, ledger entries with `Kind: decision`. A file or section with no open items → say so (name what's already decided) and offer a tour — never start one unasked. A directory → ask once: the open decisions across its docs, or a tour. |
| `tour [<file \| dir \| . \| topic>] [goal]` | A guided, information-only tour of a document, a repo or directory, or a topic from this conversation — `${CLAUDE_SKILL_DIR}/reference/tour.md` replaces §2–§4 below (argument rules there). |
| `<file>#<section>` | Only that section (use the doc's own heading — e.g. its design-questions section). |
| `resume [<log>]` | Unfinished logs in the walkthrough log dir: one → continue it; several → list them (date · source · open count) and ask; offer to mark stale ones `abandoned`. If a `<file>` argument names a different source than a log, start a new walkthrough. No log, but an unfinished chat-only walkthrough or tour in this conversation → continue it; none → say so and offer to start one. |
| `--only 2,5,7` | Restrict to those agenda items (recorded as the log's filter). |

## 2. Agenda

1. **Extract** the items; merge duplicates, split compound ones. **Keep the source's grouping and labels** (Fix 2, D3, Finding 7) as stable IDs beside the running number — never renumber; a merged item keeps its label and shows `→ covered by #3`.
2. **Order:** groups as in the source; within a group, decisions that constrain others first, then the most important.
3. **Mode** (say which): **decide** (questions/options) · **review** (findings or proposed changes: accept / modify / reject) · **tour** (explain each stop; nothing to decide — `reference/tour.md`). A decide/review list can include explain-only points: they are ✓ with the recommendation "explain", use the tour picker and the outcome `understood`, and under a bulk option are shown as a batched 1–2 line brief each — never recorded `understood` unseen. A list with both kinds is logged as `Mode: mixed`.
4. **Show the agenda** as a compact table: `# · ID · point · recommendation · ⚖ judgment call / ✓ clear-cut`.
5. **Ask once how to proceed** (AskUserQuestion): *One by one* (Recommended) · *Only the judgment calls — accept the rest* · *Pick points* (then type the numbers) · *Accept all recommendations*. Bulk-accepted points are still recorded; any that carries a compromise still becomes a follow-up.
6. **Create the log** from `${CLAUDE_SKILL_DIR}/templates/log.md`, with **a stub for every point** (1–3 lines of substance, plus any proposed text verbatim) so the walkthrough survives a new session even when its source was a chat response. Where:
   - the reviews path declared in the project CLAUDE.md's Documentation Workflow section, else `<repo root>/docs/reviews/` (repo root from `git rev-parse --show-toplevel`); file `YYYY-MM-DD-<slug>.md`, adding `-2`, `-3` if taken;
   - ask first ("create `docs/reviews/` for the log, or keep it in chat?") when the project has no `docs/` dir, when the folder isn't a git repo, or when the source is a conversation that isn't about this project's code or docs (personal or unrelated content defaults to chat only);
   - tours default to chat only (notes on request — `reference/tour.md`).

   Print the path (or "log kept in this conversation — it won't survive a new session").

## 3. Each point

1. **Header:** `**Point 3/10 · Fix 4 — <title>**` (⚖ if it's a judgment call) · `<n> left`.
2. **Brief** (~150–300 words for a fresh point; building out a user's idea may run longer):
   - the situation in 1–3 sentences, with `file:line` references;
   - options A / B (/ C), each with its tradeoff or cost;
   - `**Recommend A** — <why>`; interactions with earlier decisions;
   - **when the point changes a document:** the exact proposed text in a blockquote, where it goes ("replaces *X* in §Y"), and side effects elsewhere — approving means accepting that edit;
   - **sub-decisions** numbered with a stated lean ("1. … — I lean toward …");
   - external facts marked **[V]** (verified, with source) or **[U]** (unverified or inferred).

   Review mode: the finding, the proposed change, its risk. Explain-only points: the explanation, as a tour stop.
3. **Picker** — AskUserQuestion; `header` = the point's ID (≤12 chars, e.g. `D3`, `Fix 4`); short labels, tradeoffs in each option's description; "Other" is automatic and always works for refining, own answers, questions and navigation:
   - *decide:* `<A> (Recommended)` · up to two more alternatives · `Tell me more` — with only one alternative, add `Defer as follow-up`; further alternatives stay in the brief and are chosen via Other;
   - *review:* `Accept (Recommended)` · `Reject` · `Tell me more` · `Defer as follow-up` ("accept with changes" goes in Other);
   - *explain-only / tour:* `Got it — next` · `Expand` · `Skip — review later` (questions go in Other and are answered on the spot).

   Sub-decisions: the main question plus at most three sub-questions in the same call, each with 2–4 options; Tell me more / Defer only on the main one. Free-text replies are fine: "approve", "your call", "leave it to you" = decided as recommended. No AskUserQuestion available (headless runs) → the same choices as a numbered plain-text list.
4. **Handle the reply** per `${CLAUDE_SKILL_DIR}/reference/replies.md`.
5. **Record immediately:**
   - **the log:** the point's status, outcome, rationale, rejected options, follow-ups, queued edits;
   - **the source's decisions section, by source:**
     - *milestone doc* `proposed` → `## Reviewer decisions`: append under `### <today>` (create it once; replace `_Pending review._`), numbered `**D1:** …`, and fold `**Decision:** …` under the question. A new point that is a design question gets the next free `D<n>` in the design-questions section. `approved` → same, then tell the user it's a substantive change: `/milestone refresh <id>` re-approves (Status returns to `proposed` there, not here). `in progress` / `landed` / `superseded`, or a project that freezes design docs → **log only**, and suggest `/milestone refresh <id>` or a dated As-built note;
     - *plan* `draft` → write the decision into §Decisions as Chosen vs Rejected and resolve its `[VERIFY]` tag / register row (Answer + Basis) or re-own it. `approved` → the same is a reviewed reversal: add a note to the one-line Last updated and warn which milestone docs it makes stale;
     - *ledger* → a `/followup` Update bullet on the entry ("confirmed / changed in walkthrough `<log>` #N"); status flips stay with doc-sync;
     - *anything else* (a chat response, a review report) → log only;
   - **other implied edits** (review fixes, aligning other docs) are **queued** — later points may change them.

   Then one line: `Recorded in <log> (+ <doc>) · follow-ups: FU-NNN · Next: Point 4/10 · <ID> — <title>`.
6. **Pace:** after three straight accepts in a row, or at a group boundary, offer "Accept the rest of <group> as recommended?" — once per group; judgment calls are still asked. At group boundaries also offer a **checkpoint apply**: list the approvals since the last apply, apply on yes.

**Navigation** (any time, via Other or free text): `next` · `back to N` · `jump to N` · `skip` (returns at the end) · `accept the rest` · `only judgment calls left` · `summary so far` · `apply what we have` · `pause` (the log keeps the state; `/walkthrough resume` continues).

**On resume:** re-read the source; if it changed since the log's `Source at`, re-verify the open points and queued edits (and, for a milestone doc, that its Status still allows writing) before continuing at the first open point with a one-line recap.

## 4. End

1. **Completeness check:** list every point without an outcome (skipped, open); ask: go through them now / defer each as a follow-up / leave open (recorded as open). Then say it plainly: "Every point from <source> now has an outcome" — or name what's left.
2. **Summary table:** `# · ID · point · outcome · follow-ups` + the log path. Outcomes: decided · deferred (FU) · future direction · handed off · covered by #N · understood · skipped · open.
3. **Queued edits** since the last checkpoint, listed by file; ask once "Apply these?"; apply on yes. Then report anything added or dropped that wasn't explicitly decided, and remove it unless the user keeps it. Set the log's Status to `done`.
4. **Invoked from another skill's flow** (`/milestone refresh` approval, `/impl-plan` hand-off) → stop here and continue that flow's next step in the same turn; the log and ledger entries go into its commit. **Otherwise — what's next:** for a milestone source, "Status stays `<status>`; `/milestone refresh <id>` (or `/implement <id>`) approves it"; recommend the next step, offer a ready-to-paste prompt if it belongs in a new session, and suggest a commit message.

Recording each point edits files — in default permission mode, suggest accepting edits for the session up front so the walkthrough isn't interrupted by prompts.
