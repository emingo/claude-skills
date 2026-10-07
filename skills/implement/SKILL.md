---
name: implement
description: Implement the plan's milestones from their milestone docs. Guided mode works one work package at a time in this session — implement, stack review, commit, pause — and syncs docs when the milestone lands. Swarm mode runs parallel worktree agents, unattended by default, and resumes cleanly after interruptions. Use when the user says "let's start implementing M3", "implement the next milestone", "continue implementing", or asks to resume an interrupted implementation run.
argument-hint: "[next | <id> | <id>..<id> | all | status] [--agents N] [--step] [--model <m>]"
allowed-tools: Bash(git status *) Bash(git log *) Bash(git diff *) Bash(git show *) Bash(git rev-parse *) Bash(git merge-base *) Bash(git merge *) Bash(git add *) Bash(git rm *) Bash(git commit *) Bash(git revert *) Bash(git grep *) Bash(git submodule status *) Bash(git worktree list *) Bash(git worktree unlock *) Bash(git worktree remove *) Bash(git branch -d *) Bash(git branch --list *) Bash(git -C * status *) Bash(git -C * log *) Bash(git -C * add *) Bash(git -C * commit *) Bash(pwsh -NoProfile -File *)
---

# /implement — implement milestones from their docs

Arguments: $ARGUMENTS

## Hard rules

1. **Read `${CLAUDE_SKILL_DIR}/../impl-plan/reference/doc-model.md` first** — doc roles, layout, status words and "Who changes what", WP markers, staleness, ledger kinds, execution modes. Not `doc-authoring.md`: that is for the skills that write docs.
2. **Write only the progress markers** doc-model's "Who changes what" gives this skill, plus the plan's `draft` → `approved` when the user confirms it in preflight. They are 1–3 line edits of values you already know; never re-read a doc to make them. Approval is `/milestone refresh`'s, ledger entries are `/followup`'s, everything evidence-backed is doc-sync's.
3. **Self-invocation gate.** If Claude loaded this skill without the user typing `/implement` (e.g. "let's start implementing M7"), ask **before anything else**: "Implement <M> guided — one commit per work package, pausing after each, docs synced when it lands?" — and then run **guided mode on that one milestone only**. If resume finds swarm state (agent worktrees, unmerged agent branches), print the resume table and ask the user to type `/implement` instead. Swarm mode, `all`, ranges and `--agents` require the user's own `/implement` or an explicit request for the agent swarm.
4. **Committing is the job; nothing beyond it.** Typing `/implement` (or a yes to rule 3) is consent to commit on the **current branch**: WP commits (which in guided mode carry their ledger entries and progress marker), `--no-ff` merges, integration fixes, reverts, doc-sync commits. **Never push.** Never amend, rebase, `reset --hard`, `clean`, `checkout --`/`restore` over uncommitted work, `branch -D`, `worktree remove --force`, or force anything else. Never edit or commit inside a submodule or any path outside the repo; a submodule pointer bump happens only when the user asks.
5. **Main stays green.** Build and test after every commit or merge. If the branch can't be made green, halt the whole run and report.
6. **Stack reviewer before every code commit** — WP commits, and the coordinator's own integration-fix and stub commits — using the agent the global CLAUDE.md "Agents" section prescribes for the stack (never hardcode the roster here). Brief it with the change, not the code: the repo or worktree path, the diff to review (`git diff <base>...HEAD -- <paths>`, or the uncommitted diff), the WP file, and the WP's `Review:` depth (`full` / `light`); it runs git itself. Launch it with an explicit `model`: `opus` for `Review: full`, `sonnet` for `light` — reviewers never inherit this session's model. No "Agents" section in the global or project CLAUDE.md → resolve it in preflight: use the generic `reviewer` agent and say so in the run plan; if it isn't installed either, stop and ask which agent to use.
7. **No package outside the plan's Stack.** Guided: ask the user (what it does / the no-dependency alternative). Swarm: the WP is blocked until the user decides.
8. **Ledger ids are assigned only by the main session**, through `/followup`, one at a time. Workers never touch docs or the ledger; doc-sync only appends Updates and flips statuses.
9. **Nothing survives a merge cycle** among: notes to the coordinator in code, `FU-TBD-*` placeholders, `TODO`/`FIXME`/`HACK` without an FU id.
10. **Deferred criteria become ledger entries:** a criterion moved to a later milestone → `/followup` with `Kind: deferred`, `Revisit when: <that later milestone>`.
11. **Branch hygiene without losing work:** remove the worktree and delete the branch (`git branch -d`) of every WP that merged or never produced anything (`git worktree unlock` first if a dead process left it locked). A blocked or abandoned WP's branch holds unmerged work — **keep it** and list it in the run report.
12. **State lives in docs, git and worktrees — never only in context.** Re-running `/implement` resumes (`${CLAUDE_SKILL_DIR}/reference/resume.md`).
13. **Keep this session's context small.** Workers implement every swarm WP, `.0` included. Builds, tests and scripts write to a log file and you print only the summary lines; never dump process listings, whole logs or whole docs. Read docs by section (Grep the headings, Read with offset/limit). Hand doc-sync and workers paths, shas and ids — not pasted content.
14. **Slow commands run guarded.** No baseline run of slow end-to-end checks (packaging/consumer smoke, full screenshot runs) — the preflight baseline is the build and unit tests; slow checks run in the milestone's verification. Run a script as `pwsh -NoProfile -File <script> *> <log>` (or the shell's equivalent) in the background with a timeout of about 3× its usual duration and watch it with Monitor; on a timeout, stop its process tree, retry once, then report.
15. **Design and implementation never share a session.** After the `Approve …` commit, swarm milestones run through the unattended loop (below); `--step` runs and guided milestones end the turn with "approved — `/clear`, then `/implement` to start" — resume picks it up. Every milestone gets a fresh coordinator session; a milestone written and approved mid-run (just in time) starts in the next one.

