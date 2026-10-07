# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Emilio's workbench for his user-level Claude Code config: improving existing agents and skills, drafting new ones, and keeping a history of every change and why it was made. It is the **source of truth**. `~/.claude/` holds deployed copies (not symlinks) and is changed only through `scripts/sync.sh`. Everything here is Markdown except the scripts in `scripts/`; there is no build. `scripts/lint.sh` checks the conventions and contracts below that can be checked mechanically; behavior is smoke-tested by hand with `tests.md`.

| Repo path | Deployed to | Role |
|---|---|---|
| `main-agent/CLAUDE.md` | `~/.claude/CLAUDE.md` | Global instructions loaded into every session |
| `agents/<name>.md` | `~/.claude/agents/` | Subagent definitions |
| `skills/<name>/` | `~/.claude/skills/<name>/` | Skills (`SKILL.md` + any supporting files) |

Don't confuse `main-agent/CLAUDE.md` (the global instructions being authored) with this file (guidance for working on the repo).

## Workflow

1. **Pull first.** Tools like `/agents`, `claude-md-improver`, and `revise-claude-md` edit `~/.claude` directly. Run `scripts/sync.sh` before starting; if it reports `live-newer` or `live-only` items, `scripts/sync.sh pull` (with `--global` if the global CLAUDE.md is among them) and log them in the changelog as outside edits.
2. **Edit here**, keeping the cross-file contracts below consistent. If a skill's expected behavior changes, update its checks in `tests.md` in the same commit. Run `scripts/lint.sh` before committing.
3. **Log it.** Add an entry to `CHANGELOG.md` under today's date (newest first): `- **<agent/skill/global>** — what changed and why`. The why is the point. Commit the changelog entry together with the change, one agent or skill per commit where practical.
4. **Deploy**: `scripts/sync.sh apply` — add `--global` when `main-agent/CLAUDE.md` changed. Changes load in **new** sessions only.
5. **Smoke-test** skill and agent changes with `tests.md` — its coverage table says which tests to rerun; each runs in a new session in a scratch project, started with `scripts/smoke.sh <n>`. Record the run in its log (`scripts/check-test.sh` prints the row); a failure means a fix commit and a rerun. Tests that run against private repos live in an untracked `tests.local.md`.

`scripts/sync.sh` (Git Bash) modes: `status` (default) · `diff` · `apply [--force] [--global]` · `pull [--force] [--global]`.

- `apply` and `pull` leave `main-agent/CLAUDE.md` alone unless `--global` is passed, so a clone on another machine can't swap global instructions in either direction. `status` marks that row `[--global]`.
- `apply` refuses to overwrite live files that are newer than the repo copy.
- `pull` skips repo files that are newer than live or that have uncommitted changes.
- `--force` overrides either check.
- Every file it overwrites is first backed up to `.sync-backup/<timestamp>/{live,repo}/` (gitignored), and it never deletes anything.

The newer/older check compares file timestamps, so it can't tell when *both* sides changed. If `apply` overwrites a live edit that way, recover it from `.sync-backup/`. The script ignores `~/.claude/skills/synced/` (managed by claude.ai) and `.trash/`. It targets `$CLAUDE_CONFIG_DIR` if that is set, so point that at a scratch copy to test it.

`scripts/lint.sh` enforces: skill and agent names match their paths, every agent has a `color`, the reviewer and writing-agent rules below, every `${CLAUDE_SKILL_DIR}/…` path exists, the reviewer roster, and a coverage row in `tests.md` per skill. It also fails on any tracked file matching a pattern in `.lint-deny` (gitignored, one regex per line) — that is what keeps private project names out; without the file that check is skipped.

`scripts/defender-dev-exclusions.ps1` is machine setup, not config: run it yourself in an elevated pwsh (`-WhatIf` first, `-Remove` undoes) to exclude dev folders from Defender's real-time scan. sync.sh never deploys it.

To trial a draft agent or skill without deploying it globally, copy it into a test project's `.claude/agents/` or `.claude/skills/`; project-local definitions shadow global ones.

`.gitattributes` pins LF line endings. System git has `autocrlf=true`, and CRLF conversion would make every file differ from the deployed copy.

## Cross-file contracts

Files reference each other by name. When you rename or change one, update the others:

