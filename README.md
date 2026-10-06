# claude-skills

My user-level Claude Code configuration — global instructions, subagents and skills — kept in git with the reason for every change. It's a personal setup, not a product: the instructions are tuned to how I work. But everything is plain Markdown, and most pieces can be lifted on their own.

## What's here

| Path | What it is |
|---|---|
| `skills/impl-plan`, `skills/milestone`, `skills/implement` | A plan → milestone docs → implementation workflow (see below) |
| `skills/followup` | `/followup <note>` — records deferred items, compromises and decisions to revisit, one file per entry (`docs/fu/`), and regenerates a one-line-per-entry index for you (`docs/follow-ups.md`, needs PowerShell 7) |
| `skills/walkthrough` | `/walkthrough` — works through a list of questions or findings one point at a time with a decision log; `/walkthrough tour` is a guided tour of a document or repo |
| `agents/doc-sync.md` | Updates a project's existing docs after work lands: status lines, checklists, as-built records, the ledger |
| `agents/*-reviewer.md`, `agents/reviewer.md` | Read-only pre-commit reviewers: C#, React (plain React + Zustand + styled-components), Python, Vulkan/GPU, and a generic one |
| `agents/docs-writer.md`, `refactorer.md`, `test-writer.md` | Small general-purpose agents |
| `main-agent/CLAUDE.md` | My global instructions (deployed as `~/.claude/CLAUDE.md`). Personal preferences — read it as an example, don't install it |
| `scripts/sync.sh` | Copies this repo to and from `~/.claude` |
| `scripts/lint.sh` | Checks the repo's own conventions (names, frontmatter, cross-references) |
| `scripts/smoke.sh`, `check-test.sh` | Start a smoke test's session with its first prompt; check what it left on disk |
| `CHANGELOG.md` | Why each change was made, usually the failure in a real session that prompted it |
| `tests.md` | Manual smoke-test runbook for the skills, with a run log |
| `CLAUDE.md` | Guidance for Claude when working *on this repo*: cross-file contracts and authoring conventions |

## The planning workflow

1. **`/impl-plan <what to build>`** writes one plan doc: goal and non-goals, decisions with the rejected alternatives, stack, repo layout, spec, milestone gates, and a register of unverified assumptions. A fresh-context subagent critiques it before you review it.
2. **`/milestone all`** splits the plan into one doc per milestone: design questions, commit-sized work packages with exclusive file ownership, and an acceptance checklist. `/milestone refresh <id>` re-validates a doc written ahead of time against whatever landed since.
3. **`/implement <id>`** implements a milestone from its doc.
   - *Guided* (default): one work package at a time — implement, review, commit, sync docs, pause for you.
   - *Swarm*: parallel agents in git worktrees; the main session merges them one at a time and can resume after an interruption.
   - `/milestone mode` switches a milestone between the two.
4. **Throughout:** `/followup` keeps anything deferred from getting lost — a deferred entry that names a milestone blocks that milestone from landing — and `doc-sync` keeps the plan and milestone docs matching what was actually built.

The rules these share (doc roles, status words, who may change what) are in `skills/impl-plan/reference/doc-model.md`.

## Trying it

The safest way is project-local: definitions in a project's `.claude/` shadow global ones and touch nothing else. From a scratch project:

```bash
mkdir -p .claude/skills .claude/agents
cp -r /path/to/claude-skills/skills/{impl-plan,milestone,implement,walkthrough,followup} .claude/skills/
cp /path/to/claude-skills/agents/{doc-sync,reviewer}.md .claude/agents/
```

Copy the skills together — `milestone`, `implement` and `walkthrough` read files from `impl-plan`. Then start a **new** Claude Code session; skills and agents load at startup.

`/implement` runs a review agent before every code commit. It uses the one your `~/.claude/CLAUDE.md` names in an "Agents" section; without one it falls back to the generic `reviewer` copied above.

To install for all projects, copy the same folders into `~/.claude/skills/` and `~/.claude/agents/` instead.

### What `sync.sh` does to your config

`scripts/sync.sh apply` deploys every agent and skill here to `~/.claude`, replacing any of yours with the same name. Overwritten files are backed up under `.sync-backup/` in the clone. `scripts/sync.sh pull` copies the other way.

Neither touches the global `CLAUDE.md` unless you pass `--global`, so your own instructions stay yours. Use `--global` only on a fork where `main-agent/CLAUDE.md` is your own file.

`scripts/sync.sh status` and `diff` are read-only, and `CLAUDE_CONFIG_DIR=/some/scratch/dir scripts/sync.sh apply` shows what a deploy would do without touching your real config.

## Caveats

- **Check the run log.** The table at the bottom of `tests.md` records which smoke tests were run against which commit. Anything not logged there is unverified as deployed.
- **Start guided.** Swarm mode runs several agents at once and burns through usage limits quickly.
- **`sync.sh` needs bash 4+** — Git Bash on Windows or any current Linux. macOS's stock bash 3.2 lacks `mapfile`; use a Homebrew bash.
- **`tests.md` is written for my machine:** its by-hand setup blocks are PowerShell with Windows paths, though `scripts/smoke.sh` does the setup in bash. Tests 3, 4 and part of 9 run against private repos and aren't included. Tests 1, 2, 5–8 and 10 need only a scratch folder; Test 11 works on any repo you know well.
- The reviewer roster covers the stacks I use. Adding one means touching the files listed under "Reviewer roster" in `CLAUDE.md`.

## License

MIT — see `LICENSE`.
