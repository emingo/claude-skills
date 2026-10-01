# Refresh procedure

A milestone doc written ahead of time captured the project as of its `Written against` sha. Refresh brings it up to date just before implementation, so the work starts from reality rather than from a projection. It is also the approval step: a refreshed doc ends `approved`, ready to implement.

## 1. Collect what the doc hasn't seen

Let `<sha>` = the doc's `Written against` (if missing, use the commit that last touched the doc: `git log -1 --format=%h -- <doc>`). If it's `n/a` (no git history): read landed As-built records and compare file modification dates against the doc's, skip the git commands, and say in the Refresh log that the comparison was date-based.

- `git log --oneline <sha>..HEAD` and `git diff --stat <sha>..HEAD` — what changed in the code.
- **As-built records of every landed milestone this one depends on** (directly or transitively): "Deviations", "Notes for the next milestone", contract deviations, back-notes aimed at this id.
- **Ledger:** `git log -p <sha>..HEAD -- <ledger>` — entries added since whose Areas overlap this milestone or that mention its id; entries this doc planned to resolve that were resolved elsewhere.
- **Plan changes:** `git log -p <sha>..HEAD -- <plan>` — §Decisions edits, register answers, Stack, conventions, and this milestone's gate scope/acceptance (ignore status-line edits).
- **Sibling docs:** milestones that can run alongside this one and started since — file-ownership collisions.

## 2. Re-check every section

| Section | Check |
|---|---|
| Header | Depends on / Blocks / Can run alongside still match the plan graph and the index. |
| What exists | **Rewrite** as a real inventory of the current code — it's a snapshot, not history. Drop the *Projected* marker. |
| Entry criteria | Each one met? Unmet → say so; that alone may mean "not ready", not "rewrite". |
| Design questions (`D<n>`) | Already answered by a landed as-built or a register answer? Mark `Answered by <ref>` and fold it into the Proposal. Obsolete? Say why. New questions surfaced by deviations or ledger entries? Add them with the next free `D<n>`. |
| Work packages | Files still exist / were renamed / were created by someone else? Scope still needed? Then run the **Swarm-readiness check** below. |
| Contracts | Consumed contracts match the real signatures in code, not the owner doc's planned shape. Introduced contracts don't collide with anything that landed. |
| Test requirements / Acceptance | Named tests and commands still valid; criteria still cover the gate. |
| Ledger reconciliation | Rebuild the table from the current ledger index. |
| Risks | Add risks the deviations revealed; drop ones that are gone. |

## Swarm-readiness check

Run in every refresh and by `/milestone mode` before switching a doc to `swarm`. Every item must hold:

- Every WP has `After:`, and the `After:` graph is acyclic.
- No two WPs that `After:` leaves unordered share a file — within the doc, against sibling docs that can run alongside it, and against files that landed since `Written against` (someone else may now own them).
- Shared hotspots (package refs, project/solution files, registries, DI wiring) are owned by `WP<n>.0` or explicitly sequenced.
- Consumed contracts match the real signatures in code; introduced contracts are specified as code blocks.
- No undecided `D<n>` blocks a WP that would run in parallel. (`/milestone mode` reports this as a note only; `/implement` treats it as a failure unless its up-front design round decides them.)

Report each failure with the fix (add an `After:` edge, move a file to `.0`, split a WP); for a doc being switched to swarm, a failure blocks the switch.

## 3. Edit in place — or recommend a rewrite

**Recommend a rewrite** (report the evidence, change nothing yet) when any of these hold:

- roughly half or more of the work packages need restructuring, not just edits;
- a contract or dependency this milestone builds on landed with a materially different shape;
- a §Decision it rests on was reversed;
- the plan gate's scope or acceptance bullets changed (status-line edits don't count);
- the work is largely done already, or the milestone should now be split or merged.

On the user's go-ahead, regenerate the doc from the template (skeleton rules still apply) and add `Rewritten YYYY-MM-DD — <reason>` as the first Refresh log entry; git keeps the old version. For a split or merge, the original doc stays with `Status: superseded (→ M3a, M3b)` and a Refresh log line; new docs are written via the single-doc path; the index and the plan's gate block are updated (gate replaced by the new gates, or marked `superseded (→ …)`) — show the plan edit to the user first.

**Otherwise edit in place:**

- Apply the changes from step 2.
- Append to `## Refresh log`:
  ```
  ### Refreshed YYYY-MM-DD (against `<new sha>`)
  - <section>: <what changed> — <why: commit, as-built note, FU id, plan edit>
  ```
  One bullet per changed section. If nothing changed: `- No changes — nothing relevant landed since \`<old sha>\`.`
- Bump `Written against` to HEAD.
- Substantive changes (scope, WPs, contracts, criteria) put `Status` back to `proposed` if it was `approved` (and the plan gate line with it).
- `in progress` doc (explicit user request only): apply the edits and log them, but leave `Status` and the gate alone and skip step 4.

## 4. Approval

1. Each design question without a decision becomes one AskUserQuestion option set: the Proposal (marked Recommended) vs the Alternative (plus "Other"). Batch up to four per round. With **more than four** undecided questions, run them as `/walkthrough <doc>#<its design-questions section>` instead — it records into this same Reviewer decisions format — then continue at step 3 in the same turn. Before step 4, list any `D<n>` the walkthrough left deferred or open and ask: take the Proposal now (recorded with a `Kind: decision` follow-up), or keep the doc `proposed`. Include the walkthrough log and any ledger entries in the approval commit.
2. Record answers under `## Reviewer decisions` as `### YYYY-MM-DD` with numbered bullets. Fold each decision into its question (`**Decision:** …`) so the WP text is unambiguous.
3. If a decision implies a plan edit (a §Decision, register answer, or gate), show the exact edit; apply only if the user agrees, and note it on the plan's Last-updated line.
4. Set `Status: approved (YYYY-MM-DD)` in the doc and the gate's status line in the plan. New dependencies implied by a decision follow the Stack rule (ask, then edit Stack).

A doc whose `Written against` is HEAD and whose questions are all decided skips straight to step 4 — so `refresh` also serves as "prepare to implement".

## Autonomous approval (`--autonomous`)

Used only by `/implement` in swarm mode, after its up-front design round, when a milestone becomes eligible mid-run. Steps 1–3 as usual; then, instead of asking:

1. Accept each undecided design question's **Proposal**. Record them under `## Reviewer decisions` as `### YYYY-MM-DD (autonomous — /implement)` with numbered bullets, and fold each into its question (`**Decision:** …`).
2. For each significant decision (it shapes a contract, a file layout, a user-visible behavior, or carries a cost), invoke `/followup` with `Kind: decision` (or `compromise` when there's an accepted cost, with **Why accepted**) and Origin `— <id> refresh (autonomous)`.
3. A decision that would change the plan (a §Decision, register answer, Stack or gate) is **not** applied: keep the current shape and open a follow-up marked "needs user".
4. A rewrite recommendation (step 3) halts this milestone instead — report it to `/implement`, which halts the milestone and its dependents.
5. Set `Status: approved (YYYY-MM-DD)` and the plan gate line as in step 4 above.
