---
name: impl-plan
description: Write a gated implementation plan (master plan doc) for a new project or a large feature — goal/non-goals, decisions with rejected alternatives, pinned stack, annotated repo layout, spec sections, milestone gates, assumption register, conventions — then hand off to /milestone to split it into milestone docs. Use when the user runs /impl-plan <what to build> or asks to "write an implementation plan", "plan the build of X", or "create a roadmap".
argument-hint: "<what to build>"
disable-model-invocation: true
allowed-tools: Bash(git log *) Bash(git show *) Bash(git diff *) Bash(git rev-parse *) Bash(git status *)
---

# /impl-plan — write the master implementation plan

Request: $ARGUMENTS

## Hard rules

- **Read `${CLAUDE_SKILL_DIR}/reference/doc-model.md` first** — it defines doc roles, convention detection, defaults, status words, header fields, links, content rules and style. Everything below assumes it.
- **Follow the project's detected conventions**; defaults apply only where the project has none.
- **Never commit.** Suggest the commit message at the end.
- **The ledger is written only through `/followup`** (Skill tool), which also creates it on first use. Never hand-write ledger entries or its skeleton.
- **No new dependency enters the Stack section unapproved** — ask with what it does and what the alternative without it looks like.
- **Never silently rewrite** an existing plan's §Decisions or the gate of a landed milestone; changes are dated, reviewed edits.
- **At most two question rounds.** Anything still open after that becomes a `[VERIFY]` tag plus an assumption-register row with an owning milestone.

## 1. Discovery (≈15 reads max)

- Project `CLAUDE.md` (especially Documentation Workflow), `README.md`, the `docs/` listing.
- Any existing plan (`docs/*plan*.md`, `docs/*IMPLEMENTATION*.md`, `docs/*roadmap*.md`), milestone dir + index + `_template.md`, one sample milestone doc's headings.
- Ledger index — open entries only.
- Manifests for the real stack and versions (`*.csproj`, `*.sln`, `package.json`, `pyproject.toml`, `Cargo.toml`, …) and the top-level source layout.
- `git log --oneline -20`, `git rev-parse --short HEAD`. Not a git repo → recommend `git init` before planning (`Written against` and `/milestone refresh` depend on history); if the user declines, write `Written against: n/a` and refresh falls back to file dates.

If the request above is empty, ask what to build before anything else. If a plan already exists, ask one question: **new companion plan** / **extend** (append milestones and spec sections) / **revise in place** (dated edits; landed gates and §Decisions untouched unless the user names them).

## 2. Conventions profile

Resolve conventions per doc-model.md and print the five-line profile before writing anything. On greenfield say "defaults" per line so the user can object early.

## 3. Questions

Use AskUserQuestion with options you inferred from discovery; skip anything the request or existing docs already answer.

**Round 1** (up to 4):
1. **Non-goals** — multiSelect of plausible scope items to exclude.
2. **Open stack decisions** — one per unresolved choice; for any new dependency state what it does and the no-dependency alternative.
3. **Testing approach** — basic smoke tests (user's default) / detailed unit tests / TDD. Mark TDD "(Recommended)" for greenfield or multi-milestone plans.
4. **Default execution mode** — *guided*: pause after each work package for review (Recommended) / *swarm*: parallel worktree agents wherever the parallelism allows. Milestone docs are swarm-ready either way; the mode can be switched per milestone later with `/milestone mode`.

**Round 2** only for decisions that surfaced while drafting (and the plan filename on greenfield if the default doesn't fit).

## 4. Draft

Write the plan from `${CLAUDE_SKILL_DIR}/templates/plan.md` (or the project's existing plan structure when extending). Strip every `<!-- guidance -->` comment; never delete a heading (`None — <reason>`). Split the spec into as many numbered sections as the subsystems need and fix every `§` reference after renumbering.

Gate rules for the Milestones section:
- `M0` is a runnable, testable skeleton plus the first frozen contracts.
- Each milestone is independently demonstrable; its acceptance bullets are observable by a test or command.
- The dependency graph has no cycles and matches each gate's scope; say which milestones can run in parallel and why.
- A milestone likely to need more than ~7 work packages is flagged in the plan as a split candidate (`a`/`b`), with whether the halves would be parallel or sequential.
- Every path in the layout tree names the milestone that introduces it.
- Every `[VERIFY]` has a register row with an owner.

Header: `Status: draft`, `Execution:` = the round-1 answer, `Written against` = HEAD, one-line `Last updated`.

## 5. Critique

Launch one `general-purpose` subagent (fresh context, so it doesn't share your blind spots) with `${CLAUDE_SKILL_DIR}/templates/critique-brief.md`, filling in the placeholders. Apply its findings:
- `fix-in-place` → edit the plan.
- `[VERIFY]+register` → tag inline, add the register row with an owner.
- `follow-up` → candidates for step 6.
- `ask-user` → batch into Round 2 if unused; otherwise tag each `[VERIFY]` with a register row and an owner, **and** list it in the step 8 report as an open decision.

## 6. Seed the ledger

If there are follow-up candidates, ask one multiSelect "Record these as follow-ups?" (entries can never be deleted, so confirm first). Invoke `/followup` once per confirmed item, with Origin naming the plan section (`— plan review §N`).

## 7. Wire the project CLAUDE.md

Ask before editing. Add or update its **Documentation Workflow** section (≈2 paragraphs, per the global CLAUDE.md rule), naming:
- the plan path — doc-sync updates only the header status, gate status lines, resolved `[VERIFY]` tags/register rows, and the one-line Last updated;
- the milestone dir and id pattern — the active milestone doc carries the checklist and append-only As-built record; landed docs are frozen; implement with `/implement <id>` (guided or swarm per the doc's `Execution`; switch with `/milestone mode`), which refreshes docs written ahead of time first;
- the ledger path and the `/followup` rule;
- anything doc-sync must not touch (spec docs, templates).

This section doubles as the declared conventions for future runs.

## 8. Hand-off

Report, briefly: plan path and line count; open `[VERIFY]` count; unresolved `ask-user` decisions; follow-ups recorded; suggested commit message `Add implementation plan for <X>`. If `ask-user` decisions remain, offer to settle them with `/walkthrough` before the question below.

Then ask: **"Plan approved — generate all milestone docs now?"** with options *Yes, all milestone docs* (Recommended) / *Not yet — I'll review first* / *Only M0 for now*. On a yes, set the plan `Status: approved (<date>)` and invoke the `milestone` skill with `all` (or `M0`). Its report ends by pointing at `/implement next`.
