# Just-in-time milestone docs

A startable milestone in scope has no doc (preflight step 5): a **writer agent** writes it, this skill approves it without a recheck, and the run goes straight on to implementing it — in this same session. The doc's design happens in the writer's context, not here.

**The user's waiting time is the constraint.** Their questions reach them within about three minutes, the slow work runs while they answer, and nothing asks them anything after their last answer.

## 1. Scan

Launch the writer as early as preflight allows — right after the resume check, alongside the baseline build, before any question to the user: Agent tool, `subagent_type: general-purpose`, `model: "sonnet"` (never a smaller model; `"opus"` when the user asks for it), in the background (`--unattended`: in the **foreground** — a session that waits idle on a background writer dies after ten minutes), with `${CLAUDE_SKILL_DIR}/templates/writer-brief.md` filled in. One writer per milestone; several startable milestones without docs → one at a time, in plan order, so each writer sees the file ownership the previous one claimed.

Its first hand-back, after about two minutes, is the **scan report**: the work packages it intends and the decisions only the user can make. It follows the `milestone` skill's single-doc path as that skill's main agent would. Never write or patch a milestone doc in this session.

- `STOP <reason>` (a package outside Stack, or the plan is still `draft`), in the scan or later in the doc report → interactive: tell the user and offer `/milestone <id>`, which can ask them; `--unattended`: stop with `needs-user`. Anything the writer already wrote stays uncommitted for that.
- `--unattended`: the brief's unattended mode — no scan hand-back, the writer goes straight through and step 2 is skipped. A `Split suggestion` in its doc report → stop with `needs-user` before approving.

## 2. Ask while it writes

The scan writes nothing, so it can run during preflight; the writer is **resumed to write only once the baseline is green and the plan is approved** (preflight steps 3–4) — a run that stops there leaves no half-written doc. Then, in this order and without waiting:

0. **A split suggestion in the scan is asked first, alone, before the writer is resumed** — also under `--auto-approve`: go on as one milestone, or stop here and split it with `/milestone <id>`.
1. **Resume the writer** with SendMessage to its agent id (load the tool with ToolSearch if it isn't listed): "Write the doc, assuming your Proposals." It keeps its context and writes in the background.
2. **Ask the user** the scan's decisions with AskUserQuestion, in batches of four: the Proposal (Recommended), the Alternative, and "Decide autonomously". With `--auto-approve`, ask none of them. Before a round that follows a wait on background work, send one PushNotification naming the milestone and what is waiting (`M41: 4 decisions waiting — saves, page size, layers, line art`); load the tool with ToolSearch if it isn't listed, and carry on without it if it is unavailable. Not for a round that follows the user's own answer.
3. Note every answer that differs from its Proposal — those are the **amendments**.

## 3. Finish the doc

When the writer's doc report is back and the answers are in, whichever comes last:

- Amendments → send them to the writer in **one** SendMessage; it reworks the affected files and reports again. None → nothing to do.
- **No recheck.** The doc was written against HEAD moments ago: skip `/milestone refresh` entirely, and the swarm-readiness check with it — the writer's consistency pass covers the same ground. A "Consistency issues left" line about file ownership, `After:` or a contract is a readiness failure: guided → show it and ask; swarm → offer guided mode for that milestone, or stop (`--unattended`: `needs-user`).

## 4. Approve

This is the one doc approval this skill owns (doc-model, "Who changes what"). From the writer's reports — don't re-read the doc:

1. **Record each raised decision** by rewriting its `D<n>` bullet in the overview to the decided form (doc-model, Milestone doc layout): `(<date>, user)` for an answer; `(<date>, autonomous, FU-NNN)` for a Proposal taken without asking (`--auto-approve`, `--unattended`, "Decide autonomously") — with a `/followup` (`Kind: decision`, or `compromise` with **Why accepted** when it carries a cost; Origin `— <id> just-in-time approval`) so the user can review it afterwards. The decisions the writer settled itself are already decided bullets; leave them. A decision that would change the plan (a §Decision, register answer, Stack or gate) is never applied: keep the current shape and open a follow-up marked "needs user".
2. **Ledger entries the writer listed for re-deferral** → `/followup` Updates.
3. Set `**Status:** approved (<date>)` in the overview and `approved (<date>)` on the plan's gate line.
4. Commit `Add and approve the <M> milestone doc` — the milestone folder, the index, the plan gate and any ledger entries.

## 5. Implement

Continue with the run in this session, without another prompt (SKILL.md rule 15's exception): guided → the first work package; swarm → `.0`. From an interactive session whose swarm scope runs through the loop, start the loop as usual instead.
