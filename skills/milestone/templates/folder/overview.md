# <ID> — <Title>

**Status:** proposed
**Depends on:** <ID> (<what it provides>), … | —
**Blocks:** <ID> (<why>), … | —
**Can run alongside:** <IDs, with any condition> | —
**Execution:** <guided | swarm>
**Written against:** `<sha>` (<YYYY-MM-DD>)

Spec source: [plan](../../<plan>.md) §<gate ref>, §<spec refs>. Work packages: one file each in this folder. As built: [as-built.md](as-built.md).

<!-- Budget for this whole file: aim for 12 KB, 16 KB at most — reference the plan by §, never restate it. A section whose comment says Optional is left out when it would be empty; every other section is required. -->

## Objective

<!-- What this milestone makes true, and the cost of getting it wrong. Two or three sentences. -->

## Scope

### In

<!-- Bold-led bullets per area/layer. -->

### Explicitly out of scope

<!-- Each exclusion cites its owner: another milestone, a plan non-goal, or a ledger entry. -->

## What exists

<!-- | Piece | Where | State | — the code this milestone builds on, incl. known gaps. Written before a dependency landed: open with
_Projected — written before <ID> landed; `/milestone refresh <this id>` replaces this with a real inventory._ -->

## Entry criteria

<!-- What must be true before WP<n>.0 starts. -->

## Decisions

<!-- One bullet per design question, D1, D2… (owned [VERIFY] tags / register questions and genuine open choices; ids in the title). While open:
- **D1. <Title>** (Q5, FU-012) — open. Proposal: <answer, one sentence, why>. Alternative: <other> — <why not>.
Once decided, the same bullet becomes:
- **D1. <Title>** — <chosen>. Rejected: <alternative> — <why>. (<YYYY-MM-DD>, user) — or (<YYYY-MM-DD>, autonomous, [FU-NNN](../../fu/FU-NNN.md))
A question that needs more reasoning gets a `### D1. <Title>` block under the list, at most ten lines. If there are none: None — <reason>. -->

## Work packages

<!-- One row per WP; the WP's own file holds its scope. Verification is not a row: once every WP is landed, /implement runs the Acceptance criteria below. Status is written by /implement: ☑ landed · ☑ landed (<merge sha>) in swarm · ⛔ blocked (FU-NNN — <why>) · ⛔ blocked (stubbed — FU-NNN); empty = open. -->

| WP | Title | After | Model | Review | Status |
|---|---|---|---|---|---|
| [WP<n>.0](WP<n>.0.md) | <Entry check and shared hotspots> | — | sonnet | light | |

## Contracts introduced

<!-- Interfaces/types/schemas/CLI surfaces this milestone freezes, as code blocks — the one thing parallel WPs must agree on. Or: None new — <which existing contracts it implements>. -->

## <Project obligation — e.g. Trace obligations / Seam changes>

<!-- Replace with the Section profile's sections, or remove when the profile is "Default sections only". -->

## Acceptance criteria

<!-- From the plan gate, expanded: build and test gates first, then observable outcomes (each naming its test or command), then grep-able conventions, then:
- [ ] Interactive, user-confirmed:
  - [ ] <what the user checks — exact command and what to look for>
Ticked by doc-sync: `- [x] <criterion> — <TestClass.Method / command → output / user quote>`. -->

## Risks

<!-- Optional — drop the heading when there are none. Likely problems and the mitigation; "Skeleton objection:" lines from drafters. -->
