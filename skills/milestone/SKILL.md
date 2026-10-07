---
name: milestone
description: Write or refresh milestone execution docs from the project's implementation plan — a folder per milestone with an overview (decisions, acceptance checklist, ledger reconciliation), one small file per commit-sized work package with exclusive file ownership, and an append-only as-built record. /milestone all writes the docs for the next milestones that can start (just in time; --full for every one) plus the index; /milestone <id> writes one; /milestone next picks the next unblocked one; /milestone refresh <id> re-validates a doc written ahead of time against current code, landed as-built records and the follow-up ledger, then records reviewer decisions and marks it approved; /milestone mode <guided|swarm> [<id> | from <id> | all] switches how milestones get implemented. Use when the user asks to split a plan into milestones/phases/steps, to switch milestones between guided and agent-swarm implementation, or before starting implementation of a milestone whose doc is still proposed/approved and stale.
argument-hint: "[all | next | <id> | refresh <id> | mode <guided|swarm> [<id> | from <id> | all]]"
allowed-tools: Bash(git log *) Bash(git show *) Bash(git diff *) Bash(git rev-parse *) Bash(git status *)
---

# /milestone — milestone execution docs

Arguments: $ARGUMENTS

## Hard rules

- **Read `${CLAUDE_SKILL_DIR}/../impl-plan/reference/doc-model.md` and `doc-authoring.md` (same folder) first** — doc roles, layout, status words and who changes them; convention detection, ids, header fields, links, content rules, style. Everything below assumes them.
- **Never edit a landed doc** (`☑ landed`). Point the user at a dated As-built correction or a new milestone instead.
- **Never touch an `in progress` doc** except on an explicit `refresh <id>` from the user — and then never change its Status — or via `mode`, which changes only its `Execution` field (for the remaining WPs).
- **Never overwrite an existing doc wholesale** — that's what `refresh` is for.
- **Never commit.** Suggest the commit message at the end.
- **Never create the ledger or write entries by hand** — `/followup` only.
- **Stay within the size budgets** (doc-model, Milestone doc layout): overview ≤ 12 KB, each WP file ≤ 6 KB. Reference the plan by `§`, put a decision's reasoning in one line, and split a WP that won't fit.
- **Never delete a template heading** (`None — <reason>`); strip every `<!-- guidance -->` comment. Sole exception: the `<Project obligation>` placeholder becomes the Section profile's sections, or is removed when the profile is "Default sections only".
- **No work package introduces a dependency outside the plan's Stack.** If one is needed, ask the user (what it does / the no-dependency alternative) before drafting, and edit Stack only on approval.
- **Skeleton fields are the main agent's alone:** dependencies, work-package file ownership, contracts, acceptance criteria, Section profile. Drafting subagents may object, never change them.
- **Follow the project's genre** when it has one (its `_template.md`, its section names, a split design-doc/implementation-record model) — map this skill's sections onto theirs.

## Load (every mode)

1. Conventions profile per doc-authoring.md (print it in five lines on first use this session).
2. The plan — header (incl. `Execution`; missing → `guided`), Decisions, Stack, Conventions, Milestones section and dependency graph, Testing strategy, assumption register. No plan → stop and suggest `/impl-plan`. No testing strategy in the plan → ask the three-option testing question (smoke / detailed unit / TDD) once.
3. The milestone index (if any) and the header block of each existing milestone doc (Status, Depends on, Blocks, Execution, Written against).
4. The ledger's open entries — grep the entry folder's front matter (doc-model "Finding entries"); never the generated index.
5. `git rev-parse --short HEAD` and today's date.

Unless the mode is read-only: if the plan's Status is `draft`, ask once "Treat the plan as approved?" — yes sets `approved (<date>)`; no stops with "review the plan first".

Dependencies come from each doc's `Depends on`, or from the plan's dependency graph for milestones without a doc.

## Modes

