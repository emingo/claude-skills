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

To trial a draft agent or skill without deploying it globally, copy it into a test project's `.claude/agents/` or `.claude/skills/`; project-local definitions shadow global ones.

`.gitattributes` pins LF line endings. System git has `autocrlf=true`, and CRLF conversion would make every file differ from the deployed copy.

## Cross-file contracts

Files reference each other by name. When you rename or change one, update the others:

- **Reviewer roster.** Three places name `csharp-reviewer` / `react-reviewer` / `vulkan-reviewer` / `python-reviewer`: the global CLAUDE.md "Agents" section, the `reviewer.md` description, and the React rule in the global "Project CLAUDE.md Authoring" section. `react-reviewer.md`'s description points back at the global CLAUDE.md. A new stack-specific reviewer means updating all of these. `skills/implement` deliberately names no stack reviewer — it defers to the global "Agents" section and falls back to the generic `reviewer` only when there is none, so it needs no update.
- **Follow-up ledger.** Shared by the global "Documentation Workflow" rule, `agents/doc-sync.md`, and `skills/followup/SKILL.md`:
  - default path `docs/follow-ups.md`
  - sequential `FU-NNN` ids
  - entry fields **Status / Kind / Origin / Areas / Impacts / What**, plus **Why accepted** (required for `compromise`/`limitation`) and **Revisit when** (required for `deferred`; a bare milestone id there blocks that milestone from landing); Kind ∈ `deferred | decision | compromise | limitation`
  - headings `<a id="fu-nnn"></a>` + `### FU-NNN: <Title>` and an Index with a Kind column in new ledgers (existing ledgers keep their style and columns)
  - status `open` → `done (<sha> or PR #N, YYYY-MM-DD)` / `dropped (reason)`
  - an Index table kept in sync with the entries
  - entries never deleted

  The skeleton and entry format live only in `followup/SKILL.md`. `doc-sync` maintains the ledger but never creates it; `/impl-plan`, `/milestone`, `/implement` and `/walkthrough` write to it only by invoking `/followup` (in swarm runs only the coordinator does, one at a time — workers propose `FU-TBD-*` placeholders).
- **Plan/milestone docs.** Shared by `skills/impl-plan`, `skills/milestone`, `skills/implement`, `agents/doc-sync.md`, and the global Documentation Workflow rule; `skills/walkthrough` also reads it, writes milestone `Reviewer decisions` (same format as refresh, only for `proposed`/`approved` docs, never touching Status) and draft-plan §Decisions, and owns the walkthrough log dir (default `docs/reviews/`), which doc-sync never edits. The canonical copy is `skills/impl-plan/reference/doc-model.md` (doc roles, convention detection, defaults, status words, header fields incl. `Written against`, link rules); `milestone`, `implement` and `walkthrough` read it via `${CLAUDE_SKILL_DIR}/../impl-plan/`, so the four skills must deploy — and be trialled — together. Key invariants: docs are always swarm-ready (every WP has `After:`, exclusive file ownership, hotspots in `WP<n>.0`) and `Execution: guided | swarm` only changes how a milestone is implemented; the plan holds gates plus one status line per milestone; the milestone doc holds the checklist and append-only As-built record and is frozen once landed; doc-sync never creates or edits pre-written future milestone docs (it reports `needs /milestone refresh <id>`); `/implement` owns no status transition — it invokes refresh, `/followup` and doc-sync.
- **doc-sync vs docs-writer.** `doc-sync` only updates existing docs and reports gaps. Writing new docs belongs to `docs-writer`, except plans and milestone docs, which come from `/impl-plan` and `/milestone`.

## Authoring conventions

- **`description` drives auto-delegation and skill triggering.** Say *when* to use the agent or skill, including trigger phrases. "Use proactively …" marks agents Claude should launch unprompted.
- **Reviewers** are read-only (`tools: Read, Grep, Glob`) and omit `model`, so they inherit the main model. They share one shape: categorized checks → rules → fixed output format → "What NOT to do".
- **Agents that write files** (`doc-sync`, `docs-writer`, `refactorer`, `test-writer`) get `model: sonnet` plus Write/Edit, and Bash where they need git or test runs.
- **Every agent** has a `color`.
- **A skill's directory name** must match its frontmatter `name`, which is the `/command` users type.
- **Heavy user-triggered skills** that write many files use `disable-model-invocation: true` (e.g. `impl-plan`); leave it off when Claude should be able to chain into the skill (e.g. `milestone`, which `impl-plan` hands off to and Claude runs as `refresh` before implementing). `implement` is model-invocable too, behind a gate in its own hard rules: self-invoked, it runs guided on one milestone and asks before the first commit; swarm/ranges need the user's explicit `/implement`.
- **Skills keep hard rules at the top of `SKILL.md`** and push templates and long reference material into supporting files: after compaction only the start of a skill is re-attached.
