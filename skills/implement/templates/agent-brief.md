Work package: <M> <WPx.y> — <title>   (grouped: <WPx.y, WPx.z>)
Repo: <repo path> (you are in a worktree of it) · Base: `<base sha>` on `<main branch>`
Read: <milestone overview path> and <WP file path> — nothing else from the docs. (Single-file doc: <doc path>, sections: your WP, <decision ids>, Contracts introduced, Acceptance criteria — Grep the headings, read only those.)
Plan §refs (read only these): <list, or "none">
Approved Stack (the only packages you may use): <list>
Open follow-ups touching your files (cite, don't re-report): <FU ids, or "none">
Forbidden paths (never edit): <submodules, other repos, project hands-off paths>
Testing approach: <smoke | detailed unit | TDD>
Build/test commands (log to a file, print the summary lines): <commands>
Stack reviewer: <agent> · review depth: <full | light, from the WP>
<Retry only: the previous report's location on its branch + the failure output (trimmed to the relevant lines), and either "first run `git merge <old branch>`" (never merged) or "first run `git revert <revert sha>`" (merged then reverted), then continue>

Your rules are in your agent definition (`wp-worker`). First: `git log -1 --format=%h` — if HEAD isn't `<base sha>` or a descendant, `git merge <base sha>`; do the retry step, if any; create `.implement/reports/<WPx.y>.md` from the template below and commit `WIP <M> <WPx.y>: start` right away.

## Report template (`.implement/reports/<WPx.y>.md`)

<contents of templates/wp-report.md>
