# Milestone execution docs — index

This directory divides [`<plan>`](../<plan>.md)'s milestones into work packages. The plan says *what* is correct and in what order (its Milestones section has the gates and the dependency graph); each folder here says *how* one milestone's work is divided and what differed when it was built. Implement with `/implement <id>`.

## Documents

| Doc | Milestone | Gate |
|---|---|---|
| [`M0-foundation/`](./M0-foundation/overview.md) | Foundation | prerequisite skeleton + first contracts |

<!-- No status column — status lives in each doc's header and the plan's gate line. -->

<!-- If any a/b splits exist, one paragraph each: parallel halves under one shared gate, or a sequential split with separate gates — and why the split exists. Otherwise delete this comment. -->

## Parallelism matrix

| Can run concurrently | Why |
|---|---|
| <M2 ∥ M3> | <what each needs and why they don't collide> |

<!-- Include WP-level parallelism inside milestones where it matters. End with the hard sequential spine: "Everything else is sequential: M0 → M1 → …". -->

## Section profile

<!-- The project-specific sections every milestone doc carries before "Acceptance criteria" (e.g. "Trace obligations", "Seam changes — Engine.Graphics"), any renamed default sections, and any project rule that keeps parallel work packages off a shared file (e.g. registration by discovery instead of a shared list). /milestone reads this to keep new docs consistent. If none: "Default sections only." -->
