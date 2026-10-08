# Just-in-time milestone docs

A startable milestone in scope has no doc (preflight step 5): a **writer agent** writes it, this skill approves it without a recheck, and the run goes straight on to implementing it — in this same session. The doc's design happens in the writer's context, not here.

## 1. Write

Launch the writer with the Agent tool — `subagent_type: general-purpose`, `model: "sonnet"` (never a smaller model; `"opus"` when the user asks for it), foreground — with `${CLAUDE_SKILL_DIR}/templates/writer-brief.md` filled in. One writer per milestone. Several startable milestones without docs → one at a time, in plan order, so each writer sees the file ownership the previous one claimed.

It follows the `milestone` skill's single-doc path as that skill's main agent would, so the doc, the index row and the plan's gate (`proposed`, with its link) come back exactly as `/milestone <id>` leaves them. Never write or patch a milestone doc in this session.

A `STOP <reason>` report (the milestone needs a split, a package outside Stack, or the plan is still `draft`) → interactive: tell the user and offer `/milestone <id>`, which can ask them; `--unattended`: stop with `needs-user`.

## 2. No recheck

The doc was written against HEAD a moment ago: skip `/milestone refresh` entirely, and the swarm-readiness check with it — the writer's consistency pass covers the same ground. A "Consistency issues left" line about file ownership, `After:` or a contract is a readiness failure: guided → show it and ask; swarm → offer guided mode for that milestone, or stop (`--unattended`: `needs-user`).

## 3. Approve

This is the one doc approval this skill owns (doc-model, "Who changes what"). From the writer's report — don't re-read the doc to find them:

1. **Open decisions.**
   - Interactive, without `--auto-approve`: ask them with AskUserQuestion in batches of four — the Proposal (Recommended), the Alternative, and "Decide autonomously".
   - `--auto-approve`, `--unattended`, or "Decide autonomously": take the Proposal.
2. **Record each one** by rewriting its `D<n>` bullet in the overview to the decided form (doc-model, Milestone doc layout): `(<date>, user)` for an answer; `(<date>, autonomous, FU-NNN)` for a Proposal taken without asking — with a `/followup` (`Kind: decision`, or `compromise` with **Why accepted** when it carries a cost; Origin `— <id> just-in-time approval`) when it shapes a contract, a file layout or user-visible behavior, so the user can review it afterwards. A decision that would change the plan (a §Decision, register answer, Stack or gate) is never applied: keep the current shape and open a follow-up marked "needs user".
3. **Ledger entries the writer listed for re-deferral** → `/followup` Updates.
4. Set `**Status:** approved (<date>)` in the overview and `approved (<date>)` on the plan's gate line.
5. Commit `Add and approve the <M> milestone doc` — the milestone folder, the index, the plan gate and any ledger entries.

## 4. Implement

Continue with the run in this session (SKILL.md rule 15's exception): guided → the first work package; swarm → `.0`. From an interactive session whose swarm scope runs through the loop, start the loop as usual instead.