| Arguments | Behavior |
|---|---|
| *(none)* | No milestone docs yet → `all`. Otherwise **read-only**: print a status table (id · doc · Status · Execution · Written against · blocked by) and suggest `next`. |
| `all` | **Just in time:** write docs (steps A–E) only for milestones that can start soon — the first milestone in plan order that isn't landed or awaiting a check, the ones that can run alongside it, and at most two more beyond those whose dependencies are among them. Every other gate stays `not written`, and the report says `/milestone next` — or `/implement`, which invokes this skill for a startable milestone without a doc — writes it when it comes up. `all --full` writes every missing doc. Then the index. Existing docs are read into the skeleton as fixed rows; unlanded ones are listed with an offer to refresh. |
| `<id>` | Case-insensitive, normalized to the project's scheme (`m3` → `M3`). If it names a split parent (`M3` with `M3a`/`M3b`): parallel halves → act on each; sequential → the first unlanded half. Then: no doc → write it (single-doc path below); `proposed`/`approved` → `refresh`; `in progress (WP…)` → report it as the active milestone and its first open WP; `awaiting user check` → say so and suggest `/implement <id>` to confirm the checks; landed → refuse. Unknown id → list valid ids. |
| `next` | If a milestone is `in progress (WP…)`, report it (and its first open WP) as active and stop. Report milestones `awaiting user check` as such and pass over them. Otherwise take the first milestone in plan order that isn't landed or awaiting a check and whose dependencies are landed or awaiting a check → write it (no doc) or refresh it. Also list other milestones eligible to run alongside. Nothing eligible: all landed → say so and suggest setting the plan `implemented`; else print the status table with blockers. |
| `mode <guided\|swarm> <target>` | Switch execution mode — see `mode` below. |
| `refresh <id>` | `proposed`/`approved` docs: follow `${CLAUDE_SKILL_DIR}/reference/refresh.md`. `in progress`: only on explicit user request — update sections per refresh.md steps 1–3, log it, leave Status alone, skip approval. Landed: refuse. `--autonomous` (only when invoked by `/implement` swarm): refresh.md's Autonomous approval instead of asking. |

## `all` — write the milestone docs

### A. Skeleton (main agent)

Build one table covering every milestone being written before any doc is written, plus fixed rows for milestones that already have a doc (copied from it: header, WP file ownership, contracts — not regenerated) and plan-graph rows for the ones left `not written` (their dependencies and the files they are expected to touch, so ownership conflicts still show).

