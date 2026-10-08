# Plan / milestone doc model

Canonical rules shared by `/impl-plan`, `/milestone`, `/implement`, `/walkthrough`, the `doc-sync` agent, and the global CLAUDE.md Documentation Workflow rule: what each doc is, its status words, and who changes them. Rules for *writing* plans and milestone docs (conventions, header fields, links, content rules, style) are in `doc-authoring.md` next to this file — only `/impl-plan` and `/milestone` need it.

## Doc roles

| Doc | Says | Written by | Lifecycle |
|---|---|---|---|
| **Plan** | *What* correct looks like and *in what order*: goal, decisions, spec, milestone gates | `/impl-plan` | Living. Gates change only via reviewed edits; status is one line per milestone |
| **Milestone doc** | *How* one milestone's work is divided: decisions, work packages, checklist, as-built truth — a folder (see Milestone doc layout) | `/milestone` | `proposed` → `approved` → `in progress` → `landed` (then frozen) |
| **Milestone index** (`<milestones dir>/README.md`) | Documents table, parallelism matrix, section profile | `/milestone all` | Updated when docs are added/split; no status column |
| **Ledger** (`docs/fu/FU-NNN.md`, one file per entry) | Deferred items, decisions worth revisiting, compromises, accepted limitations | `/followup` only | Entries never deleted; status lives in each entry's front matter |
| **Ledger index** (`docs/follow-ups.md`) | One line per entry, for the user | `fu-index.ps1` (generated) | Regenerated whenever an entry changes. **Agents never read it** — they grep `docs/fu/` |

Paths come from the project CLAUDE.md's Documentation Workflow section; without one: plan `docs/implementation-plan.md`, milestones `docs/milestones/<id>-<slug>/`, ledger `docs/fu/`. Full convention detection is in `doc-authoring.md`.

The plan is the single source of truth for *what*; milestone docs reference it by `§N.M` and never restate it. If they disagree, the plan wins until a reviewed edit changes it.

## Milestone doc layout

A folder per milestone, so each reader opens only its slice.

| File | Holds | Read by | Budget |
|---|---|---|---|
| `overview.md` | Header, objective, scope, what exists, entry criteria, **Decisions** (one bullet per `D<n>`), **Work packages table** (id · title · After · Model · Review · Status), contracts introduced, project sections, acceptance criteria, risks | everyone; workers read it with their WP file | aim for 12 KB, 16 KB at most |
| `WP<id>.md` | One work package: After, Model, Review, files owned, the decisions/contracts it touches, the open ledger entries overlapping its files (each with a disposition), scope, tests, definition of done | that WP's worker and reviewer | 6 KB — more means split the WP |
| `as-built.md` | Append-only, and only what differs from the docs: a note per WP that deviated, the landing record, then dated corrections | doc-sync; the next milestone's refresh | — |

- **Decisions have one home:** the `D<n>` bullet in the overview — open (`Proposal / Alternative`) until decided, then `<chosen>. Rejected: <alt> — <why>. (<date>, user)` or `(…, autonomous)` — with `FU-NNN` when the decision has a ledger entry. A Proposal taken on the user's behalf, or a decision they want to revisit, also gets a `kind: decision` ledger entry, linked from the bullet; nothing restates it in the as-built record.
- **A refresh is its own commit** (`Refresh <M> milestone doc: <what changed>`) — the doc carries no refresh log.
- **WP status lives in the overview's table** — the WP file carries none.
- **Verification is not a work package.** Once every WP is landed, `/implement` runs the overview's Acceptance criteria and doc-sync lands the milestone. A doc written before this rule whose last WP is "verification" → that WP is this step: never run it as a work package or launch a worker for it; `/implement` marks its row `☑ landed` when it sets `in progress (verification)`.
- Templates: the `milestone` skill's `templates/folder/`.

**Older single-file docs and ledgers are not supported.** A landed `M<n>-<slug>.md` is frozen history — read its As-built section when a later milestone depends on it, never edit it. An unlanded single-file milestone doc, or a ledger kept as one file → stop and tell the user to rewrite the doc with `/milestone <id>` or migrate the ledger with the `followup` skill's `scripts/fu-migrate.ps1`. Exception: a project whose CLAUDE.md declares its own milestone genre (its `_template.md`, a design-doc + implementation-record split) keeps writing that genre with `/milestone`, but `/implement` and doc-sync's milestone transitions don't apply to it — say so and stop rather than suggesting a rewrite.

## Status words

**Plan header:** `draft` → `approved (YYYY-MM-DD)` → `in progress — <ids> active` (list every in-progress milestone) → `implemented (YYYY-MM-DD)`.

**Plan gate line** (one per milestone, the only status the plan carries): `not written` · `proposed` · `approved (date)` · `in progress` · `landed (date, <sha>)` · `superseded (→ <doc>)`.

**Milestone doc `Status:`** `proposed` · `approved (YYYY-MM-DD)` · `in progress (WPx.n)` (the WP currently being worked; several when they run concurrently: `in progress (WP4a.2, WP4a.5)`) · `in progress (verification)` (every WP landed, acceptance criteria being run) · `in progress (awaiting user check)` (code complete, only interactive criteria left — counts as code-complete for dependents, does not land) · `☑ landed (YYYY-MM-DD, <sha>)` · `superseded (→ <doc>)`. A milestone lands only when every acceptance criterion passes; landing with one outstanding requires an explicit user decision, recorded as a qualifier (`☑ landed (2026-09-10, abc1234) — interactive check waived by user, see As-built`) and in the As-built record.

