You are writing the milestone execution doc for <id> — <title> — just in time: implementation starts as soon as you finish. The user is waiting for your questions, so you work in two passes.

Project root: <path>
Plan: <plan path> · HEAD `<sha>` · date <YYYY-MM-DD>
Skill to follow: <resolved path to the milestone skill's SKILL.md> — its Hard rules, Load, steps A–E under `all`, and the Single-doc path; the two doc-model files its first rule names (<resolved paths to doc-model.md and doc-authoring.md>); the templates in <resolved path to the milestone skill's templates/folder/> and <its templates/index.md>.
Testing approach, if the plan doesn't state one: <smoke | detailed unit | TDD>
Execution mode for the doc: <guided | swarm>
Mode: <interactive | unattended>

## Pass 1 — scan (interactive only; about ten tool calls)

Read just enough to know the work packages and what you must ask: this milestone's gate in the plan, the `§` sections it cites, the neighbouring milestones' header blocks, and the names of the files and types involved (Glob and Grep — no whole source files yet). Don't read the skill or the templates yet. Then hand back exactly this and stop; you will be resumed with "Write the doc":

```
SCAN <id>
Work packages:
- WP<n>.0 <title> — <files or folders>
Decisions for the user:
- D1 <title> — Proposal: <one line> · Alternative: <one line>
(or: none)
Split suggestion: <only when it needs more than about 8 work packages: where to cut it, and why> (or: none)
```

**What counts as a decision for the user:** a choice the plan doesn't settle that shapes a contract, a file layout or behaviour the user will see. Everything else you decide yourself and never ask — in the doc it is a decided bullet, `<chosen>. Rejected: <alternative> — <why>. (<date>, autonomous)`.

`Mode: unattended` → skip this pass and its hand-back; go straight through pass 2 with your own Proposals.

## Pass 2 — write

Do what that skill's main agent does for `/milestone <id>` — skeleton row, draft, consistency pass, index row, the plan's gate link and `proposed` — with these differences:

- **Never ask.** The decisions you raised in the scan stay open bullets with your Proposal and Alternative; write the work packages as if each Proposal holds. A choice you only meet now, you settle yourself as a decided `(<date>, autonomous)` bullet — the user has already been asked. (`Mode: unattended`: there was no scan, so the choices that would have been decisions for the user are the open bullets.)
- **Draft inline.** Launch no subagents.
- **Write each file once.** WP files first, the overview last, when you know what it has to hold: one line per decision, contracts as signatures. Aim for 12 KB; up to 16 KB is fine; at most one trimming pass. A WP file over 6 KB means the WP is too big — split the WP.
- **Stop instead of deciding** when a work package needs a package outside the plan's Stack, or the plan's Status is `draft`: write nothing and report `STOP <reason>`.
- **Never commit, and never write to the ledger.** Open entries that overlap go into the owning WP's `Ledger:` field; one that no WP takes is listed in your report for re-deferral.
- Stay inside the milestone's folder, the index and this milestone's gate block in the plan.

Report exactly this, nothing else:

```
<id> — <folder path> — overview <KB> / largest WP <KB> / <n> WPs
Open decisions:
- D1 <title> — Proposal: <one line> · Alternative: <one line>
(or: none)
Opus WPs: <WP id — the unsettled choice> (or: none)
Consistency issues left: <list, or none>
Ledger entries to re-defer: <FU id — why> (or: none)
Split suggestion: <unattended mode only — where to cut a milestone of more than about 8 work packages> (or: none)
```

**Amendments.** If you are resumed with answers that differ from your Proposals, change only the files those answers affect, leave the decision bullets open (the main session records the answers), and send the same report again.
