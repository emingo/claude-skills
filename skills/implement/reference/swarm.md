# Swarm mode

This session is the **coordinator**: it launches `wp-worker` agents for every work package (`.0` first and alone), merges, gates, numbers follow-ups, writes the progress markers and syncs docs once per merged wave — on the main branch, one merge at a time. It runs only the verification WP itself, and lean. Workers only write code in their own worktree. Keep this session's context small (SKILL.md rule 13).

## 1. Eligibility and the rolling pool

A work package is **eligible** when all hold:
- its milestone doc is `approved` or `in progress`;
- every milestone it depends on is landed or awaiting a user check;
- every WP in its `After:` list is **landed** (doc-model: merged, not reverted, marked `☑ landed` by doc-sync) — and every non-`.0` WP is implicitly After `WP<n>.0`;
- none of its files owned are owned by a running WP;
- it carries no `⛔ blocked` marker in the overview's WP table.

**`.0` runs first and alone, as a worker, for each milestone entering the pool** — it applies reviewer decisions and pre-edits the shared hotspots (package references from Stack, project/solution entries, registries, DI wiring) so parallel workers never touch them. Merge it (§3) and sync before the pool starts.

**Pool:** keep `min(N, eligible)` workers running (N from `--agents`, default 4). Launch each with the Agent tool: `subagent_type: wp-worker`, `model: "opus"` only when the WP says `Model: opus` (otherwise omit it — the agent defaults to Sonnet), `isolation: "worktree"`, `run_in_background: true`, prompt = `${CLAUDE_SKILL_DIR}/templates/agent-brief.md` filled in (with `wp-report.md` embedded). A retry (§5) keeps the WP's model when the failure was mechanical (merge conflict, interruption, salvage, ownership violation); only a Sonnet worker whose build, tests or logic failed is retried on Opus. Group several WPs into one worker only when `After:` chains them and they share files; the report is named after the first WP. Note which agent runs which WP — resume must never salvage a worktree whose agent is still running. After every merge (§3), recompute eligibility and refill free slots — later workers then branch from a newer main and inherit fixes instead of re-applying them.

**Builds share the machine.** Up to N workers and this session build at once, and each build defaults to every core, which oversubscribes the CPU. The build/test commands in every brief — and your own after a merge — cap a build's parallelism at `max(1, cores ÷ (running workers + 1))` and skip work already done. For .NET: `dotnet build -m:<n>`, then `dotnet test --no-build` (`--no-restore` on any command after the worktree's first restore). Other stacks: the equivalent jobs flag (`make -j<n>`, `cargo build -j <n>`, `npm`/`pnpm` workspace concurrency). Recompute `<n>` when the pool size changes.

The last WP of each milestone (verification) runs in this session once every other WP of that milestone is landed: run each acceptance command quietly (slow ones guarded, rule 14), keep the literal summary lines, and hand them to doc-sync — which ticks criteria, updates README/CLAUDE.md and lands the milestone, or sets `awaiting user check` for interactive criteria.

## 2. Worker results

Workers finish with one line: `BRANCH <name> · SHA <sha> · STATUS done|blocked|partial · REPORT .implement/reports/<WP>.md`. The full report is the committed file on their branch — read it with `git show <branch>:.implement/reports/<WP>.md`. Queue `done` results for merging in finish order; send `blocked`/`partial` and errors to §5.

## 3. Merge protocol (one at a time)