## Modes

| Arguments | Behavior |
|---|---|
| *(none)* | A milestone `in progress (WP…)` or `in progress (verification)` → resume it. Else a milestone `in progress (awaiting user check)` → handle it (below) first. Else → `next`. |
| `status` | Read-only: the run report (`${CLAUDE_SKILL_DIR}/templates/run-report.md`) regenerated from docs + git, plus stale/locked agent worktrees, kept blocked branches, and doc drift. Offers cleanup of merged/empty leftovers; does nothing without a yes. |
| `next` | First milestone in plan order that isn't landed, isn't awaiting a user check, and whose dependencies are landed or awaiting a user check. |
| `<id>` | That milestone (normalized as in `/milestone`; a split parent means both halves). Landed → refuse. Awaiting a user check → handle it (below). A dependency not yet landed or awaiting a user check → list the blockers and stop (suggest `next`, or a range that includes them). |
| `<id>..<id>` | Inclusive range in plan order. Every dependency outside the range must be landed or awaiting a user check — else list them and stop. |
| `all` | Every milestone not landed. |
| `--agents N` | Swarm concurrency cap (default **4**). |
| `--model <m>` | The unattended coordinator's model (default **sonnet**) — passed to the loop as `-Model`. Workers and reviewers get theirs per WP. |
| `--step` | Swarm without the loop: run one milestone in this session, then stop with "<M> done — `/clear`, then `/implement` to continue". |
| `--unattended` | Passed only by the loop script — see Unattended. |

**Awaiting user check** — print that milestone's interactive checks (exact command + what to look for) and ask whether the user has done them. Confirmed → pass the user's words to doc-sync as evidence, which ticks them and lands the milestone; commit `Sync docs for <M>: user checks confirmed`. Not yet → skip it; its dependents may still proceed.

## Preflight (every run)

1. **Resume check first:** derive state per `reference/resume.md`. If anything is in flight, print the resume table and ask "Resume?" before anything else.
2. **Clean tree** (`git status --porcelain` empty, `.claude/worktrees/` aside — and except an interrupted guided WP the user chose to continue). State the branch the run will commit to.
3. **Green baseline.** Build and test commands from the project CLAUDE.md → the plan's Testing section → the active doc's first two acceptance criteria — never the slow end-to-end checks (rule 14). Run them now, quietly (rule 13): red → stop. Running them here also surfaces permission prompts while the user is present — if they aren't allow-listed, warn that background workers will stall on prompts and suggest `/fewer-permission-prompts`.
4. **Plan** exists (else suggest `/impl-plan`); `draft` → ask "Treat as approved?" — yes sets `approved (<date>)` (the one transition this skill owns).
5. **Docs** exist for every milestone in scope that can start now — milestones are written just in time, so a later one may legitimately have none yet. A startable milestone without a doc: invoke the `milestone` skill for it (`/milestone <id>`) — the only way this skill gets docs written — then treat the new doc like any `proposed` one in step 7. Never write milestone docs by hand.
6. **Mode per milestone:** the doc's `Execution` → the plan's default → `guided`. In a mixed range, a guided milestone runs on its own; the swarm resumes once it is landed or awaiting a user check.
7. **Refresh and approve** every doc that is `proposed`, or `approved` but **stale** (doc-model's Staleness rule):
   - *Guided:* interactive `/milestone refresh <id>`; commit `Approve the <M> milestone doc` (including any walkthrough log and ledger entries it produced, so the tree stays clean).
   - *Swarm — one up-front design round:* (a) run refresh steps 1–3 for every in-scope doc; (b) collect every undecided `D<n>` across them; (c) ask in AskUserQuestion batches of four — Proposal marked Recommended, plus "Decide autonomously"; (d) approve each doc, recording the user's answers as refresh.md §4 step 2 does (the overview's `D<n>` bullets) and "Decide autonomously" answers exactly as refresh.md's Autonomous approval does; commit `Approve <first>–<last> milestone docs`. Mid-run, when a later milestone becomes eligible and its doc is stale, run `/milestone refresh <id> --autonomous`, then re-run the swarm-readiness check on it.
   - Refresh recommends a rewrite → halt that milestone and its dependents; continue the rest of the graph.
