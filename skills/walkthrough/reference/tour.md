# Tour mode — guided understanding

A tour explains a large document, a repo, or a topic step by step. Nothing is decided and no source is edited: each stop ends with the user understanding it, skipping it for later, or holding an open question. This file replaces SKILL.md §2–§4 for tours; SKILL.md's hard rules, picker conventions (§3.3: free text is fine, plain-text fallback) and "On resume" paragraph still apply.

## When

Start a tour only when the user asks for one — `/walkthrough tour …`, "guide me through this repo/document step by step", "give me a tour of …" — or accepts an offer. "Explain X", "how does X work", "walk me through this function" get a normal answer (plus an offer of a tour when the honest answer would run well past a screen).

**Arguments:** `tour [<file | dir | . | topic>] [goal]`. Resolve the first token as a path (cwd, then repo root); if nothing exists there, treat the whole argument as a topic from this conversation; if neither matches, ask. Text after a path is the user's goal. No target → ask (this repo / a file / the last response).

## 1. Build the outline

Never outline from memory or file names alone — but read in two passes, so the user sets the scope before the expensive part.

- **A document:** read it (a very large one section by section). Group its sections into **5–9 stops** — by idea, not one per heading. Keep the document's order unless a later section is needed to understand an earlier one. Each stop names its source range (`§3–4`, `lines 120–260`).
- **A repo or directory:**
  1. *Cheap pass:* README, CLAUDE.md, manifests, the top-level listing, the shape of `git log`.
  2. If it's large (several packages, or more than ~300 source files) and no goal was given, ask once: whole-repo overview · one subsystem · a goal.
  3. *Then* explore what the chosen scope needs — entry points, the main flow, tests — with up to three Explore subagents only when it's large. Module internals are read at their stop, not up front.

  Outline top-down, **7–10 main stops** in Standard, adapting to what's there: what it is and who uses it → how to build, run and test it → the map (layout, layers, dependencies) → the main flow end to end (follow one request / frame / command through the code) → the key modules, most central first (further modules become sub-stops) → data and contracts → conventions and gotchas → current state (done, in progress, known gaps).
- **A topic in the conversation** (a plan just written, an agent's report): its sections or themes.

A stated goal ("I need to change the importer") tailors the outline — stops on the path to it come first and go deeper; say so (`Tailored to: …`).

Show the outline as a table — `# · stop · what you'll learn · source` — and ask once (AskUserQuestion, header `Depth`): *Standard* (Recommended) · *Overview* (≈5 short stops) · *Deep* (planned sub-stops for each major part). "Other" takes reordering, picking stops, or "start at 4": re-show the final outline once with its final numbers. After the first stop, numbers never change; stops the user left out are a filter, not `skipped`.

## 2. Each stop

1. **Header:** `**Stop 3/8 — <title>**` · `<n> left`. M counts main stops only. A sub-stop is `**Stop 3.2 — <title>** · part 2 of 3` and doesn't change N/M or `<n> left`.
2. **Brief** (~150–300 words): the one idea first, in a sentence; then how it works, grounded in the source — `file:line` references, a snippet of at most ~15 lines, or a small table/diagram when structure matters more than prose; how it connects to earlier stops; one thing worth noticing (a gotcha, a surprising choice) if there is one. Verify against the actual source; mark anything unverified or inferred **[U]**.
3. **Picker** (header `Stop 3`): `Got it — next` · `Expand` · `Skip — review later`. "Other" is for an open question or navigation.
4. **State line** after each outcome, so the tour survives compaction: `Stops: 1–2 understood · 3 skipped · open questions 1 · parked 0 · Next: Stop 4/8 — <title>` (plus the notes path once a notes file exists).

## 3. Replies

| Reply | Do |
|---|---|
| **Got it — next** | Outcome `understood`; go on. |
| **Expand** | Go deeper on this stop: a worked example, the code path traced, a diagram, the history behind a choice. If the stop is big, open **sub-stops** (`3.1`, `3.2`, … — show the mini-outline first). After the expansion, or the last sub-stop, re-offer **this stop's** picker. |
| **Skip — review later** | Outcome `skipped`; it comes back at the end. |
| **An open question** | Answer it from the source — read more if needed — then re-offer the same stop's picker. If it belongs to a later stop, answer briefly and say where it's covered (or offer to jump). If the material can't answer it, say so and park it under **Open questions**. |
| **"I know this already"** | Outcome `understood`; shorten later stops that build on it. |
| **A misunderstanding in the user's question** | Correct it plainly, with the evidence. |
| **A decision surfaces** ("should we change this?") | In a tour: don't decide mid-tour — park it under **Parked decisions**. (For an explain-only point inside a decide/review walkthrough, it becomes a new agenda point per `replies.md` instead.) |
| **"Quiz me"** | Only then: one or two questions on the stops so far, then continue. Never quiz unasked. |
| **Navigation** | `back to N` · `jump to N` · `outline` (show it again with outcomes) · `go deeper from here` / `speed up` (change depth for the remaining stops) · `pause` (with no notes file: offer once to save notes, and say the tour otherwise continues only in this conversation). |

## 4. End

1. **Recap** — the mental model in ten lines or fewer.
2. **Skipped stops** — list them; offer: review now / leave for later.
3. **Open questions** that couldn't be answered, and where an answer might be found.
4. **Parked decisions**, if any — offer to go through them as a normal decide walkthrough (SKILL.md §2–§4, with its log and all its rules) or to record them with `/followup` (`Kind: deferred` with a Revisit when for undecided ones).
5. **What next** — a deeper tour of one stop, or what to read or run first.

## Writing things down

A tour lives in the conversation by default. It writes only on request, and never in plan mode (offer to save once plan mode is off):

- **"Save notes"** → `<log dir>/YYYY-MM-DD-tour-<slug>.md` (adding `-2`, `-3` if taken; or a path the user names — which a bare `/walkthrough resume` won't find), written from `templates/log.md` with `Mode: tour`: the outline as the agenda with outcomes, a stub per stop (its one idea and source range), questions asked with their answers, open questions, parked decisions, and the recap once the tour ends. SKILL.md §2.6's asking rules apply (no `docs/` dir, not a repo).
- **Once a notes file exists it is the log:** update it after every stop and name it in the state line. Status `paused` on pause; `done` once the End has run (skipped stops left for later are outcomes, not open).
- **Resume:** `/walkthrough resume` continues a saved tour at the first stop without an outcome, after SKILL.md's "On resume" check of the source.

No commit is made, and none is suggested unless a notes file was written.
