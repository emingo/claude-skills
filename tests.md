# Skill smoke tests

Manual end-to-end runbook for the planning, implementation and review skills (`/impl-plan`, `/milestone`, `/implement`, `/walkthrough`, `/followup`) and the `doc-sync` agent. These are prompt files, so there's no automated suite — each test is a Claude Code session in a scratch project plus a checklist of what to look for. `scripts/smoke.sh <n>` starts a test's session and `scripts/check-test.sh <n>` checks what it left on disk; what Claude said, asked and paused on is still checked by eye.

**When to run:** after changing any file the coverage table names, rerun its tests before committing (or at least before `scripts/sync.sh apply`). When a skill's behavior changes, update its tests here in the same commit.

**Setup rules:**
- Skills load from `~/.claude`, so deploy first (`scripts/sync.sh apply`) — or, to trial a draft without deploying, copy `impl-plan`, `milestone`, `implement` and `walkthrough` together into the scratch project's `.claude/skills/` (they read each other's files).
- Every test needs a **new** Claude Code session; skills are loaded at startup.
- **Starting a test:** `scripts/smoke.sh <n>` (Git Bash) asks which model to use, prints the test's section, and on a keypress opens the session in the scratch folder with the test's first prompt. That prompt is the first untagged code block in the section, so keep it first when editing a test; a prompt with `<placeholders>` is asked for. Test 1 also gets its folder created (default `../scratch-plantest`; `--dir` or `$SMOKE_DIR` to change it); Tests 3, 4 and 11 run elsewhere and need `--dir`. It warns when the deployed config differs from the repo.
- **After a test:** the launcher runs `scripts/check-test.sh <n>` when the session ends. It checks the on-disk results of Tests 1 and 5 and prints the run-log row; for other tests it prints only the row.
- Run everything in scratch folders or scratch clones, never in the real repos.
- Tests 3 and 4 and Test 9's read-only `status` check run against private repos, so they live in an untracked `tests.local.md` (gitignored). On another machine, write your own equivalents against a project you know well.
- Tests 1–2 and 5–9 build on each other in `C:\dev\scratch-plantest`, in order. Tests 3–4 (local) are independent. Test 10 needs only Test 1's plan and docs. Test 11 runs in a scratch clone; delete its notes file afterwards.
- Tick checkboxes locally while running, then `git checkout tests.md` to drop the ticks **before** adding your row to the [run log](#run-log) — the log is what gets committed, not the ticks.

## Coverage

| Skill / agent | Tests |
|---|---|
| `impl-plan` | 1 |
| `milestone` — `all --full` / `<id>` / `next`, folder layout, size budgets, parallel drafting | 1, 3 |
| `milestone` — just-in-time `all` (only the next milestones) | none yet — run `/milestone all` on a fresh plan and check that only the startable milestones get folders |
| `milestone` — `refresh` (incl. `--autonomous`) | 2, 4, 7 |
| `milestone` — convention detection | 3, 4 |
| `milestone` — `mode` | 6 |
| `implement` — guided, self-invocation gate, dependency check | 5, 9 |
| `implement` — swarm, resume, salvage, cleanup, `--step`, per-wave sync | 7 |
| `implement` — unattended loop (`implement-loop.ps1`, `--unattended`, state file) | 12 |
| `implement` — merge gates | 8 |
| `implement` — just-in-time docs (writer agent, no recheck, `--auto-approve`) | 13 |
| `implement` — `status`, forbidden paths | 9 |
| `followup` — Kind, Why accepted, Revisit when | 1, 2, 5, 7, 9 |
| `doc-sync` — milestone markers, landing rules, drift repair | 5, 7, 8, 9 |
| `wp-worker` — narrow reads, quiet commands, reviewer by diff | 7 |
| Stack reviewers — git-only Bash, `light` / `full` depth | 5, 7 |
| `doc-sync` — reading budget (sections only, no generated index) | 5, 7 |
| `walkthrough` — agenda, per-point picker, new ideas mid-review, log, resume, apply, plan mode | 10 |
| `walkthrough` — tour mode (document, repo), notes, no over-triggering | 11 |
| Global CLAUDE.md — offer a tour for large docs / whole repos | 11 |
| `milestone` — refresh hands >4 open questions to `/walkthrough` | 10 |
| Global CLAUDE.md — offer `/walkthrough` for 5+ points | 10 |
| `impl-plan/reference/doc-model.md`, `doc-authoring.md`, `doc-sync-plan.md` | all |

Tests 3 and 4 and part of 9 are in `tests.local.md`.

## Test 1: greenfield plan → all milestones (the main test)

`scripts/smoke.sh 1` does this setup and starts the session. By hand (PowerShell):
```powershell
mkdir C:\dev\scratch-plantest; cd C:\dev\scratch-plantest
git init; git commit --allow-empty -m "init"
claude
```
The empty commit matters: the skills record the commit each doc was written against, which needs at least one commit.

**Prompt:**
```
/impl-plan A .NET 9 command-line tool called `mdlinks` that checks a folder of Markdown docs for broken links. It should find relative links to other files and to heading anchors (like `../follow-ups.md#fu-012`), resolve them the way GitHub renders them, and report broken ones. Output as human-readable text or JSON, with exit codes usable in CI (0 clean, 1 broken links, 2 usage/config error). Support a `.mdlinksignore` file with glob patterns, and a `--watch` mode that re-checks on file changes. External http(s) links are out of scope for now. Target users: me, running it locally and in GitHub Actions on my own repos.
```

**How to answer its questions** (to exercise the most paths):
- **Non-goals:** accept whatever it suggests, and add "no external URL checking".
- **Markdown parser:** it should ask about a dependency such as Markdig vs a hand-written parser, and explain what each costs. Pick **Markdig**.
- **Testing:** **TDD**.
- **Default execution mode:** **guided**. Docs come out swarm-ready either way; Test 6 switches later milestones to swarm.

**Check the plan for:**
- [ ] It printed a five-line conventions profile, all "defaults", before writing anything.
- [ ] The plan header has `**Execution:** guided`.
- [ ] `docs/implementation-plan.md` has sections numbered `## N.` separated by `---`, with no `<!-- -->` comments left.
- [ ] §2 lists decisions as Rejected/Chosen, with a **Cost:** line.
- [ ] GitHub's heading-slug rules appear as a `[VERIFY]` item with a row in the assumption table and an owning milestone.
- [ ] Every path in the layout tree names a milestone.
- [ ] M0 is a runnable skeleton, and there are 5+ milestones. If not, parallel drafting won't trigger; see the "if too small" note below.
- [ ] A critique subagent ran, and you were asked which of its findings to record as follow-ups. Say yes to one, so the ledger gets created.
- [ ] It asked before editing CLAUDE.md, and made no commits.
- [ ] It ended with "Plan approved — generate the milestone docs now?", recommending *the next milestones* (just in time) and offering *Every milestone doc now*. Pick **Every milestone doc now** — later tests need every doc.

**Check the milestone docs for:**
- [ ] With 4+ docs, drafting ran in parallel subagents after a skeleton table was built.
- [ ] Each milestone is a folder `docs/milestones/M<n>-<slug>/` with `overview.md`, one `WP<id>.md` per work package and `as-built.md`. Overviews are ≤ 16 KB (most near 12) and WP files ≤ 6 KB.
- [ ] Each overview's header has Status `proposed`, Depends on / Blocks / Can run alongside, `Execution: guided`, and Written against with a commit SHA. Its WP table lists every WP file with After, Model and Review.
- [ ] Decisions are one bullet each, `D1`, `D2`… (open: Proposal / Alternative); there is no Reviewer decisions or Refresh log section. Work packages are `WP1.0` … `WPn.N`; `.0` applies reviewer decisions **and owns the shared files** (`.csproj`, `.sln`, package references); no package is a verification step (the overview's WP table has no such row).
- [ ] Every WP file has `**After:**`, `**Model:**` (`sonnet` unless the WP must make a design choice the doc doesn't settle — at most a third on `opus`, each with that reason) and `**Review:**` (`light` for test-only or tooling WPs), and no two packages that `After:` leaves unordered list the same file.
- [ ] **What exists** is marked *Projected* on milestones whose dependencies haven't landed.
- [ ] Ledger links read `../../fu/FU-001.md`, and the follow-up you recorded appears in the `Ledger:` field of the WP that owns its files, with a disposition. No overview has a reconciliation table, a Spec references section, or an empty Risks section.
- [ ] The entry is `docs/fu/FU-001.md` with front matter (`status`, `kind`, `areas`, `files`); `docs/follow-ups.md` starts with the `GENERATED by fu-index` comment and lists it in one row.
- [ ] `docs/milestones/README.md` has the Documents table with **no** status column, the parallelism matrix and the Section profile — and no dependency graph, protocol or "Execution modes" section (the plan owns the graph).
- [ ] Depends on ↔ Blocks is symmetric. Spot-check two docs.
- [ ] Each plan gate links its doc and shows `proposed`. Nothing else in the plan changed.

**If the plan comes out with fewer than 4 milestones,** you'll only see inline drafting. That's fine; the parallel path gets covered in Test 3.

## Test 2: refresh picks up drift (same scratch folder)

This checks that `refresh` notices what landed after a doc was written. First commit the docs, then simulate work landing:
```powershell
git add -A; git commit -m "Add plan and milestone docs"
```
```
Simulate some drift for a test, don't implement anything real: create src/Mdlinks/Slug.cs with a static `string ToAnchor(string heading, bool lowercase)` method (a different signature from whatever the milestone docs planned, if they planned one), then run /followup "Slug generation must handle duplicate headings with -1/-2 suffixes like GitHub does". Commit both with message "Simulate drift".
```
Then **start a new session**. Find the milestone whose doc deals with heading anchors/slugs (`Select-String -List 'slug|anchor' docs\milestones\*\*.md`) and refresh it — say it's M2:
```
/milestone refresh M2
```
- [ ] It lists what changed since the commit M2 was written against: the new file and the new follow-up (with its `Kind`).
- [ ] If M2 consumes the slug contract, it flags the signature mismatch.
- [ ] It lists one bullet per changed section for the commit message (no Refresh log in the doc), and updates the Written-against SHA.
- [ ] It asks you M2's `D<n>` questions (proposal vs alternative), rewrites each `D<n>` bullet in `overview.md` to its decided form (`<chosen>. Rejected: … (<date>, user)`), and sets both the doc and the plan gate to `approved (date)`.
- [ ] It does **not** set `in progress`; that's `/implement`'s job when work starts.

Commit the result (`git add -A; git commit -m "Refresh M2"`) and revert the drift so it doesn't confuse later tests: `git revert --no-edit HEAD~1`.

## Test 3: regenerate a real milestone doc (local)

Runs against a private repo, so it lives in the untracked `tests.local.md` (see Setup rules). It regenerates a milestone doc that is known to be good and compares the headings, then removes five docs to exercise parallel drafting against existing ones.

## Test 4: refresh after real drift (local), plus convention detection

Runs against private repos, so it lives in the untracked `tests.local.md` (see Setup rules). It refreshes a doc that predates the `Written against` field after real work landed, and checks read-only that other projects' doc conventions are detected.

## Test 5: guided implementation of M0 (same scratch folder)

```
/implement M0
```
- [ ] Preflight runs the build and tests first (and offers `/fewer-permission-prompts` if they aren't allow-listed), then prints a run plan and goes on without asking "Start?" (it asks only when the plan holds a surprise: fallback reviewer, a forced guided milestone, a readiness failure, a worktree-base warning). Untracked files outside every work package's paths are listed, not asked about.
- [ ] The run plan names the stack reviewer. With no "Agents" section in the global or project CLAUDE.md (point `CLAUDE_CONFIG_DIR` at a scratch config holding only the skills and agents), it says it is falling back to `reviewer`; with `reviewer` not installed either, it stops and asks which agent to use.
- [ ] M0's doc gets refreshed if it's stale, committed as `Approve the M0 milestone doc`.
- [ ] For **each** work package: implement → tests → the stack reviewer (`csharp-reviewer`) → **one** commit `… (M0 WP0.n)` that also holds the `☑ landed` marker and any ledger entry, with a `Deviation:` line in its body if it differed from the WP file → **pause** with a summary (commit, test counts, reviewer findings, deviations, follow-ups with Kind, next WP). No doc-sync and no `Sync docs` commit between work packages.
- [ ] When a design question isn't settled by the doc, it **asks** you instead of deciding.
- [ ] Decline one reviewer finding on purpose. It should become a `Kind: compromise` follow-up with **Why accepted**, landing in that work package's commit.
- [ ] After the last WP it sets `in progress (verification)`, runs the acceptance criteria and runs doc-sync **once**, committed as `Sync docs for M0 (<first sha>..<last sha>)`. Then M0's overview is `☑ landed (date, sha)`, every row of its WP table says `☑ landed`, its criteria are ticked with real test output, `as-built.md` has a landing record (and a Deviations entry only for a WP that differed), and the plan gate says `landed`. If M0 has an interactive check, you're given the exact command.

Then the self-invocation gate. **Start a new session** and type:
```
Let's start implementing M3.
```
- [ ] It loads `/implement` and first asks "Implement M3 guided — one commit per work package, pausing after each, docs synced when it lands?"
- [ ] M3's dependencies haven't landed, so it lists the blockers and stops instead of starting. (If M3 happens to depend only on M0, try a later milestone.)

Now type `Let's start implementing M1.` — it should ask the same question, refresh M1 if stale, and begin guided. Do M1's first WP, then stop it.

## Test 6: switch to swarm mode (same scratch folder)

Finish M1 first (`/implement M1`, then "continue to the end of M1"). Then:
```
/milestone mode swarm from M2
```
- [ ] M2 and every later unlanded doc now say `Execution: swarm` (the suggested commit message says so); the plan header says `Execution: swarm`.
- [ ] `git diff` doesn't touch M0 or M1, nor any Status or Written-against line.
- [ ] Open `D<n>` questions are reported as a note, not a failure.

Commit it (`git commit -am "Switch M2+ to swarm execution"`).

**Negative case:** in a later doc, edit two work packages that `After:` leaves unordered so both list the same file, then run `/milestone mode swarm <that id>` again (switch it back to guided first if needed).
- [ ] It refuses that doc, names the shared file and suggests a fix (an `After:` edge, or moving the file to `.0`). Undo your edit afterwards: `git checkout -- docs/milestones`.

## Test 7: swarm run, interruption and resume (same scratch folder)

This test drives the coordinator in-session with `--step`; Test 12 covers the unattended loop.
```
/implement all --agents 3 --step
```
- [ ] The **up-front design round** asks every undecided `D<n>` across M2+ in batches of four, with a "Decide autonomously" option. Pick that option for at least one question. Then it commits `Approve M2–Mn milestone docs` and ends the turn telling you to `/clear` and re-run (design and implementation never share a session). Do that: `/clear`, then `/implement all --agents 3 --step`.
- [ ] Each milestone's `.0` runs alone as a `wp-worker` before any other worker starts on that milestone; workers run on Haiku except WPs marked `Model: opus`, and a worker whose build or tests failed is retried on Sonnet; reviewers are launched with an explicit model (`full` → Opus, `light` → Sonnet), and a WP whose report shows a review is not reviewed again by the coordinator.
- [ ] Build and test output never appears in full in the chat — only summary lines. Each merge is one `merge-wp.sh` call (merge, build, test, gates); the coordinator writes no merge script of its own.
- [ ] Every worker launches its reviewer in the foreground and ends with the one-line `BRANCH … · SHA … · STATUS … · REPORT …` message; none hands back `partial` for a missing review. A worker whose worktree started from a foreign commit re-branches to `<m>-<wp>` from the base and says so.
- [ ] Worker briefs carry capped build commands (`dotnet build -m:<n>` with `<n>` ≈ cores ÷ (workers + 1), `dotnet test --no-build`).
- [ ] No more than 3 workers run at once (`git worktree list` in another terminal).

**Interrupt it:** once `git worktree list` shows 2 or more `.claude/worktrees/agent-*` entries, close the Claude window (or kill the process). Check that at least one worktree has uncommitted changes: `git -C .claude/worktrees/agent-<id> status --short`. Then start a new session and type:
```
/implement
```
- [ ] It prints a **resume table** before anything else: merged-but-unsynced WPs (synced first), done-but-unmerged branches (merge queue), partial worktrees (salvage), empty ones (removed). Then it asks "Resume?".
- [ ] A partial worktree gets a `WIP … salvage uncommitted changes after interruption` commit and a relaunched worker. No work package is done twice.

Let it finish. Then check:
- [ ] Every merge is `Merge <M> WPx.y: …` followed by `Record follow-ups for <M> WPx.y`, and every merged WP appears in a later `Sync docs for <M> <WP ids> (<shas>)` commit — one per wave, not one per merge, none for `.0` alone, and the last one is the landing sync (`git log --oneline`). The overview's WP table marks each `☑ landed (<sha>)`; `as-built.md` has entries only for WPs that deviated.
- [ ] Once a milestone's WPs are all landed its overview says `in progress (verification)` until the landing sync. The acceptance commands are run by a `general-purpose` agent on Haiku that answers one line per criterion; the coordinator doesn't run them itself, and no `wp-worker` is launched for verification.
- [ ] The run report's Agents line names the WPs retried Haiku → Sonnet (or "none").
- [ ] Follow-up files in `docs/fu/` are sequential and unique, the generated index lists each one, and the decision you left to the agents appears with `kind: decision`.
- [ ] `git grep -n FU-TBD -- . ':!.claude' ':!docs'` returns nothing, and no `.implement/` folder exists.
- [ ] `git worktree list` shows only the main checkout; `git branch --list 'worktree-agent-*'` shows nothing (or only branches the run report lists as **Blocked**).
- [ ] The run report leads with what needs you: interactive checks with exact commands (e.g. for `--watch`), "needs your decision" items, blocked work, then decisions to review grouped by Kind.

## Test 8: the merge gate catches a note left for the coordinator

This plants a fake "finished" agent branch and checks `/implement` refuses to merge it as-is. Do it while a swarm milestone still has an open work package — if Test 7 finished everything, roll back first: `git switch -c gate-test <sha before the last milestone's merges>`.

Pick an open WP of a swarm milestone and one of its **Files owned** (say `M4`, `WP4.2`, `src/Mdlinks/Report/JsonReporter.cs`), then:
```powershell
git worktree add .claude/worktrees/agent-fake -b worktree-agent-fake
cd .claude/worktrees/agent-fake
Add-Content src\Mdlinks\Report\JsonReporter.cs "// NOTE FOR THE COORDINATOR: please double-check the escaping here"
mkdir .implement\reports -Force
Set-Content .implement\reports\WP4.2.md @'
# M4 WP4.2 - fake test
**Status:** done
## Reviewer
csharp-reviewer - no findings
## Follow-up candidates
None
'@
git add -A; git commit -m "Add escaping check (M4 WP4.2)"
cd ..\..\..
claude
```
```
/implement
```
- [ ] The resume table lists `worktree-agent-fake` as **done, unmerged** for WP4.2.
- [ ] After merging, the gate flags the `NOTE FOR THE COORDINATOR` line and resolves it (acts on it or turns it into a follow-up) **before** the `Sync docs` commit. The note isn't left in the code.
- [ ] The fake worktree and branch are removed afterwards (`git worktree list`, `git branch --list 'worktree-agent-*'`).

## Test 9: deferred criteria, user checks, and status on real repos

**Deferred criterion** (same scratch folder, before its milestones land): in an open milestone, say M3, add an acceptance criterion that can only pass once a later milestone, say M4, exists (e.g. "`--watch` re-checks on change" if watch mode is M4). Commit it, then `/implement M3`.
- [ ] The criterion stays `- [ ]` with a bold reason citing a new `Kind: deferred` follow-up whose `Revisit when` is **M4** (not M3).
- [ ] M3 still lands — doc-sync treats the deferred criterion as settled, not as "could not fix"; M4 refuses to land while that follow-up is open (doc-sync reports it instead).

**User check:** when a milestone's only open criteria are interactive, tell it you can't check right now.
- [ ] Its status becomes `in progress (awaiting user check)`, and its dependents still start.
- [ ] A later `/implement` (no arguments) offers the checks again with the exact command; confirming with a quote lands the milestone.

**Read-only status on real repos:** in the untracked `tests.local.md` (see Setup rules) — leftover worktrees, doc drift, and submodules listed as forbidden paths.

## Test 12: unattended loop (same scratch folder, a later swarm milestone still open)

```
/implement all
```
- [ ] After the design round and the `Approve …` commit, it starts `implement-loop.ps1` detached (a minimized PowerShell window on Windows), says how to stop it (`-Stop`), and relays loop lines (`RUN`, `DONE`, …) one line each. Closing the session doesn't stop the loop.
- [ ] `loop.log`'s `START` and `RUN` lines show `model=opus` / `--model opus` (no `--model` given), and each `DONE` line ends with `· cost <model> $…` per model — Haiku for the workers and the verification runner, Sonnet for doc-sync, `light` reviews and retries, Opus for the coordinator, `Model: opus` workers and `full` reviews. Re-running with `/implement all --model sonnet` shows `model=sonnet` instead.
- [ ] `.implement/loop/` holds `loop.log`, `state.json` and `run-<n>.jsonl`, and `git status` stays clean (the folder ignores itself).
- [ ] Each milestone ran in its own session: one `run-<n>.jsonl` per milestone, each starting with a fresh context.
- [ ] Run `pwsh -NoProfile -File <skills>/implement/scripts/implement-loop.ps1 -Stop` from another terminal: the loop logs `STOP requested`, finishes the current milestone, and ends with `STOPPED on request`.
- [ ] Running `/implement` in an interactive session while the loop runs reports the running loop instead of starting a second coordinator (the loop's own `--unattended` sessions don't stop on it).
- [ ] The coordinator session never ends a turn while a worker is running: between merges it sits in `wait-workers.ps1` calls, so a worker that takes longer than ten minutes doesn't end the session. If a session does die after committing work, the log says `INTERRUPTED … resuming` and the loop goes on instead of stopping after two.
- [ ] With a one-milestone scope (`/implement M4`), the loop logs `ALL DONE — scope M4 is one milestone` right after `DONE` and starts no second session.
- [ ] A milestone with only interactive criteria ends as `awaiting-check` and the loop moves on; a "needs user" decision stops the loop with `NEEDS YOU`.

## Test 13: just-in-time doc (same scratch folder)

Pick an unlanded milestone whose dependencies have landed, say M3. Remove its doc so it has to be written just in time: delete `docs/milestones/M3-<slug>/`, drop its row from `docs/milestones/README.md`, set its plan gate back to `not written`, and commit. New session:
```
/implement M3 --auto-approve
```
- [ ] Right after the resume check — alongside the baseline, before any question — it launches **one** `general-purpose` agent on Sonnet (or better) for M3's doc; the session itself never loads `/milestone` and writes no doc file.
- [ ] Within about three minutes the agent hands back a `SCAN` report (work packages, decisions for the user, split suggestion). The session resumes the same agent with SendMessage to write the doc; the final reply is the short doc report (sizes, open decisions, Opus WPs, consistency issues, ledger entries to re-defer). The overview was written once, last, and is at most 16 KB.
- [ ] Only choices that shape a contract, a file layout or visible behaviour come back as decisions; the rest are already decided bullets marked `(<date>, autonomous)`.
- [ ] No refresh runs. With `--auto-approve` no question is asked: every open `D<n>` bullet becomes its Proposal, marked `(<date>, autonomous, FU-NNN)` where it shapes a contract, layout or behavior, and those follow-ups exist with `kind: decision`.
- [ ] One commit `Add and approve the M3 milestone doc` holds the folder, the index row, the gate (`approved`) and the ledger entries.
- [ ] It then starts WP3.0 in the **same** session — no "`/clear`, then `/implement`".
- [ ] Repeat on another milestone **without** `--auto-approve`: the first batch of questions arrives while the doc is still being written, an answer that differs from its Proposal is sent to the writer as an amendment in one message, and nothing is asked after the last answer. The decisions are asked in batches of four (Proposal recommended, Alternative, "Decide autonomously"), answers are recorded as `(<date>, user)`, and implementation starts right after the commit.
- [ ] A milestone whose doc was written earlier with `/milestone` and committed: `/implement` refreshes it without re-reading the code (nothing but the doc's own commit landed since) and only asks its open decisions.

## Test 10: point-by-point walkthrough

In `scratch-plantest` with Test 1's plan and milestone docs, **on a throwaway branch** so the other tests' state isn't touched: `git switch -c t10 <commit with Test 1's docs>` (discard it afterwards with `git switch - ; git branch -D t10`). Accept edits for the session when Claude suggests it. Pick a milestone with several undecided `D<n>`, e.g. M2. New session:
```
/walkthrough docs/milestones/M2-<slug>/overview.md#Decisions
```
- [ ] It shows an agenda table (`# · ID · point · recommendation · ⚖/✓`), keeps the doc's own labels (`D1`, `D2`…) as IDs, names the mode (decide), and asks once how to proceed. Choose **One by one**.
- [ ] It creates `docs/reviews/<date>-<slug>.md` and prints its path.
- [ ] Every point has a `Point N/M · Dn — …` header, a brief of roughly 300 words or less with options, a **Recommend** line, and a picker: Recommended / alternative / Tell me more / Defer.
- [ ] An explain-only point in the list (nothing to decide) gets the tour picker — Got it / Expand / Skip — and the outcome `understood` in the log.

Now exercise the reply paths:
- [ ] **Tell me more** on one point → a deeper explanation, then the **same** point's picker again.
- [ ] **Defer** one → a `Kind: decision` (or `deferred`) follow-up appears in the ledger; the point's outcome says `deferred (FU-NNN)`.
- [ ] **Refine** one through Other ("yes, but …") → restated in one line, then recorded.
- [ ] Reply **"approve, but what about <a new idea>?"** once → the approval is recorded, the idea becomes a new agenda point (`New 1`) handled right away, and any later point it affects is announced as reworked (or marked `covered by`).
- [ ] **Skip** one → it comes back at the completeness check.
- [ ] After three straight accepts, it offers "accept the rest of … as recommended?" once.

Then check:
- [ ] Each decision lands in M2's `overview.md` as it's made — its `D<n>` bullet rewritten to the decided form — and every "recorded" line names the log path.
- [ ] The end lists any point without an outcome, prints a summary table with outcomes, asks once before applying queued edits, reports anything added that wasn't discussed, and suggests a commit message without committing.

**Resume:** start another walkthrough, `pause` after two points, open a new session, and type `let's continue` (or `/walkthrough resume`).
- [ ] It picks up at the first open point with a one-line recap.

**Two unfinished logs:** start a second walkthrough, pause it too, then `/walkthrough resume`.
- [ ] It lists both (date · source · open count) and asks which, instead of guessing.

**Chat-sourced resume:** ask a question whose answer lists 5+ points, run `/walkthrough` with no argument, pause after one point, start a new session, `/walkthrough resume`.
- [ ] It continues with the remaining points' substance intact (from the log's stubs), not just their titles.

**Refresh hand-off:** on a milestone doc with more than four undecided `D<n>`, run `/milestone refresh <id>`.
- [ ] Approval runs as a walkthrough, then returns to refresh in the same turn: deferred/open `D<n>` are listed with "take the Proposal or keep `proposed`", and the approval commit includes the walkthrough log.

**Plan mode:** enter plan mode, then `/walkthrough <doc>`.
- [ ] No file is written (no log, no doc edits, no follow-ups); at the end it lists what to write once plan mode is off.

**Proactive offer** (new session):
```
Review docs/implementation-plan.md for gaps, risks and missing decisions.
```
- [ ] A response with 5+ findings ends with a compact table (# · point · recommendation, judgment calls flagged) and offers `/walkthrough` — not a list of questions.
- [ ] Accepting runs it with no argument, in **review** mode (picker: Accept / Reject / Tell me more / Defer), with proposed text shown for each change.
- [ ] Negative: a `reviewer` agent's report relayed during a commit (5+ findings Claude is about to fix) does **not** end with a walkthrough offer.

## Test 11: guided tour (information only)

Run in a clone of a repo you know well, so you can judge the explanations. A tour edits nothing, so no branch is needed. Substitute a large document, a type and a landed milestone doc from that repo for the `<…>` placeholders below. New session:
```
/walkthrough tour docs/<large doc>.md
```
- [ ] It reads the document, then shows an outline of **5–9 stops** (grouped by idea, not one per heading) as a table with what you'll learn and the source range for each, and asks once for depth: Standard / Overview / Deep.
- [ ] Each stop has a `Stop N/M — …` header, a brief of roughly 300 words or less that leads with the one idea and cites real sections or lines, and a picker: **Got it — next** / **Expand** / **Skip — review later**.
- [ ] **Expand** goes deeper on the same stop (an example, a traced path, a diagram) — on a big stop it offers sub-stops (`3.1`, `3.2`) — then returns to the same stop's picker.
- [ ] Type a **question** in Other → answered from the document, then the same stop is offered again. Ask one the document can't answer → it says so and parks it as an open question.
- [ ] **Skip** one stop → it's listed at the end with "review now / leave for later".
- [ ] Ask "should we change this?" about something → it's parked as a decision, not decided mid-tour.
- [ ] The end gives a recap of ten lines or fewer, the skipped stops, the open questions, and the parked decision with an offer to walk through it or record a follow-up.
- [ ] `git status` is clean: no log, no notes, no edits. Then say **"save notes"** → a `…-tour-….md` file appears in the log dir (asking first if `docs/` doesn't exist), with `Mode: tour` and the stops' outcomes; nothing is committed.

**Notes and resume:** start another tour, say "save notes" after stop 2, continue to stop 4, then open a new session and run `/walkthrough resume`.
- [ ] The notes file was updated after stops 3 and 4 (not a one-time snapshot), and the tour continues at stop 5.
- [ ] `pause` on a chat-only tour offers once to save notes and says it otherwise continues only in this conversation.
- [ ] In plan mode, "save notes" writes nothing and offers to save once plan mode is off.

**Depth and numbering:** choose **Deep**, or pick stops at the outline.
- [ ] The outline is re-shown once with final numbers; sub-stops read `Stop 3.2 — … · part 2 of 3` and don't change `N/M`; after the last sub-stop the picker for stop 3 returns.

**Repo tour** (new session):
```
/walkthrough tour .
```
- [ ] It explores first (README, CLAUDE.md, manifests, entry points; subagents on a large repo), then outlines top-down: what it is → how to run it → the map → the main flow end to end → key modules → conventions and gotchas → current state.
- [ ] Stops cite real `file:line` locations and short snippets, and anything inferred is marked **[U]**.
- [ ] Start a second tour with a goal — `/walkthrough tour . I need to add a new <feature>` — and the outline says `Tailored to: …`, with stops on that path first.
- [ ] **Topic tour:** after Claude writes a long plan or report, `/walkthrough tour the plan you just wrote` tours its sections.

**No over-triggering** (new session, one prompt each):
- [ ] `What does <SomeType> do?` → a normal answer, no tour.
- [ ] `Walk me through how <SomeType> handles a request.` → a normal answer, no tour.
- [ ] `Help me understand what this repo does.` → a short overview that ends by **offering** a tour; it doesn't start one unasked. Reply `yes` → the tour starts on the repo without re-asking the target.
- [ ] `/walkthrough docs/milestones/<landed doc>.md` on a doc with nothing left to decide → it says nothing is open and offers a tour; `/walkthrough docs/milestones` asks: open decisions, or a tour.
- [ ] `Guide me through this repo step by step.` → the tour starts.

## When a check fails

1. Note the test, the checkbox, and the relevant output (what Claude said or wrote).
2. Fix it in `claude-skills` — usually a line in a `SKILL.md`, in `doc-model.md`, or in one of `/implement`'s reference files — and update the affected test here if the expectation itself was wrong.
3. Add a `CHANGELOG.md` entry, commit, `scripts/sync.sh apply`, and rerun the test in a new session.
4. Record the run below.

Clean up afterwards: delete the scratch folders and clones (in `scratch-plantest`, `git worktree prune` first if a test left worktrees behind).

## Run log

Append a row per run, newest first. "Skills at" is the `claude-skills` commit that was deployed; "Model" is the session's main model, since a result on a cheaper model doesn't carry over to another.

| Date | Tests | Skills at | Model | Result | Notes |
|---|---|---|---|---|---|
