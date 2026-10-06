# Plan / milestone doc model

Canonical rules shared by `/impl-plan`, `/milestone`, `/implement`, the `doc-sync` agent, and the global CLAUDE.md Documentation Workflow rule. Change them here first, then check those files for consistency.

## Doc roles

| Doc | Says | Written by | Lifecycle |
|---|---|---|---|
| **Plan** | *What* correct looks like and *in what order*: goal, decisions, spec, milestone gates | `/impl-plan` | Living. Gates change only via reviewed edits; status is one line per milestone |
| **Milestone doc** | *How* one milestone's work is divided: decisions, work packages, checklist, as-built truth — a folder (default) or one file (see Milestone doc layouts) | `/milestone` | `proposed` → `approved` → `in progress` → `landed` (then frozen) |
| **Milestone index** (`<milestones dir>/README.md`) | Documents table, dependency graph, parallelism, protocol, section profile | `/milestone all` | Updated when docs are added/split; no status column |
| **Ledger** (`docs/fu/FU-NNN.md`, one file per entry) | Deferred items, decisions worth revisiting, compromises, accepted limitations | `/followup` only | Entries never deleted; status lives in each entry's front matter |
| **Ledger index** (`docs/follow-ups.md`) | One line per entry, for the user | `fu-index.ps1` (generated) | Regenerated whenever an entry changes. **Agents never read it** — they grep `docs/fu/` |

The plan is the single source of truth for *what*; milestone docs reference it by `§N.M` and never restate it. If they disagree, the plan wins until a reviewed edit changes it.

## Convention detection

A project's existing conventions always beat these defaults. Resolve in this order and stop at the first that answers each item:

1. The project CLAUDE.md's Documentation Workflow section (declared paths, id pattern, ledger path, no-touch list).
2. The milestone index's **Section profile**.
3. Existing files (a project whose docs are single files keeps that layout unless its CLAUDE.md declares the folder layout, e.g. "folder layout from M13"): plan name (`docs/*plan*.md`, `docs/*IMPLEMENTATION*.md`, `docs/*roadmap*.md`), milestone dir and filenames, a `_template.md` in it, one sample milestone doc's headings, the ledger's layout (a `docs/fu/` entry folder, or a legacy single-file ledger and its heading style).
4. Defaults below.

Detect and report as a **conventions profile** (five lines): plan path + header style · milestone dir + id pattern + filename pattern · template/genre (merged default, project `_template.md`, or split design-doc + implementation-record) · layer-specific section names · ledger layout + paths (entry folder and generated index, or legacy single file + heading/anchor style).

A project with its own genre is followed, not migrated: e.g. `r<N>` ids with a `_template.md` and layer-named sections (`## Seam changes — <Project>`), or `mN-<topic>.md` design docs frozen as specs plus `mN-implementation.md` records with checkboxes ticked in the plan. Map the default section list onto theirs rather than adding headings they don't use.

## Defaults (greenfield only)

- Plan: `docs/implementation-plan.md`
- Milestones: one folder per milestone, `docs/milestones/M<n>[a|b]-<kebab-slug>/` (layout below); index `docs/milestones/README.md`
- `M0` = foundation: runnable, testable skeleton plus the first frozen contracts. Add it even if the user's outline starts at M1.
- Split suffixes: `a`/`b` = either **parallel halves under one shared gate** or a **sequential split with separate gates** — the index must say which.
- Work packages: `WP` + the milestone id minus its letter prefix + `.n` — M2 → `WP2.1`, M6a → `WP6a.3`, R4 → `WP4.2`. `.0` = apply reviewer decisions, confirm entry criteria, and pre-edit the shared hotspots; the last WP = verification + doc-sync + ledger. Every other WP is implicitly After `.0`, and the last WP is implicitly After all the others.
- Milestone design questions: `D<n>`, numbered per doc (`### D1. <Title> (Q5, FU-012)`). Never `Q<n>` — that's the plan's register.
- Plan assumptions: `Q<n>` in the assumption register, project-wide; inline uncertainty: `[VERIFY]`.
- Ledger: entries `docs/fu/FU-NNN.md`, generated index `docs/follow-ups.md`.

## Milestone doc layouts

**Folder (default for new docs).** Each reader opens only its slice — in single-file docs every worker, reviewer and doc-sync run read the whole doc, often larger than the code it described.