8. **Swarm readiness** for swarm milestones: the Swarm-readiness check in the `milestone` skill's `reference/refresh.md`, with undecided `D<n>` counted as failures here. Failure → offer guided mode for that milestone, or stop.
9. **Forbidden paths:** `git submodule status` + `.gitmodules` paths, plus anything the project CLAUDE.md marks hands-off. They go into every brief.
10. **Run plan:** milestones · mode each · how it runs (swarm: the unattended loop by default, or `--step`; guided: in a fresh session after this one) · the stack reviewer (rule 6 — say so when it is the fallback) · models: the coordinator's (swarm loop: Sonnet unless `--model`), each WP's worker (Sonnet unless the WP says `opus`) and reviewer (`full` → Opus, `light` → Sonnet) · first wave (swarm) or first WP (guided) · cap N · expected agent count (nested reviewer agents roughly double concurrent load). Ask "Start?" once (self-invoked runs already asked in rule 3).

## Unattended (the default for swarm)

**From the interactive session**, after preflight and the design round's `Approve …` commit:

1. Start the loop **detached**, so it outlives this session and no background-task time cap kills it mid-milestone: on Windows `Start-Process pwsh -WindowStyle Minimized -ArgumentList '-NoProfile','-File','${CLAUDE_SKILL_DIR}/scripts/implement-loop.ps1','-Scope','<the scope typed>'` (plus `'-Model','<m>'` when `--model` was given; the script defaults to Sonnet); elsewhere `nohup pwsh -NoProfile -File … >/dev/null 2>&1 &`. Tell the user how to stop it (`… implement-loop.ps1 -Stop` ends it after the current milestone) and that closing this session doesn't.
2. Watch `.implement/loop/loop.log` with Monitor (re-arm it when it expires) and relay each `RUN` / `DONE` / `FAIL` / `LIMIT` / `NEEDS YOU` / `ALL DONE` / `STOP` / `END` line as one line. Never read the `run-<n>.jsonl` transcripts unless a run failed and the user asks.
3. When it ends, print the run report (as `status` does), leading with what needs the user.

**A session started with `--unattended`** (only the loop does that):

- **Never asks.** Resume without asking (skip resume step 0 — the loop's own lock names your parent). A startable milestone without a doc → `/milestone <id>` then `/milestone refresh <id> --autonomous`; docs to refresh or approve → `/milestone refresh <id> --autonomous`. Anything "never autonomous" (swarm.md §4) → blocked with a "needs user" follow-up. A guided milestone, a dirty tree outside `.claude/worktrees/` and `.implement/`, or swarm state it can't classify → stop with `needs-user`.
- **Exactly one milestone:** the first in scope that is `in progress`, else the next eligible one. Run it to landed or `awaiting user check` (never wait for interactive checks), or to a stop condition.
- **Before ending, write `.implement/loop/state.json`:** `{"milestone": "<M>", "result": "landed|awaiting-check|needs-user|blocked|red|limit|all-done", "sha": "<HEAD>", "summary": "<one line>", "needsUser": ["FU-NNN — <question>"], "resetAt": "<ISO time or null>"}`. Nothing eligible → `all-done`. A usage limit → swarm.md §5's salvage, then `limit` with the reset time if known. Then end — never start the next milestone.

## Run

- **Guided milestones:** `${CLAUDE_SKILL_DIR}/reference/guided.md`.
- **Swarm milestones:** `${CLAUDE_SKILL_DIR}/reference/swarm.md` (worker brief `templates/agent-brief.md`, worker report `templates/wp-report.md`).

## End of run

1. **Each milestone's verification** (run by this session in both modes, once every WP is landed): run every acceptance criterion; anything unmet that belongs to a later milestone → rule 10; interactive-only criteria → offer the checks now, otherwise doc-sync sets `awaiting user check`; doc-sync lands what qualifies. This is a guided milestone's only doc-sync and a swarm milestone's last one.
2. **No separate final doc-sync.** Each landing doc-sync also updates the project CLAUDE.md status lines and README; the one that lands the plan's last gate sets the plan header `implemented` (only with Definition-of-done evidence and no open `deferred` entry naming a landed milestone).
3. **Whole-tree gates:** `git grep -nE 'NOTE FOR|FU-TBD' -- . ':!.claude' ':!docs'` → nothing; no worktree or `worktree-agent-*` branch remains for a merged or empty WP (kept blocked branches are listed instead).
4. **Run report** from `${CLAUDE_SKILL_DIR}/templates/run-report.md`, in chat. Lead with what needs the user: interactive checks with exact commands, decisions marked "needs user", blocked work, decisions to review grouped by Kind.