- id + slug; split proposals (a/b, parallel or sequential) — **ask the user** before splitting, since it changes the gate structure;
- Depends on / Blocks / Can run alongside;
- `Execution`: the plan's default (existing docs keep theirs);
- work packages `WP<n>.0` … `WP<n>.N` (id form per doc-authoring): `.0` apply reviewer decisions, confirm entry criteria, and pre-edit the shared hotspots (package refs, project/solution files, registries); last = verification + doc-sync + ledger; each with **`After:`**, **files owned**, **`Model:`** and **`Review:`** (doc-model's rules) and gating notes — swarm-ready per doc-model's Execution modes, whatever the mode;
- contracts introduced and consumed;
- acceptance criteria expanded from the plan gate (build/test gates first; repeat grep-able conventions);
- which `[VERIFY]` tags / register questions each milestone owns (each becomes a `D<n>` design question);
- a disposition for every open ledger entry whose `files:` or `areas:` overlap;
- the **Section profile**: the index's existing one, or decide it now from the project's architecture (layer-named change sections, cross-cutting obligations such as tracing) — "Default sections only" if nothing warrants one.

Run the consistency checklist (below) against the skeleton and fix it before drafting.

### B. Draft

Template: the project's own if it has one; else `${CLAUDE_SKILL_DIR}/templates/folder/overview.md`, one `${CLAUDE_SKILL_DIR}/templates/folder/wp.md` per work package (`WP<id>.md`) and `${CLAUDE_SKILL_DIR}/templates/folder/as-built.md`. Status `proposed`; `Written against` = HEAD. A milestone whose dependencies haven't landed gets a *Projected* "What exists".

- **Fewer than 4 docs to write:** draft inline.
- **4 or more:** launch `general-purpose` subagents in parallel, ~5 docs each, with `${CLAUDE_SKILL_DIR}/templates/drafter-brief.md` filled in — the full skeleton table and Section profile go into every brief. Subagents can't ask the user; open points come back as Proposals or `[VERIFY]` tags. Resolve each skeleton objection: change the skeleton and patch the affected docs, or record why not under that doc's Risks.

### C. Consistency pass (main agent)

Re-read every doc's header, work packages, contracts, criteria and reconciliation table, and check:

1. *(`all` only)* Every plan gate maps to exactly one doc or a declared a/b pair; the index lists the same set.
2. Depends on ↔ Blocks are symmetric; Can run alongside is symmetric; no cycles; matches the plan's dependency graph.
3. No two work packages that `After:` leaves unordered share a file — within a doc, or across docs that can run alongside each other. An extension of an earlier milestone's file is marked `*(<owner>-owned — extended here)*` and the owner is an ancestor.
4. Every contract is introduced in exactly one doc; every consumer depends (transitively) on the introducer.
5. Every `§` reference exists in the plan.
6. Every plan acceptance bullet is covered by the doc's criteria (for a split, by the pair together).
7. Every open overlapping ledger entry has a disposition; ledger links use the relative path to the resolved ledger and its anchor style.
8. Every `[VERIFY]` / register question has exactly one owning milestone, where it appears as a `D<n>` design question.
9. WP ids are unique, sequential and in the doc-authoring form; `.0` and the last WP follow the convention; every template heading is present (placeholder exception aside); no guidance comments remain; no WP uses a package outside Stack.
10. Every WP has `After:`, `Model:` and `Review:`; each `Model: opus` names the unsettled design choice that earns it, and more than a third of a doc's WPs on `opus` is reported with the WPs to reconsider; the `After:` graph is acyclic; manifests, project/solution files and registries are owned by `.0` or explicitly sequenced; every header has `Execution`.
11. Size budgets hold (`wc -c`): overview ≤ 12 KB, each WP file ≤ 6 KB. Over → cut restated plan text and long rationale first, then split the WP.

Fix what's fixable; report anything that needs the user.

### D. Index

Write (or update) `<milestones dir>/README.md` from `${CLAUDE_SKILL_DIR}/templates/index.md`, listing only docs that exist: Documents table (no status column), split semantics, mermaid dependency graph, parallelism matrix, multi-agent protocol (always in full — docs are swarm-ready whatever the mode), execution modes, shared conventions, Section profile, as-built rules.

### E. Plan + report

- **Only for gates whose doc was written in this run:** fill the `_Execution doc:_` link (the overview, in the folder layout) and set the gate status to `proposed`. Touch nothing else in the plan.
- Report: docs written (path · overview KB · WP count · largest WP file KB), gates left `not written` (just in time), skeleton objections and how they were resolved, new `[VERIFY]` tags, consistency issues left for the user, suggested commit message `Add milestone docs <first>–<last>`.
- Close with: "Review the docs, then implement with `/implement next` — it refreshes and approves each doc written ahead of time before starting (or run `/milestone refresh <id>` to review one yourself first)."

## `mode` — switch guided ↔ swarm

Targets: `<id>` (one milestone; a split parent means both halves) · `from <id>` (every unlanded milestone from that id on, in plan order, **and** the plan's default) · `all` (every unlanded milestone and the plan's default).

1. Resolve the targets; list landed ones as skipped. With `from`/`all`, targets without a doc just inherit the new plan default. A single `<id>` without a doc → refuse and suggest `/milestone <id>` first, or `mode … from <id>`.
2. **Switching to `swarm`:** run the Swarm-readiness check from `${CLAUDE_SKILL_DIR}/reference/refresh.md` on each target — open `D<n>` questions are reported as a note here, not a failure (`/implement` asks them up front). A target that fails is **not** switched — report its failures with the fix (add an `After:` edge, move a file to `.0`, split a WP) and suggest `/milestone refresh <id>` to apply them. Switching to `guided` needs no check.
3. For each target that passes: set `**Execution:**` — the commit message records the switch. For an `in progress` doc say which WPs it applies to (`(WP3.4–3.6)`); landed WPs are unaffected.
4. `from` / `all`: set the plan header's `**Execution:**` too.
5. Never change Status or `Written against`; touch nothing else.
6. Report the switched / skipped / blocked targets and suggest the commit message `Switch <targets> to <mode> execution`.

## Single-doc path (`<id>`, `next`)

Same as `all` steps A–E for one milestone: the skeleton row is built fresh for the target; neighbours' rows come from their docs, or from the plan graph where they have none. Consistency checks 2–11 apply to the target and its direct neighbours. The index gains (or is created with) the new row only.

## After this skill

`/implement` implements the docs; who changes which status from then on is doc-model's "Who changes what". Before starting implementation of a milestone whose doc is `proposed`, or `approved` but stale (doc-model's staleness rule), run `refresh` first, unprompted. Never refresh the doc you're currently implementing just because new commits exist.