| File | Holds | Read by | Budget |
|---|---|---|---|
| `overview.md` | Header, objective, scope, what exists, entry criteria, **Decisions** (one bullet per `D<n>`), **Work packages table** (id · title · After · Model · Review · Status), contracts introduced, project sections, acceptance criteria, ledger reconciliation, risks | everyone; workers read it with their WP file | 12 KB |
| `WP<id>.md` | One work package: After, Model, Review, files owned, the decisions/contracts/ledger ids it touches, scope, tests, definition of done | that WP's worker and reviewer | 6 KB — more means split the WP |
| `as-built.md` | Append-only: per-WP notes as work lands, then the landing record, then dated corrections | doc-sync; the next milestone's refresh | — |

- **Decisions have one home:** the `D<n>` bullet in the overview — open (`Proposal / Alternative`) until decided, then `<chosen>. Rejected: <alt> — <why>. (<date>, user)` or `(…, autonomous, FU-NNN)`. No Reviewer decisions section: an autonomous decision or one the user wants to revisit also gets a `kind: decision` ledger entry, linked from the bullet; nothing restates it in the as-built record.
- **No Refresh log:** a refresh is its own commit (`Refresh <M> milestone doc: <what changed>`), so history lives in git.
- **WP status lives in the overview's table** — the WP file carries none.
- Templates: the `milestone` skill's `templates/folder/`.

**Single file (legacy, or a project that declares it).** Everything in one `M<n>-<slug>.md` with the sections of the `milestone` skill's `templates/milestone.md`, including Reviewer decisions and Refresh log; WP markers sit under each WP heading. Landed single-file docs stay as they are — a project can switch to folders for new milestones only.

Rules below that name a section apply to whichever file holds it.

## Status words

**Plan header:** `draft` → `approved (YYYY-MM-DD)` → `in progress — <ids> active` (list every in-progress milestone) → `implemented (YYYY-MM-DD)`.

**Plan gate line** (one per milestone, the only status the plan carries): `not written` · `proposed` · `approved (date)` · `in progress` · `landed (date, <sha>)` · `superseded (→ <doc>)`.

**Milestone doc `Status:`** `proposed` · `approved (YYYY-MM-DD)` · `in progress (WPx.n)` (the WP currently being worked; several when they run concurrently: `in progress (WP4a.2, WP4a.5)`) · `in progress (awaiting user check)` (code complete, only interactive criteria left — counts as code-complete for dependents, does not land) · `☑ landed (YYYY-MM-DD, <sha>)` · `superseded (→ <doc>)`. A milestone lands only when every acceptance criterion passes; landing with one outstanding requires an explicit user decision, recorded as a qualifier (`☑ landed (2026-09-10, abc1234) — interactive check waived by user, see As-built`) and in the As-built record.

