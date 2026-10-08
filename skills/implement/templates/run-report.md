# Implementation run — <date> · <first sha>..<last sha>

## Needs you

**Interactive checks** (milestones `awaiting user check`):
- <M> — `<exact command>` → <what you should see>

**Needs your decision** (follow-ups marked "needs user"):
- [FU-NNN](<ledger link>) — <question> — <what's waiting on it>

**Blocked** (branches kept with their unmerged work):
- <M WPx.y> — <why> — <FU id> — branch `<name>` — <what unblocks it>

**Cross-repo requests:** <requests doc entries / FU ids, or "none">

## Decisions to review

Grouped by Kind; each with Why accepted and Revisit when.

**decision**
- [FU-NNN](<ledger link>) — <title> — <one line>
**compromise**
- …
**limitation**
- …
**deferred**
- … (Revisit when: <M>)

## Progress

| Milestone | Mode | Status | WPs landed | Unticked criteria |
|---|---|---|---|---|
| <M> | swarm | ☑ landed (`<sha>`) | 5/5 | — |
| <M> | swarm | in progress (awaiting user check) | 4/4 | `--watch` re-checks on save (interactive) |
| <M> | guided | in progress (WP3.2) | 1/4 | … |

## Run details

- Stubs landed: <FU ids, or "none">
- Integration fixes: <commit · what>
- Agents: <spawned> spawned · <retried> retried (Haiku → Sonnet: <WPs, or none>) · <interrupted> interrupted (salvaged: <WPs>)
- Cleanup: worktrees <0 left / list> · agent branches of merged/empty WPs <0 left / list> · kept blocked branches <list>
- Next: `<the command to continue>`
