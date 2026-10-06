# Resume — derive run state

There is no run-state file. Everything is recoverable from the docs, git and the worktrees, so a run cut off by a session limit, a crash, compaction or `/clear` resumes from a fresh session by re-running `/implement`.

Check in this order:

0. **A running loop** (interactive sessions only — a session started with `--unattended` was launched by that loop and skips this step). `.implement/loop/loop.lock` naming a live process → an unattended loop is coordinating: report it (and the last lines of `.implement/loop/loop.log`) and stop — never start a second coordinator.
1. **Docs.** Each milestone's Status; each WP's marker — the Status cell of the overview's WP table (single-file docs: `**Status: ☑ landed** (<sha>)` under the WP heading) — `☑ landed` or `⛔ blocked`. Blocked WPs stay blocked until the user resolves the cause.
2. **The current branch**, in this order:
   1. **A merge in progress** (`git rev-parse -q --verify MERGE_HEAD` succeeds) → `git merge --abort`; treat that WP as a task failure (swarm.md §5).
   2. **A `.implement/reports/<WP>.md` file on the branch** → the merge happened but its processing didn't finish: run merge protocol steps 3–7 for it (build + test first). Before step 5, grep the ledger for entries whose `origin:` already names this WP — those follow-ups were recorded; don't create them twice.
   3. **Merged but unsynced:** a `Merge <M> WPx.y …` or `… (<M> WPx.y)` commit whose WP isn't marked in its doc, and which has **no** later `Revert "…"` commit for it → run doc-sync for it (merge protocol step 6) before anything new starts. A reverted merge is not landed; a `Stub <M> WPx.y` commit is not landed either.
3. **Agent worktrees.** `git worktree list --porcelain`, keep entries under `.claude/worktrees/agent-*`. **Skip any whose agent is still running in this session**; if you can't tell whether an agent is still alive, ask before touching its worktree. Map each to its WP by the `<M> WPx.y` in its commit subjects or its `.implement/reports/<WP>.md`; with neither, match its changed paths against WPs' files owned, or ask. Classify:
   - **merged** — `git merge-base --is-ancestor <branch> HEAD` succeeds (and not reverted) → only clean up: unlock if needed, `git worktree remove`, `git branch -d`.
   - **done, unmerged** — final commit present, report `Status: done`, clean tree → merge queue.
   - **partial** — uncommitted changes, or a report not `done` → salvage: `git -C <path> add -A` and `git -C <path> commit -m "WIP <M> WPx.y: salvage uncommitted changes after interruption"`; then relaunch a worker as for a task failure (swarm.md §5, "never merged"); then unlock if needed and `git worktree remove <path>`. Keep the old branch until the new worker's work is merged (merge protocol step 7 deletes it).
   - **empty** — no commits beyond its base **and** a clean tree → unlock if needed, remove the worktree, `git branch -d` the branch.
   A worktree locked by a process that no longer exists (`locked` in the porcelain output, the agent isn't running) needs `git worktree unlock` before `remove`. If `remove` or `branch -d` refuses, stop and look — never `--force` / `-D`.
4. **Leftovers on main.** Unstaged edits only to milestone status lines, WP table cells and the plan's status lines → the coordinator's unsynced markers: keep them and include them in the next doc-sync commit. Staged changes, or new ledger entries / FU-TBD replacements not yet committed → an interrupted step 5: finish it (re-check the ledger as in 2.2) and commit `Record follow-ups for <M> WPx.y`. A dirty tree whose changes fall inside the in-progress WP's files owned → an interrupted guided WP (see `guided.md`). Dirty files elsewhere → stop and ask (`--unattended`: stop with `needs-user`).

Print a resume table — WP · state · action — and ask "Resume?" once (`--unattended`: don't ask, resume). Self-invoked runs (SKILL.md rule 3) that find swarm state stop here and ask the user to type `/implement`. Then continue with the normal preflight from the clean-tree check onward (an accepted guided leftover is exempt from it).
