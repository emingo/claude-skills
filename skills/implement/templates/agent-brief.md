Work package: <M> <WPx.y> — <title>   (grouped: <WPx.y, WPx.z>)
Repo: <repo path> (you are in a worktree of it) · Base: `<base sha>` on `<main branch>`
Read: <milestone overview path> and <WP file path> — nothing else from the docs.
Plan §refs (read only these): <list, or "none">
Approved Stack (the only packages you may use): <list>
Open follow-ups touching your files (cite, don't re-report): <FU ids, or "none">
Forbidden paths (never edit): <submodules, other repos, project hands-off paths>
Testing approach: <smoke | detailed unit | TDD>
Build/test commands (log to a file, print the summary lines): <commands, with the parallelism cap and skip flags from swarm.md — e.g. `dotnet build -m:3` (add `--no-restore` once this worktree has restored), `dotnet test --no-build`>
Stack reviewer: <agent> · review depth: <full | light, from the WP> · launch it in the foreground and wait for it
<Retry only: the previous report's location on its branch + the failure output (trimmed to the relevant lines), and either "first run `git merge <old branch>`" (never merged) or "first run `git revert <revert sha>`" (merged then reverted); then set the report's Status back to `in progress` in your `WIP … start` commit, and continue>

Your rules are in your agent definition (`wp-worker`). First: `git rev-list --count <base sha>..HEAD`. `0` → `git merge --ff-only <base sha>`. Anything else means this worktree started from a commit the run doesn't contain: `git switch -c <m>-<wpx.y> <base sha>` (lower case, e.g. `m41-wp41.3`; on a retry, or if that name is taken, add `-r2`, `-r3`), check the count is `0` now, and say so under Coordinator notes — your branch is then that one, not the harness branch. If you can't get the count to `0`, stop: commit nothing else, set `Status: blocked` and explain. Then do the retry step, if any; create `.implement/reports/<WPx.y>.md` from the template below and commit `WIP <M> <WPx.y>: start` right away.

When you are done, your last message is the one line your agent definition specifies — `BRANCH … · SHA … · STATUS … · REPORT …` — and nothing else: no summary, no report text.

## Report template (`.implement/reports/<WPx.y>.md`)

<contents of templates/wp-report.md>