- **Reviewer roster.** Three places name `csharp-reviewer` / `react-reviewer` / `vulkan-reviewer` / `python-reviewer`: the global CLAUDE.md "Agents" section, the `reviewer.md` description, and the React rule in the global "Project CLAUDE.md Authoring" section. `react-reviewer.md`'s description points back at the global CLAUDE.md. A new stack-specific reviewer means updating all of these. `skills/implement` deliberately names no stack reviewer — it defers to the global "Agents" section and falls back to the generic `reviewer` only when there is none, so it needs no update.
- **Follow-up ledger.** Shared by the global "Documentation Workflow" rule, `agents/doc-sync.md`, and `skills/followup/SKILL.md`:
  - one file per entry, `docs/fu/FU-NNN.md`, with flat front matter `id / title / status / kind / areas / files / revisit / origin` and a body of **What / Why accepted / Impacts** bullets plus dated **Update** bullets
  - sequential `FU-NNN` ids; Kind ∈ `deferred | decision | compromise | limitation`; **Why accepted** required for `compromise`/`limitation`, `revisit:` required for `deferred` (a bare milestone id there blocks that milestone from landing)
  - status `open` → `done (<sha> or PR #N, YYYY-MM-DD)` / `dropped (reason)`; entries never deleted or renamed
  - `docs/follow-ups.md` is a generated index for the user (`skills/followup/scripts/fu-index.ps1`), regenerated after every entry change and **never read by agents** — they grep `docs/fu/`
  - a ledger still kept as one file is not supported: `/followup` stops and points at `skills/followup/scripts/fu-migrate.ps1`, which converts it

  The entry format and the grep queries live only in `followup/SKILL.md`. `doc-sync` maintains the ledger but never creates it; `/impl-plan`, `/milestone`, `/implement` and `/walkthrough` write to it only by invoking `/followup` (in swarm runs only the coordinator does, one at a time — workers propose `FU-TBD-*` placeholders).
- **Plan/milestone docs.** Shared by `skills/impl-plan`, `skills/milestone`, `skills/implement`, `agents/doc-sync.md`, and the global Documentation Workflow rule; `skills/walkthrough` also reads it, records milestone decisions (the overview's `D<n>` bullets — same format as refresh, only for `proposed`/`approved` docs, never touching Status) and draft-plan §Decisions, and owns the walkthrough log dir (default `docs/reviews/`), which doc-sync never edits. The canonical copy is in `skills/impl-plan/reference/`, split by reader so `/implement` and doc-sync don't load authoring rules: `doc-model.md` (doc roles, layout, status words, who changes what, execution modes — read by everything), `doc-authoring.md` (convention detection, defaults, header fields incl. `Written against`, links, content rules — read only by `/impl-plan`, `/milestone` and their subagents) and `doc-sync-plan.md` (doc-sync's own transitions, read by the agent only in projects with a plan); `milestone`, `implement` and `walkthrough` read them via `${CLAUDE_SKILL_DIR}/../impl-plan/`, so the four skills must deploy — and be trialled — together. Key invariants: milestone docs are folders (`overview.md` ≤ 12 KB, one `WP<id>.md` ≤ 6 KB per work package, `as-built.md`) so each reader opens only its slice — landed single-file docs are frozen history and nothing writes that layout any more; docs are always swarm-ready (every WP has `After:`, `Model:`, `Review:`, exclusive file ownership, hotspots in `WP<n>.0`) and hold only what something reads — verification is not a WP, the as-built record lists deviations only, and a section marked Optional is left out when empty; and `Execution: guided | swarm` only changes how a milestone is implemented; the plan holds gates plus one status line per milestone; the milestone's as-built record is append-only and the doc is frozen once landed; doc-sync never creates or edits pre-written future milestone docs (it reports `needs /milestone refresh <id>`); `/implement` writes only the routine progress markers (`in progress`, WP `☑ landed` / `⛔ blocked`) and invokes refresh, `/followup` and doc-sync for everything else — doc-sync once per milestone in guided mode (at landing, from the WP commits' `Review:`/`Deviation:` lines) and once per merged wave in swarm.
- **doc-sync vs docs-writer.** `doc-sync` only updates existing docs and reports gaps. Writing new docs belongs to `docs-writer`, except plans and milestone docs, which come from `/impl-plan` and `/milestone`.

## Authoring conventions

- **`description` drives auto-delegation and skill triggering.** Say *when* to use the agent or skill, including trigger phrases. "Use proactively …" marks agents Claude should launch unprompted.
- **Reviewers** don't change anything: `tools: Read, Grep, Glob, Bash`, where Bash is only for reading git (`diff`/`show`/`log`/`status`) — their shared "Getting the change" section says so and sets the review depth (`full` / `light`). They omit `model`, so they inherit the main model. They share one shape: getting the change → categorized checks → rules → fixed output format → "What NOT to do".
- **Agents that write files** (`doc-sync`, `docs-writer`, `refactorer`, `test-writer`, `wp-worker`) get `model: sonnet` plus Write/Edit, and Bash where they need git or test runs. `/implement` overrides `wp-worker` to Opus per work package (`Model: opus` in the WP).
- **Every agent** has a `color`.
- **A skill's directory name** must match its frontmatter `name`, which is the `/command` users type.
- **Heavy user-triggered skills** that write many files use `disable-model-invocation: true` (e.g. `impl-plan`); leave it off when Claude should be able to chain into the skill (e.g. `milestone`, which `impl-plan` hands off to and Claude runs as `refresh` before implementing). `implement` is model-invocable too, behind a gate in its own hard rules: self-invoked, it runs guided on one milestone and asks before the first commit; swarm/ranges need the user's explicit `/implement`.
- **Skills keep hard rules at the top of `SKILL.md`** and push templates and long reference material into supporting files: after compaction only the start of a skill is re-attached.
