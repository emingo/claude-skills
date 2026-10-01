---
name: implement
description: Implement the plan's milestones from their milestone docs. Guided mode works one work package at a time in this session — implement, stack review, commit, doc-sync, then pause for the user's go-ahead. Swarm mode runs parallel worktree agents per the work packages' After/ownership rules, merging and doc-syncing each one, recording autonomous decisions and compromises as follow-ups, and resuming cleanly after interruptions. /implement [next | <id> | <id>..<id> | all] [--agents N]; /implement status prints progress read-only. Use when the user says "let's start implementing M3", "implement the next milestone", "continue implementing", or asks to resume an interrupted implementation run.
argument-hint: "[next | <id> | <id>..<id> | all | status] [--agents N]"
allowed-tools: Bash(git status *) Bash(git log *) Bash(git diff *) Bash(git show *) Bash(git rev-parse *) Bash(git merge-base *) Bash(git merge *) Bash(git add *) Bash(git rm *) Bash(git commit *) Bash(git revert *) Bash(git grep *) Bash(git submodule status *) Bash(git worktree list *) Bash(git worktree unlock *) Bash(git worktree remove *) Bash(git branch -d *) Bash(git branch --list *) Bash(git -C * status *) Bash(git -C * log *) Bash(git -C * add *) Bash(git -C * commit *)
---

# /implement — implement milestones from their docs

Arguments: $ARGUMENTS

## Hard rules

1. **Read `${CLAUDE_SKILL_DIR}/../impl-plan/reference/doc-model.md` first** — doc roles, status words and "Who changes what", Execution modes, WP markers, staleness, ledger kinds. The `impl-plan`, `milestone` and `implement` skills deploy and are trialled together.
2. **Own no status transition** except the plan's `draft` → `approved` when the user confirms it in preflight. Approval comes from `/milestone refresh`, ledger entries from `/followup`, WP markers and in-progress / landed / implemented from `doc-sync`. This skill invokes them; it never edits those Status lines itself.
3. **Self-invocation gate.** If Claude loaded this skill without the user typing `/implement` (e.g. "let's start implementing M7"), ask **before anything else**: "Implement <M> guided — a WP commit plus a doc-sync commit per work package, pausing after each?" — and then run **guided mode on that one milestone only**. If resume finds swarm state (agent worktrees, unmerged agent branches), print the resume table and ask the user to type `/implement` instead. Swarm mode, `all`, ranges and `--agents` require the user's own `/implement` or an explicit request for the agent swarm.
4. **Committing is the job; nothing beyond it.** Typing `/implement` (or a yes to rule 3) is consent to commit on the **current branch**: WP commits, `--no-ff` merges, integration fixes, reverts, doc-sync commits. **Never push.** Never amend, rebase, `reset --hard`, `clean`, `checkout --`/`restore` over uncommitted work, `branch -D`, `worktree remove --force`, or force anything else. Never edit or commit inside a submodule or any path outside the repo; a submodule pointer bump happens only when the user asks.
5. **Main stays green.** Build and test after every commit or merge. If the branch can't be made green, halt the whole run and report.
6. **Stack reviewer before every code commit** — WP commits, and the coordinator's own `.0`, integration-fix and stub commits — using the agent the global CLAUDE.md "Agents" section prescribes for the stack (never hardcode the roster here). No "Agents" section in the global or project CLAUDE.md → resolve it in preflight: use the generic `reviewer` agent and say so in the run plan; if it isn't installed either, stop and ask which agent to use.
7. **No package outside the plan's Stack.** Guided: ask the user (what it does / the no-dependency alternative). Swarm: the WP is blocked until the user decides.
8. **Ledger ids are assigned only by the main session**, through `/followup`, one at a time. Workers never touch the plan, milestone docs, index, ledger, README or CLAUDE.md. doc-sync, when invoked from here, only appends Updates and flips statuses — it never creates entries.
9. **Nothing survives a merge cycle** among: notes to the coordinator in code, `FU-TBD-*` placeholders, `TODO`/`FIXME`/`HACK` without an FU id.
10. **Deferred criteria become ledger entries:** a criterion moved to a later milestone → `/followup` with `Kind: deferred`, `Revisit when: <that later milestone>`.
11. **Branch hygiene without losing work:** remove the worktree and delete the branch (`git branch -d`) of every WP that merged or never produced anything (`git worktree unlock` first if a dead process left it locked). A blocked or abandoned WP's branch holds unmerged work — **keep it** and list it in the run report.
12. **State lives in docs, git and worktrees — never only in context.** Re-running `/implement` resumes (`${CLAUDE_SKILL_DIR}/reference/resume.md`).

## Modes

