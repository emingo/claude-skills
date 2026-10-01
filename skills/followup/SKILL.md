---
name: followup
description: Capture a follow-up into the project's follow-up ledger the moment it surfaces — a deferred item, an accepted limitation, a compromise, or a decision the user may want to revisit. Use when the user says /followup <note>, "note this down", "add a follow-up", "add a followup about that decision, I want to review it later", or when a deferred item / accepted limitation / compromise / surprising constraint is identified mid-task and must not be lost.
---

# /followup — capture a ledger entry

Append the note passed as arguments (or, if none, the follow-up just discussed in conversation) to the project's follow-up ledger. Ledger path: the one declared in the project CLAUDE.md's documentation workflow section if any; otherwise `docs/follow-ups.md`.

1. If the ledger file doesn't exist yet, create it (and its directory) with exactly this skeleton:

   ```markdown
   # Follow-up Ledger

   Side-findings that surface during tasks: deferred features, accepted limitations, compromises, decisions worth revisiting, latent design smells, and missing pieces. Anything discovered mid-task that could change a future implementation or clarify a feature gets an entry here **before the task is considered done** (use `/followup <note>` to capture one mid-session).

   Rules:
   - Entries are **never deleted**. Status moves `open` → `done (<sha> or PR #N, YYYY-MM-DD)` or `dropped (reason)`; resolved entries keep their body as history.
   - IDs are stable and sequential (`FU-NNN`); reference them from docs, code comments, and commit messages instead of duplicating the detail.
   - **Kind** says why the entry exists: `deferred` (planned work moved later — **Revisit when** names the owning milestone or trigger), `decision` (a choice made autonomously or on the user's behalf that they may revisit), `compromise` (an accepted cost to keep scope — **Why accepted** required), `limitation` (a known gap or constraint — **Why accepted** required).
   - Before planning or implementing any feature, scan the index for open entries whose **Areas** overlap the work — each one must be addressed or explicitly re-deferred in the plan.
   - `doc-sync` maintains this file: it appends entries reported at task end, and flips status when a commit range verifiably resolves one.

   ## Index

   | ID | Title | Kind | Status | Areas |
   |----|-------|------|--------|-------|

   ## Entries
   ```

2. Read the ledger. If the note re-defers or adds evidence to an **existing** entry, don't create a new one: append `- **Update (YYYY-MM-DD, <source>):** …` to it (for a re-deferral: `Revisit when → <new> — <why>`, and set Status `open (re-deferred)`), then skip to step 5. Otherwise determine the next sequential `FU-NNN` id (first entry in a fresh ledger: `FU-001`).
3. Append an entry under `## Entries`. Match the heading style the ledger already uses; in a fresh ledger (or one already using it) write an explicit anchor so links survive title edits:

   ```markdown
   <a id="fu-001"></a>
   ### FU-001: <Title>
   ```

   Then the fields:
   - **Status:** open
   - **Kind:** `deferred` | `decision` | `compromise` | `limitation`. Infer it from how the user put it — "I want to review that later" → `decision`; "accept that cost for now" → `compromise`; "can't do X here" → `limitation`; "do it in M5" → `deferred`. Suffix `(unconfirmed)` when guessed.
   - **Origin:** current branch + today's date + one clause on what work surfaced it (from conversation context). When invoked from `/impl-plan`, `/milestone`, `/implement` or `/walkthrough`, name the plan section, milestone, work package or walkthrough point (e.g. `main, 2026-09-30 — plan review §7`, `— M3 refresh`, `— M4a WP4a.3 (swarm report)`, `— walkthrough 2026-10-01-m2-design #4`).
   - **Areas** / **Impacts:** infer from the note and the code being discussed; suffix `(unconfirmed)` to anything guessed rather than stated.
   - **What:** the note, expanded to 1–3 full sentences with the concrete file/type names involved so it stands alone months later.
   - **Why accepted:** (required for `compromise` and `limitation`; optional otherwise) what made this acceptable now — the cost avoided, the alternative's price.
   - **Revisit when:** (required for `deferred`; optional otherwise) a milestone id or a concrete trigger ("if rotation interpolation shows gimbal artifacts"). A bare milestone id here blocks that milestone from landing until the entry is resolved or re-deferred.

   An existing ledger keeps any extra fields it already uses (e.g. `When picked up`); add the new fields alongside them.
4. Add the matching row to the Index table in the ledger's existing column layout (add a Kind cell only if the Index has a Kind column), linking the id the way existing rows do — with explicit anchors that's `| [FU-001](#fu-001) | <Title> | decision | open | <Areas> |`. Other docs link an entry by relative path plus the same anchor (from `docs/milestones/`: `../follow-ups.md#fu-001`); in a ledger without explicit anchors the anchor is GitHub's slug of the full heading (`#fu-001-title-words`).
5. Do NOT commit — the entry rides along with the session's next commit.
6. Echo the created entry back to the user and ask nothing; if the note was too vague to fill **What** meaningfully, say what's missing instead of inventing details.
