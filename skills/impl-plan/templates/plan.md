# <Project> — Implementation Plan

**Status:** draft
**Execution:** guided
**Written against:** `<sha>` (<YYYY-MM-DD>)

<!-- A section whose comment says Optional is left out when it would be empty — renumber what follows and fix every § reference. Every other section is required. -->

---

## 1. Goal and non-goals

### Goal

<!-- 1–2 paragraphs: what exists when this is done and who it serves. -->

### Non-goals

<!-- Bullets. Each one a thing a reasonable person might assume is in scope. What comes after this plan is not listed here — it becomes `Kind: deferred` ledger entries. -->

### Definition of done (whole project)

<!-- One paragraph, observable: the end-to-end scenario that proves it works. -->

---

## 2. Decisions already made

<!-- One ### per decision, Rejected before Chosen when they're alternatives to each other. Each: bulleted reasons, then a one-word verdict line. Record the cost of the chosen path, not just its benefits. Reversing one is a dated, reviewed edit here, never a mid-implementation call. -->

### 2.1 Rejected: <alternative>

- <reason>

Rejected.

### 2.2 Chosen: <approach>

- <reason>
- **Cost:** <what this makes harder>

---

## 3. Reference material

<!-- Optional — drop the section when there is nothing to list. -->

| Source | Use for |
|---|---|
| <doc/url/repo> | <what to consult it for> |

---

## 4. Stack

<!-- Pin versions. A dependency added here must have been approved with "what it does / the alternative without it". -->

| Concern | Choice | Notes |
|---|---|---|
| <runtime/lang> | <choice + version> | <why / constraint> |

---

## 5. Repository layout

<!-- ASCII tree. Every file/dir annotated with the milestone that introduces it (and § that specifies it). A path with no owning milestone is a planning gap. -->

```
<root>/
  src/
    <Project>/            # M0 — <role> (§6)
  tests/
    <Project>.Tests/      # M0
  docs/
    implementation-plan.md
    milestones/
    fu/                   # one file per follow-up
    follow-ups.md         # generated index, for humans
```

---

## 6. <Specification — e.g. Execution model / Architecture>

<!-- The spec proper: one ## per subsystem (renumber following sections). As detailed as the hard parts need: contracts as code, pseudocode for the core algorithm, config examples with "Rules:" bullets, tables. Bold-callout the rule that matters most. Mark unconfirmed facts [VERIFY]. -->

### 6.1 <Subsystem>

---

## 7. Conventions

<!-- Project-specific, grep-able rules, plus any every-milestone obligation (build-warnings policy, error-path tests written with the feature). Anything checkable by grep gets repeated as an acceptance criterion in every milestone doc. -->

- Traceability tags (grep targets, not explanatory comments): `// ASSUMPTION(Qn):` on code resting on an assumption-register answer; `FU-NNN` where code knowingly defers a ledger item.
- Tests for "not implemented / unsupported" paths use reserved fake names (`x-not-a-real-<thing>`), never a real feature that isn't built yet.
- <naming / layering / error-handling rules>

---

## 8. Milestones

Each milestone below is a **gate definition**: do not start one until every predecessor in the dependency graph has landed (or is code-complete, awaiting only a user check) and its execution doc is `approved`. Its folder in [`milestones/`](milestones/README.md) divides the work and records what differed; this section stays the gate.

### M0 — Foundation

_Execution doc: [`milestones/M0-foundation/overview.md`](milestones/M0-foundation/overview.md)_ · **Status:** not written

<!-- 1–3 sentences of scope. -->

**Acceptance:**
- <observable by a test or command>

### M1 — <Title>

_Execution doc: [`milestones/M1-<slug>/overview.md`](milestones/M1-<slug>/overview.md)_ · **Status:** not written

**Acceptance:**
- <…>

### Dependency graph

```mermaid
graph LR
    M0 --> M1
```

<!-- Then: which milestones can run in parallel and why; which are strictly sequential. -->

---

## 9. Testing strategy

<!-- The chosen approach (smoke / detailed unit / TDD) and what it means per milestone: unit, integration, golden/fixture tests, how acceptance criteria map to named tests, CI gates. -->

---

## 10. Assumption register

<!-- Every [VERIFY] in this doc has a row. Owner = the milestone that must resolve it — in place, removing the tag. Basis once answered: documented / toolkit / assumed. Pinned by = the test that fails if the answer is wrong. -->

| Q | Question | Owner | Answer | Basis | Pinned by |
|---|---|---|---|---|---|
| Q1 | <question> | M<n> | _open_ | | |