**Ledger** (an entry's front-matter `status:`): `open` (optionally `open (re-deferred)`, `open (needs user)`, `open (partially resolved — M4)`) → `done (<sha> or PR #N, YYYY-MM-DD)` / `dropped (reason)`.

**Finding entries:** grep the entry folder's front matter — `status:`, `kind:`, `areas:`, `files:` (repo paths and folders), `revisit:`; the `followup` skill lists the queries. Match a milestone or work package by the files it owns first, then by area. Open an entry only when it matches.

### Ledger kinds

Every entry carries a `kind:` (format owned by the `followup` skill):

| Kind | Meaning | Required extra field |
|---|---|---|
| `deferred` | Planned work moved later, incl. an acceptance criterion transferred to another milestone | `revisit:` owning milestone id or trigger |
| `decision` | A choice made autonomously or on the user's behalf that they may want to revisit | — |
| `compromise` | An accepted cost to keep scope | **Why accepted:** in the body |
| `limitation` | A known gap or constraint (incl. "outside this WP's ownership", "needs another repo") | **Why accepted:** in the body |

**A bare milestone id in `revisit:` blocks that milestone from landing** until the entry is resolved or explicitly re-deferred — this is what stops a deferred criterion from being silently dropped. **Re-deferring** never rewrites the body: append `- **Update (YYYY-MM-DD, <source>):** Revisit when → <new> — <why>`, set `revisit:` to the new value and `status:` to `open (re-deferred)`. (In a legacy single-file ledger the effective Revisit when is the latest such Update, else the field.)

Use commit SHAs (short, backticked) for evidence; PR numbers only when the project uses PRs.

**Work-package markers** (folder layout: the Status cell of the overview's WP table; single file: inline under the WP heading as `**Status: ☑ landed** (<sha>)`; written by `/implement`): `☑ landed (<sha>)` — merged, not reverted, synced · `**Status: ⛔ blocked** (FU-NNN — <why>)` — waiting on a user decision or after a second failure; `⛔ blocked (stubbed — FU-NNN)` when a fail-loud stub stands in for it. A WP with neither marker is open. A reverted merge or a `Stub …` commit never makes a WP landed.

**Staleness:** a milestone doc is *stale* when commits since its `Written against` touch code, the plan or the ledger — the doc's own approval and mode-switch commits don't count. Stale `proposed`/`approved` docs get `/milestone refresh` before implementation.

### Who changes what

Each transition has exactly one owner; nobody else makes it.

| Transition | Owner |
|---|---|
| Plan `draft` → `approved` | `/impl-plan` hand-off, `/milestone` load, or `/implement` preflight (user confirms) |
| Gate `not written` → `proposed` | `/milestone`, only for docs it wrote in that run |
| Doc `proposed` → `approved`, gate → `approved` | `/milestone refresh` (after reviewer decisions; `--autonomous` only when invoked by `/implement` in swarm mode) |
| Doc → `in progress (WPx.n)`; gate → `in progress`; plan header → `in progress — <ids> active` | `/implement`, when it starts work on the milestone (a 1–3 line edit; it knows the values) |
| WP markers `☑ landed` / `⛔ blocked` | `/implement`, after the merge or failure it just handled (never for a reverted merge or a `Stub …` commit) |
| Doc → `in progress (awaiting user check)` | `doc-sync`, when only interactive criteria remain |
| Doc → `☑ landed`; gate → `landed (date, <sha>)` | `doc-sync`, only when all criteria pass (else user decision) |
| Plan header → `implemented` | `doc-sync`, when every gate is landed |
| Doc/gate → `superseded (→ …)` | `/milestone refresh` split/merge/rewrite, user-approved |
| Plan `Execution` default | `/impl-plan` (round 1), or `/milestone mode … from <id>` / `all` |
| Doc `Execution` | `/milestone` (copies the plan default when writing the doc), or `/milestone mode` |

`/implement` owns only the routine progress markers above — values it already knows, so no agent re-reads a doc to write them. Everything that needs evidence (ticking criteria, the as-built record, awaiting user check, landing, `implemented`, ledger status flips) stays with doc-sync; approval stays with `/milestone refresh`.

## Header fields

**Plan:** `**Status:**` · `**Audience:** Claude Code (and humans reviewing its work)` · `**Execution:** guided | swarm` (default for milestone docs not yet written) · `**Companions:**` (spec docs, ledger, milestone index) · `**Written against:** \`<sha>\` (date)` · `**Last updated:** <date> — <one line>`. One line only — history lives in git and the milestone as-built records. Existing plans with a "Previously:" chain or a "Status as of" section keep their style.

**Milestone doc** (the overview in the folder layout): `**Status:**` · `**Depends on:**` (id + what it provides) · `**Blocks:**` · `**Can run alongside:**` · `**Execution:** guided | swarm` · `**Work packages:** N` · `**Written against:** \`<sha>\` (date)` · then a line `Spec source: §8 M2, §6.3.`

`Written against` is what makes `/milestone refresh` mechanical: everything since that sha is what the doc hasn't seen.

## Execution modes

How a milestone gets implemented — not how its doc is written. **Docs are always swarm-ready**, whatever the mode, so switching never needs a rewrite.

- **guided** — work packages run one at a time in the main session, pausing for the user after each (implement → stack review → commit → doc-sync).
- **swarm** — parallel worker agents in git worktrees, as far as `After:` ordering and file ownership allow; a coordinator (the main session) merges each finished WP and runs doc-sync once per merged wave.

What "swarm-ready" requires of every milestone doc:

- Each work package declares `**After:** <WP ids> | —` — the WPs that must land before it starts. Anything `After:` leaves unordered may run concurrently.
- **File ownership is exclusive** between WPs that `After:` leaves unordered, within a doc and across docs that can run alongside each other.
- **`WP<n>.0` owns the shared hotspots** — package references, project/solution files, registries, DI wiring — that the other WPs would otherwise each edit. Parallel WPs never touch them.
- Contracts consumed across WPs are specified as code blocks in Contracts introduced, so parallel WPs code against the same shape.
- Workers never edit the plan, milestone docs, index, ledger, README or CLAUDE.md.

Every WP also declares **`Model:`** — `sonnet` (default: frozen contract, named files, decided questions) or `opus` (new public API design, a `[VERIFY]` or research into a third-party library, tricky lifetime or concurrency logic) — and **`Review:`** — `full` (library or public code, concurrency, lifetimes) or `light` (sandbox, demo, tool or test-only code).

## Links

- Relative paths only. Plan → milestone: `milestones/M2-<slug>/overview.md` (single file: `milestones/M2-<slug>.md`). Milestone → plan: `../../<plan>.md#<anchor>` from a milestone folder (`../<plan>.md` from a single file) or just `§N.M` in prose.
- Milestone → ledger: the relative path to the entry file — `../fu/FU-012.md` from `docs/milestones/<doc>.md`, `../../fu/FU-012.md` from a milestone folder. Ledger ids in tables are links too: `| [FU-012](../fu/FU-012.md) | … |`. Legacy single-file ledgers: `../follow-ups.md#fu-nnn` (explicit anchors) or GitHub's slug of the full heading — never `./follow-ups.md` from inside `docs/milestones/`. Links of that form keep working after migration (the generated index keeps the anchors).
- Milestone → milestone: by id in prose (`M0's IPolicyHandler`, `WP6a.3 owns the table`), file link on first mention.

## Content rules

- **Silence is deliberate:** never delete a template heading; an empty section says `None — <reason>`. Sole exception: the milestone template's `<Project obligation>` placeholder is replaced by the Section profile's sections, or removed when the profile is "Default sections only".
- **Reference, don't restate:** cite `§N.M`; restating the spec in a milestone doc creates two sources of truth.
- **Every out-of-scope item cites its owner** (another milestone, a non-goal, a ledger entry) so it isn't re-litigated mid-implementation.
- **Decisions are Chosen vs Rejected with reasons** — one line each where possible; "do not re-litigate §Decisions" is a rule, not a suggestion. A reversal is a dated, reviewed edit, never a silent rewrite.
- **Acceptance criteria are observable** by a test or a command. Ticked: `- [x] <criterion> — <TestClass.Method / command → output>`. Unmet: stays `- [ ]` with a **bold reason**. Never tick on faith or on a commit message.
- **Contracts are frozen at the doc that introduces them.** A consumer needing a different shape records a deviation in its own as-built record and a back-note on the owner's.
- **File ownership is exclusive** between work packages that can run concurrently. A later milestone extending an earlier one's file marks it `*(M0-owned — extended here)*`, and the owner must be an ancestor in the dependency graph.
- **Append-only history:** As-built records, Refresh logs (single-file docs), plan Last-updated, ledger entry bodies. Later As-built additions and corrections are dated H3s (`### YYYY-MM-DD — <event>`); the stale text stays so the mistake remains visible.
- **Deferred criteria never vanish:** an acceptance criterion that can't pass in its milestone stays `- [ ]` with a **bold reason** citing a `Kind: deferred` ledger entry whose `Revisit when` names the later milestone that now owns it.
- **Not-implemented exemplars use reserved fake names** (`x-not-a-real-element`), never a real feature that simply isn't built yet — those tests break the day a later WP builds it.
- **No unapproved dependencies:** a work package may only use packages in the plan's Stack section. A new one needs user approval (what it does / the no-dependency alternative) and a Stack edit first.
- **Uncertainty is explicit:** `[VERIFY]` inline plus an assumption-register row with an owning milestone. The owner resolves it in place and removes the tag; the register records Answer + Basis (`documented` / `toolkit` / `assumed`) + the test that pins it. "`assumed` after a bounded search" is a legitimate outcome.

## Style

Second-person imperative ("Do not start M3 until…"). Dense rationale — say *why*, including the cost of getting it wrong. Bold for load-bearing rules. Em dashes as separators. Backticked identifiers, paths, and SHAs. Plan sections numbered `## N. Title` and separated by `---`; milestone docs use unnumbered `##` sections in the fixed template order. Tables for inventories and registers, prose for reasoning. No filler, no marketing tone.