1. **Inspect:** `git log --oneline <main>..<branch>` and `git diff --stat <main>...<branch>`. Files touched must be within the WP's files owned plus its report; the report says `done`; its Reviewer section shows the reviewer actually ran — then never review it again, `.0` included. Empty or "not run" → run the stack reviewer yourself first, briefed with `git -C <worktree> diff <base>...HEAD` and the WP's review depth, on the model that depth sets (SKILL.md rule 6). A file outside ownership → read why in the report; accept only if the edit is necessary and doesn't collide with a running WP's files, otherwise treat as a task failure (§5).
2. **Merge:** `git merge --no-ff <branch> -m "Merge <M> WPx.y: <title>"` (grouped: `Merge <M> WPx.y/x.z: <title>`). A conflict you fully understand (additive hunks) → resolve it; anything else → `git merge --abort` → task failure (§5).
3. **Build + full test.** Red → an integration commit `Integrate <M> WPx.y with <other>: <what>` (stack-reviewed; you aren't bound by file ownership here; it's recorded as a deviation). Not fixable with bounded effort → revert **newest first**: any integration commits for this merge (`git revert <sha>`), then the merge (`git revert -m 1 <merge sha>`); record the revert sha(s) → task failure (§5). Tests the report lists under "Tests outside ownership affected": if the milestone doc intends the behavior change, update them in the integration commit; otherwise revert and open a follow-up.
4. **Gates** on the lines this merge added (`git diff <pre-merge>..HEAD`): `NOTE FOR|COORDINATOR|TODO|FIXME|HACK|FU-TBD` and the milestone's grep-able convention criteria. Resolve each hit before step 6: a TODO/FIXME without an FU id becomes a follow-up candidate; a coordinator note becomes an action now or a follow-up.
5. **Follow-ups.** For each candidate in the report (and from the gates): grep the ledger for an existing entry first (`files:`, `areas:`, key terms) — a duplicate becomes evidence for doc-sync to append as an Update. Otherwise `/followup` with its Kind, Why accepted, Revisit when, Impacts, and Origin `— <M> WPx.y (swarm report)`. Replace each `FU-TBD-<WP>-<n>` in the code with the real id; `/followup` regenerates the index. Then `git rm .implement/reports/<WP>.md` and **commit right away** — `Record follow-ups for <M> WPx.y` (report removal, placeholder replacements, new ledger entries and the regenerated index). `git merge` and `git revert` refuse to run while the index holds staged changes, so nothing staged may wait for the wave.
6. **Markers now, doc-sync per wave.** Right after the merge, write the WP's `☑ landed (<merge sha>)` in the overview's WP table and update the milestone's `in progress (…)` line (on its first merge, the plan gate and header too) — leave them uncommitted. Run **doc-sync** (foreground, never two at once) when the merge queue is empty and no other worker is about to finish, before the verification WP, and before stopping. Give it: the merge shas and WP ids; each report's location (`git show <final sha>:.implement/reports/<WP>.md` — it reads them itself); one line of reviewer outcome per WP; follow-up ids opened and resolved (they already exist — Updates and status flips only); integration fixes; reverted or stubbed WPs ("not landed"); the WPs running or next. Commit the markers and doc-sync's edits as `Sync docs for <M> <WP ids> (<merge shas>)`. Until then the markers stay as unstaged edits — never `git add` them before the sync commit.
7. **Clean up:** `git worktree unlock <path>` if locked, `git worktree remove <path>`, `git branch -d <branch>` — plus the branch and worktree of any earlier failed attempt at this WP. Never `-D`, never `--force`: if `-d` refuses, the branch isn't merged — keep it and find out why.
8. Refill the pool (§1).

## 4. Autonomy policy

The run doesn't wait for the user after the up-front design round (SKILL.md preflight step 7). When a choice comes up that the docs don't settle:
- **Workers** pick the option most consistent with the doc's Proposal and the frozen contracts, and record it in their report as Chosen / Rejected / **Cost** — it becomes a `Kind: decision` (or `compromise`, when there's an accepted cost) follow-up at merge.
- **This session** does the same for integration fixes and refreshes (`/milestone refresh <id> --autonomous`, then the swarm-readiness check again).
- **Never autonomous:** adding a dependency, changing a plan §Decision or gate (→ follow-up marked "needs user", work continues on the current shape), editing another repo (→ §6). These block the WP (§5) until the user decides.

## 5. Failure policy

- **Session / rate limit** (a worker errors with a usage-limit, 429 or session-limit message, or several fail the same way at once): stop launching. For each worktree whose agent has **ended** (completed or errored — never one still running) and has uncommitted changes, make the salvage commit only (`git -C <path> add -A`, `git -C <path> commit -m "WIP <M> WPx.y: salvage uncommitted changes after interruption"`) — no relaunch, no removal. Print the reset time if known and "re-run `/implement` to resume"; end the turn. This doesn't count as a retry.
- **Blocked** (a worker or merge needs a user decision: a dependency, a plan change, another repo, an unworkable contract) — **no retry.** `/followup` (Kind `decision` marked "needs user", or `limitation`), write the WP's `⛔ blocked (FU-NNN — <why>)` marker yourself (rule 2), keep its branch, list it under Blocked in the run report. Dependents of an unworkable contract are blocked the same way.
- **Task failure** (tests or build failing, merge conflict, ownership violation, `partial`, agent error) — **retry once** with a fresh worker whose brief adds the old report and the failure output, plus how to pick up the old work:
  - old branch **never merged** → "first `git merge <old branch>`";
  - old branch **merged then reverted** → "first `git revert <revert sha>` (newest revert first if several), then fix the failure" — merging the old branch would be a no-op.
- **Second task failure:**
  - if dependents need a frozen contract this WP introduces and their tests don't need its behavior, land an explicit stub in this session that fails loudly (throws "not implemented — FU-NNN"), stack-reviewed, committed as `Stub <M> WPx.y: <what> (FU-NNN)` with a `Kind: deferred` follow-up, `Revisit when: <M>`; write its marker `⛔ blocked (stubbed — FU-NNN)` yourself and tell doc-sync it's a stub, not landed;
  - otherwise block it as above.
  - Either way the milestone can't land; keep going with independent work.
- **The branch can't be made green, even after reverting the last merge:** halt everything and report.

## 6. Cross-repo work

Never edit another repo or a submodule. If the project keeps `<id>-<repo>-requests.md` docs, append the request there (this session, on main, in the sync commit); otherwise open a `Kind: limitation` follow-up whose Areas name the repo. Work that needs the external change is blocked (§5) and goes under "you must do" in the run report.