**Ledger** (an entry's front-matter `status:`): `open` (optionally `open (re-deferred)`, `open (needs user)`, `open (partially resolved — M4)`) → `done (<sha> or PR #N, YYYY-MM-DD)` / `dropped (reason)`.

**Linking entries:** by relative path to the entry file — `../../fu/FU-012.md` from a milestone folder — never to the generated index.

**Finding entries:** grep the entry folder's front matter — `status:`, `kind:`, `areas:`, `files:` (repo paths and folders), `revisit:`; the `followup` skill lists the queries. Match a milestone or work package by the files it owns first, then by area. Open an entry only when it matches.

### Ledger kinds

Every entry carries a `kind:` (format owned by the `followup` skill):

| Kind | Meaning | Required extra field |
|---|---|---|
| `deferred` | Planned work moved later, incl. an acceptance criterion transferred to another milestone | `revisit:` owning milestone id or trigger |
| `decision` | A choice made autonomously or on the user's behalf that they may want to revisit | — |
| `compromise` | An accepted cost to keep scope | **Why accepted:** in the body |
| `limitation` | A known gap or constraint (incl. "outside this WP's ownership", "needs another repo") | **Why accepted:** in the body |

**A bare milestone id in `revisit:` blocks that milestone from landing** until the entry is resolved or explicitly re-deferred — this is what stops a deferred criterion from being silently dropped. **Re-deferring** never rewrites the body: append `- **Update (YYYY-MM-DD, <source>):** Revisit when → <new> — <why>`, set `revisit:` to the new value and `status:` to `open (re-deferred)`.

Use commit SHAs (short, backticked) for evidence; PR numbers only when the project uses PRs.

**Work-package markers** (the Status cell of the overview's WP table; written by `/implement`): `☑ landed` (guided: written in the WP's own commit) or `☑ landed (<merge sha>)` (swarm) — committed or merged, and not reverted · `⛔ blocked (FU-NNN — <why>)` — waiting on a user decision or after a second failure; `⛔ blocked (stubbed — FU-NNN)` when a fail-loud stub stands in for it. A WP with neither marker is open. A reverted merge or a `Stub …` commit never makes a WP landed.

**Staleness:** a milestone doc is *stale* when commits since its `Written against` touch code, the plan or the ledger — the doc's own approval and mode-switch commits don't count. Stale `proposed`/`approved` docs get `/milestone refresh` before implementation.

### Who changes what

Each transition has exactly one owner; nobody else makes it.

| Transition | Owner |
|---|---|
| Plan `draft` → `approved` | `/impl-plan` hand-off, `/milestone` load, or `/implement` preflight (user confirms) |
| Gate `not written` → `proposed` | `/milestone`, only for docs it wrote in that run (or `/implement`'s just-in-time writer agent, which follows `/milestone`) |
| Doc `proposed` → `approved`, gate → `approved` | `/milestone refresh` (after reviewer decisions; `--autonomous` only when invoked by `/implement` in swarm mode) — or `/implement` itself for a doc its writer agent wrote just in time, where there is nothing to recheck |
| Doc → `in progress (WPx.n)` / `in progress (verification)`; gate → `in progress`; plan header → `in progress — <ids> active` | `/implement`, when it starts work on the milestone (a 1–3 line edit; it knows the values) |
| WP markers `☑ landed` / `⛔ blocked` | `/implement`, with the commit or after the merge or failure it just handled (never for a reverted merge or a `Stub …` commit) |
| Doc → `in progress (awaiting user check)` | `doc-sync`, when only interactive criteria remain |
| Doc → `☑ landed`; gate → `landed (date, <sha>)` | `doc-sync`, only when all criteria pass (else user decision) |
| Plan header → `implemented` | `doc-sync`, when every gate is landed |
| Doc/gate → `superseded (→ …)` | `/milestone refresh` split/merge/rewrite, user-approved |
| Plan `Execution` default | `/impl-plan` (round 1), or `/milestone mode … from <id>` / `all` |
| Doc `Execution` | `/milestone` (copies the plan default when writing the doc), or `/milestone mode` |

## Execution modes

How a milestone gets implemented — not how its doc is written. **Docs are always swarm-ready**, whatever the mode, so switching never needs a rewrite.

- **guided** — work packages run one at a time in the main session, pausing for the user after each (implement → stack review → one commit); doc-sync runs once, when the milestone lands.
- **swarm** — parallel worker agents in git worktrees, as far as `After:` ordering and file ownership allow; a coordinator (the main session) merges each finished WP and runs doc-sync once per merged wave.

What "swarm-ready" requires of every milestone doc:

- Each work package declares `**After:** <WP ids> | —` — the WPs that must land before it starts. Anything `After:` leaves unordered may run concurrently.
- **File ownership is exclusive** between WPs that `After:` leaves unordered, within a doc and across docs that can run alongside each other.
- **`WP<n>.0` owns the shared hotspots** — package references, project/solution files, registries, DI wiring — that the other WPs would otherwise each edit. Parallel WPs never touch them.
- Contracts consumed across WPs are specified as code blocks in Contracts introduced, so parallel WPs code against the same shape.
- Workers never edit the plan, milestone docs, index, ledger, README or CLAUDE.md.

Every WP also declares **`Model:`** — `sonnet` (the default worker; which model that is belongs to `/implement`, which may run it on a smaller one) or `opus`, only when the WP must make a design choice the doc doesn't settle: an open `[VERIFY]` or research into a third-party library, or a public API whose shape isn't given as a contract code block. Hard logic against a frozen contract (concurrency, lifetimes) is `sonnet` with `Review: full`, not `opus` — expect at most a third of a milestone's WPs on `opus`. **`Review:`** — `full` (library or public code, concurrency, lifetimes; reviewed on Opus) or `light` (sandbox, demo, tool or test-only code; reviewed on Sonnet).
