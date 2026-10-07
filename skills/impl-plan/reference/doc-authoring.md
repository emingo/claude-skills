# Authoring plans and milestone docs

For the skills that write docs — `/impl-plan`, `/milestone` and their drafting and critique subagents. Read `doc-model.md` (same folder) first: doc roles, layout, status words and execution modes are there.

## Convention detection

A project's existing conventions always beat these defaults. Resolve in this order and stop at the first that answers each item:

1. The project CLAUDE.md's Documentation Workflow section (declared paths, id pattern, ledger path, no-touch list).
2. The milestone index's **Section profile**.
3. Existing files: plan name (`docs/*plan*.md`, `docs/*IMPLEMENTATION*.md`, `docs/*roadmap*.md`), milestone dir and filenames, a `_template.md` in it, one sample milestone doc's headings, the ledger's entry folder (`docs/fu/`).
4. Defaults below.

Detect and report as a **conventions profile** (five lines): plan path + header style · milestone dir + id pattern + filename pattern · template/genre (merged default, project `_template.md`, or split design-doc + implementation-record) · layer-specific section names · ledger paths (entry folder and generated index).

A project with its own genre is followed, not migrated: e.g. `r<N>` ids with a `_template.md` and layer-named sections (`## Seam changes — <Project>`), or `mN-<topic>.md` design docs frozen as specs plus `mN-implementation.md` records with checkboxes ticked in the plan. Map the default section list onto theirs rather than adding headings they don't use.

## Defaults (greenfield only)

- Plan: `docs/implementation-plan.md`
- Milestones: one folder per milestone, `docs/milestones/M<n>[a|b]-<kebab-slug>/` (layout below); index `docs/milestones/README.md`
- `M0` = foundation: runnable, testable skeleton plus the first frozen contracts. Add it even if the user's outline starts at M1.
- Split suffixes: `a`/`b` = either **parallel halves under one shared gate** or a **sequential split with separate gates** — the index must say which.
- Work packages: `WP` + the milestone id minus its letter prefix + `.n` — M2 → `WP2.1`, M6a → `WP6a.3`, R4 → `WP4.2`. `.0` = apply reviewer decisions, confirm entry criteria, and pre-edit the shared hotspots; every other WP is implicitly After `.0`. There is no verification WP (doc-model, Milestone doc layout).
- Milestone design questions: `D<n>`, numbered per doc (`### D1. <Title> (Q5, FU-012)`). Never `Q<n>` — that's the plan's register.
- Plan assumptions: `Q<n>` in the assumption register, project-wide; inline uncertainty: `[VERIFY]`.
- Ledger: entries `docs/fu/FU-NNN.md`, generated index `docs/follow-ups.md`.

## Header fields

**Plan:** `**Status:**` · `**Execution:** guided | swarm` (default for milestone docs not yet written) · `**Written against:** \`<sha>\` (date)`. Nothing else: history lives in git and the as-built records. An existing plan with more header lines (`Last updated`, a "Previously:" chain, a "Status as of" section) keeps its style.

**Milestone doc** (the overview): `**Status:**` · `**Depends on:**` (id + what it provides) · `**Blocks:**` · `**Can run alongside:**` · `**Execution:** guided | swarm` · `**Written against:** \`<sha>\` (date)` · then a line `Spec source: §8 M2, §6.3.`

## Links

- Relative paths only. Plan → milestone: `milestones/M2-<slug>/overview.md`. Milestone → plan: `../../<plan>.md#<anchor>` or just `§N.M` in prose.
- Milestone → ledger: the relative path to the entry file — `../../fu/FU-012.md` from a milestone folder — never the generated index. Ledger ids in tables are links too: `| [FU-012](../../fu/FU-012.md) | … |`.
- Milestone → milestone: by id in prose (`M0's IPolicyHandler`, `WP6a.3 owns the table`), file link on first mention.

## Content rules

- **Omit what's empty:** a section the template marks Optional is left out when it has nothing to say; every other heading stays, and an empty one says `None — <reason>`. The milestone template's `<Project obligation>` placeholder is replaced by the Section profile's sections, or removed when the profile is "Default sections only".
- **Reference, don't restate:** cite `§N.M`; restating the spec in a milestone doc creates two sources of truth.
- **Every out-of-scope item cites its owner** (another milestone, a non-goal, a ledger entry) so it isn't re-litigated mid-implementation.
- **Decisions are Chosen vs Rejected with reasons** — one line each where possible; "do not re-litigate §Decisions" is a rule, not a suggestion. A reversal is a dated, reviewed edit, never a silent rewrite.
- **Acceptance criteria are observable** by a test or a command. Ticked: `- [x] <criterion> — <TestClass.Method / command → output>`. Unmet: stays `- [ ]` with a **bold reason**. Never tick on faith or on a commit message.
- **Contracts are frozen at the doc that introduces them.** A consumer needing a different shape records a deviation in its own as-built record and a back-note on the owner's.
- **File ownership is exclusive** between work packages that can run concurrently. A later milestone extending an earlier one's file marks it `*(M0-owned — extended here)*`, and the owner must be an ancestor in the dependency graph.
- **Append-only history:** As-built records and ledger entry bodies. Later As-built additions and corrections are dated H3s (`### YYYY-MM-DD — <event>`); the stale text stays so the mistake remains visible.
- **Deferred criteria never vanish:** an acceptance criterion that can't pass in its milestone stays `- [ ]` with a **bold reason** citing a `Kind: deferred` ledger entry whose `Revisit when` names the later milestone that now owns it.
- **Not-implemented exemplars use reserved fake names** (`x-not-a-real-element`), never a real feature that simply isn't built yet — those tests break the day a later WP builds it.
- **No unapproved dependencies:** a work package may only use packages in the plan's Stack section. A new one needs user approval (what it does / the no-dependency alternative) and a Stack edit first.
- **Uncertainty is explicit:** `[VERIFY]` inline plus an assumption-register row with an owning milestone. The owner resolves it in place and removes the tag; the register records Answer + Basis (`documented` / `toolkit` / `assumed`) + the test that pins it. "`assumed` after a bounded search" is a legitimate outcome.

## Style

Second-person imperative ("Do not start M3 until…"). Dense rationale — say *why*, including the cost of getting it wrong. Bold for load-bearing rules. Em dashes as separators. Backticked identifiers, paths, and SHAs. Plan sections numbered `## N. Title` and separated by `---`; milestone docs use unnumbered `##` sections in the fixed template order. Tables for inventories and registers, prose for reasoning. No filler, no marketing tone.
