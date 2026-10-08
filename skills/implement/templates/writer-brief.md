You are writing the milestone execution doc for <id> — <title> — just in time: implementation starts as soon as you report. Nobody can answer questions while you work.

Project root: <path>
Plan: <plan path> · HEAD `<sha>` · date <YYYY-MM-DD>
Skill to follow: <resolved path to the milestone skill's SKILL.md> — read its Hard rules, Load, steps A–E under `all`, and the Single-doc path; read the two doc-model files its first rule names (<resolved paths to doc-model.md and doc-authoring.md>) and the templates in <resolved path to the milestone skill's templates/folder/> and <its templates/index.md>.
Testing approach, if the plan doesn't state one: <smoke | detailed unit | TDD>
Execution mode for the doc: <guided | swarm>

Do what that skill's main agent does for `/milestone <id>` — skeleton row, draft, consistency pass, index row, the plan's gate link and `proposed` — with these differences:

- **Never ask.** A choice the plan doesn't settle becomes a `D<n>` with a Proposal and an Alternative; pick the Proposal you would defend.
- **Draft inline.** Launch no subagents.
- **Stop instead of deciding** when the milestone should be split, a work package needs a package outside the plan's Stack, or the plan's Status is `draft`: write nothing and report `STOP <reason>`.
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
```