| Arguments | Behavior |
|---|---|
| *(none)* | A milestone `in progress (WP…)` → resume it. Else a milestone `in progress (awaiting user check)` → handle it (below) first. Else → `next`. |
| `status` | Read-only: the run report (`${CLAUDE_SKILL_DIR}/templates/run-report.md`) regenerated from docs + git, plus stale/locked agent worktrees, kept blocked branches, and doc drift. Offers cleanup of merged/empty leftovers; does nothing without a yes. |
| `next` | First milestone in plan order that isn't landed, isn't awaiting a user check, and whose dependencies are landed or awaiting a user check. |
| `<id>` | That milestone (normalized as in `/milestone`; a split parent means both halves). Landed → refuse. Awaiting a user check → handle it (below). A dependency not yet landed or awaiting a user check → list the blockers and stop (suggest `next`, or a range that includes them). |
| `<id>..<id>` | Inclusive range in plan order. Every dependency outside the range must be landed or awaiting a user check — else list them and stop. |
| `all` | Every milestone not landed. |
| `--agents N` | Swarm concurrency cap (default **4**). |

**Awaiting user check** — print that milestone's interactive checks (exact command + what to look for) and ask whether the user has done them. Confirmed → pass the user's words to doc-sync as evidence, which ticks them and lands the milestone; commit `Sync docs for <M>: user checks confirmed`. Not yet → skip it; its dependents may still proceed.

## Preflight (every run)

1. **Resume check first:** derive state per `reference/resume.md`. If anything is in flight, print the resume table and ask "Resume?" before anything else.
2. **Clean tree** (`git status --porcelain` empty, `.claude/worktrees/` aside — and except an interrupted guided WP the user chose to continue). State the branch the run will commit to.
3. **Green baseline.** Build and test commands from the project CLAUDE.md → the plan's Testing section → the active doc's first two acceptance criteria. Run them now: red → stop. Running them here also surfaces permission prompts while the user is present — if they aren't allow-listed, warn that background workers will stall on prompts and suggest `/fewer-permission-prompts`.
4. **Plan** exists (else suggest `/impl-plan`); `draft` → ask "Treat as approved?" — yes sets `approved (<date>)` (the one transition this skill owns).
5. **Docs** exist for every milestone in scope — else offer `/milestone all` (or the missing ids). Never write milestone docs here.
6. **Mode per milestone:** the doc's `Execution` → the plan's default → `guided`. In a mixed range, a guided milestone runs on its own; the swarm resumes once it is landed or awaiting a user check.
7. **Refresh and approve** every doc that is `proposed`, or `approved` but **stale** (doc-model: commits since `Written against` touch code, the plan or the ledger — the doc's own approval and mode commits don't count):
   - *Guided:* interactive `/milestone refresh <id>`; commit `Approve the <M> milestone doc` (including any walkthrough log and ledger entries it produced, so the tree stays clean).
   - *Swarm — one up-front design round:* (a) run refresh steps 1–3 for every in-scope doc; (b) collect every undecided `D<n>` across them; (c) ask in AskUserQuestion batches of four — Proposal marked Recommended, plus "Decide autonomously"; (d) approve each doc, recording the user's answers as normal Reviewer decisions and "Decide autonomously" answers exactly as refresh.md's Autonomous approval does; commit `Approve <first>–<last> milestone docs`. Mid-run, when a later milestone becomes eligible and its doc is stale, run `/milestone refresh <id> --autonomous`, then re-run the swarm-readiness check on it.
   - Refresh recommends a rewrite → halt that milestone and its dependents; continue the rest of the graph.
8. **Swarm readiness** for swarm milestones: the Swarm-readiness check in the `milestone` skill's `reference/refresh.md`, with undecided `D<n>` counted as failures here. Failure → offer guided mode for that milestone, or stop.
9. **Forbidden paths:** `git submodule status` + `.gitmodules` paths, plus anything the project CLAUDE.md marks hands-off. They go into every brief.
10. **Run plan:** milestones · mode each · the stack reviewer (rule 6 — say so when it is the fallback) · first wave (swarm) or first WP (guided) · cap N · expected agent count (nested reviewer agents roughly double concurrent load). Ask "Start?" once (self-invoked runs already asked in rule 3).

## Run

- **Guided milestones:** `${CLAUDE_SKILL_DIR}/reference/guided.md`.
- **Swarm milestones:** `${CLAUDE_SKILL_DIR}/reference/swarm.md` (worker brief `templates/agent-brief.md`, worker report `templates/wp-report.md`).

## End of run

1. **Each milestone's last WP** (run by this session in both modes): run every acceptance criterion; anything unmet that belongs to a later milestone → rule 10; interactive-only criteria → offer the checks now, otherwise doc-sync sets `awaiting user check`; doc-sync lands what qualifies.
2. **Final doc-sync pass** over the whole run: project CLAUDE.md status lines, README, plan header (`implemented` only with Definition-of-done evidence and no open `deferred` entry naming a landed milestone).
3. **Whole-tree gates:** `git grep -nE 'NOTE FOR|FU-TBD' -- . ':!.claude' ':!docs'` → nothing; no worktree or `worktree-agent-*` branch remains for a merged or empty WP (kept blocked branches are listed instead).
4. **Run report** from `${CLAUDE_SKILL_DIR}/templates/run-report.md`, in chat. Lead with what needs the user: interactive checks with exact commands, decisions marked "needs user", blocked work, decisions to review grouped by Kind.
