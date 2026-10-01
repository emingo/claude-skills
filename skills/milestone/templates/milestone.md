# <ID> — <Title>

**Status:** proposed
**Depends on:** <ID> (<what it provides>), … | — 
**Blocks:** <ID> (<why>), … | —
**Can run alongside:** <IDs, with any condition> | —
**Execution:** <guided | swarm>
**Work packages:** <N>
**Written against:** `<sha>` (<YYYY-MM-DD>)

Spec source: [plan](../<plan>.md) §<gate ref>, §<spec refs>.

## Objective & why it matters

<!-- What this milestone makes true, and the cost of getting it wrong — which later milestones block or redesign if this is shaky. One or two paragraphs. -->

## Spec references

<!-- Bullets: `§x.y (what it covers here)`. Reference, never restate. -->

## Scope

### In

<!-- Bold-led bullets per area/layer. Use the project's layer names when it has them. -->

### Explicitly out of scope

<!-- Each exclusion cites who owns it: another milestone, a plan non-goal, or a ledger entry — so it isn't re-litigated mid-implementation. -->

## What exists

<!-- Inventory of the code/docs this milestone builds on: | Piece | Where | State |. Include known gaps and bugs. If written before a dependency landed, open with:
_Projected — written before <ID> landed; `/milestone refresh <this id>` replaces this with a real inventory._ -->

## Entry criteria

<!-- What must be true before WP.0 starts: dependencies landed, questions answered, tools available. -->

## Design questions

<!-- One ### per open design choice, including [VERIFY] tags / register questions this milestone owns and ledger entries it resolves (put the Q/FU ids in the title). Numbered D1, D2… per doc — never Q (that's the plan's register). Format:

### D1. <Title> (Q5, FU-012)

**Proposal:** <the recommended answer and why>.
*Alternative:* <the credible other option> — <why not>.

During implementation, append under the question:
- **As built (WP<n>.<k>, YYYY-MM-DD):** <what was actually done>

If there are none: None — <reason>. -->

## Work packages

<!-- Commit-sized. Ids: WP + milestone id minus its letter prefix (M2 → WP2.1, M6a → WP6a.1). WP<n>.0 = apply reviewer decisions, confirm entry criteria, and pre-edit the shared hotspots (package refs, project/solution files, registries, DI wiring) the other WPs would otherwise each edit. Last WP = verification + doc-sync + ledger. Write every WP swarm-ready whatever the Execution mode: `After:` lists the WPs that must land first, and WPs that `After:` leaves unordered never share a file. Format:

### WP<n>.1 — <Title> *(gating note, e.g. "gate: must land before WP<n>.2–.4" / "depends on D2")*

**After:** WP<n>.0 | —
**Files owned:** `path/A.ext`, `path/B.ext` *(M0-owned — extended here)*, `tests/.../ATests.ext`

<Scope paragraph: what to build, which contracts it implements, what to watch for.>

**Definition of done:** <test-observable outcome — named tests pass, command output, not "implemented">.
-->

## Contracts introduced

<!-- Interfaces/types/schemas/CLI surfaces this milestone freezes, as a code block. Later milestones cite them as "<ID>'s <Contract>". Or: None new — <which existing contracts it implements>. -->

## Test requirements

<!-- Map each acceptance criterion to a named test (| Criterion | Test |) plus fixtures. Under TDD, each WP's definition of done starts with the test written and failing first. -->

## <Project obligation — e.g. Trace obligations / Seam changes>

<!-- Replace this placeholder with the Section profile's sections (each one, in profile order; "None — <reason>" when this milestone doesn't touch it). If the profile is "Default sections only", remove the placeholder — the only heading that may be removed. -->

## Acceptance criteria

<!-- From the plan gate, expanded. Build and test gates first, then milestone-specific observable outcomes, then repeated grep-able conventions. Optional nested block for things only a human can confirm:
- [ ] `<build command>` succeeds with 0 warnings
- [ ] `<test command>` — all green
- [ ] <observable outcome>
- [ ] Interactive, user-confirmed:
  - [ ] <what the user checks>
When ticked: `- [x] <criterion> — <TestClass.Method / command → output / user quote>`. Unmet: stays `[ ]` with a **bold reason**. -->

## Follow-up ledger reconciliation

<!-- Every open ledger entry whose Areas overlap this milestone; ids link to the ledger (relative path + anchor). Disposition: **Resolved here** (which WP) / Re-deferred (reason, new owner) / Must not worsen / Interacts (how). Example row:
| [FU-012](../follow-ups.md#fu-012) | Pipelines, resize | **Resolved here** — WP3.2 |
If none overlap: None — no open entries overlap (checked <date>). -->

| FU | Areas overlap | Disposition |
|---|---|---|

### New follow-ups raised

<!-- Filled during implementation via /followup; list ids with one line each. Until then: None yet. -->

## Risks / known-hard-parts

<!-- What's likely to go wrong or take longer, and the mitigation. Include "Skeleton objection:" lines if a drafter disagreed with a fixed skeleton field. -->

## Refresh log

<!-- Appended by `/milestone refresh`:
### Refreshed YYYY-MM-DD (against `<sha>`)
- <section>: <what changed and why>
Until the first refresh: None yet. -->

## Reviewer decisions

<!-- Filled when the user approves the doc:
### YYYY-MM-DD
1. **D1:** <decision> — <reason if given>.
Until approval: _Pending review._ -->

## As-built record

_Not implemented yet._

- **Landed:** _n/a_
- **Deviations from this plan:** _n/a_
- **Discovered during implementation:** _n/a_
- **`[VERIFY]` / register answers:** _n/a_
- **Follow-ups opened:** _n/a_
- **Acceptance evidence:** _n/a_
- **Notes for the next milestone:** _n/a_

<!-- Filled only once all acceptance criteria pass (per-WP progress goes on the WP as "**Status: ☑ landed** (sha)"). Later additions and corrections are dated H3s: "### YYYY-MM-DD — <event>". Never rewritten. -->
