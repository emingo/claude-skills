You are reviewing a draft implementation plan with fresh eyes before any milestone docs are written from it. You did not write it; assume nothing it doesn't say. Read-only — do not edit any file.

Plan: <plan path>
Doc model (the rules the plan must follow): <path to doc-model.md>
Project context: <project CLAUDE.md path, spec/design docs, ledger path or "none">
User decisions this session: <non-goals, stack choices, testing approach, default execution mode>

Check, in this order:

1. **Traceability.** Every Goal statement and the Definition of done is covered by at least one milestone's acceptance bullet. No acceptance bullet contradicts a non-goal.
2. **Verifiability.** Every acceptance bullet is observable by a named test or a command with expected output. Flag "works", "is robust", "handles errors" without a check.
3. **Hidden assumptions.** Facts about external systems, libraries, formats or behavior stated as certain without a source — each should be a `[VERIFY]` with a register row and an owning milestone. Also check that every existing `[VERIFY]` has a row, and every row has an owner.
4. **Contradictions** between sections (decisions vs spec, layout vs spec, stack vs code examples, gate vs dependency graph).
5. **Dependencies.** Anything in Stack or code examples that implies a package not listed or not approved.
6. **Layout ownership.** Every path in the repository-layout tree is attributed to a milestone.
7. **Milestone shape.** M0 is a runnable, testable skeleton; each milestone is independently demonstrable; the dependency graph has no cycles and matches each gate's scope; any milestone likely to need more than ~7 work packages is a split candidate; nothing essential is scheduled after something that needs it.
8. **Ledger.** If a ledger exists: open entries (grep `docs/fu/` front matter, never the generated index) whose `areas:` or `files:` overlap the plan and that it neither addresses nor explicitly defers.
9. **Doc-model conformance.** Header fields, section order, Chosen/Rejected decision format, gate-block format, `None — <reason>` instead of deleted sections.

Report findings only — no praise, no summary of the plan. For each:

```
N. [high|medium|low] §<ref> — <the problem, concretely>
   Class: fix-in-place | [VERIFY]+register | follow-up | ask-user
   Fix: <the specific edit, the register row to add, the follow-up text, or the question with 2–4 options>
```

Class meanings: `fix-in-place` — unambiguous edit the author can just make; `[VERIFY]+register` — an uncertain fact to tag and assign to a milestone; `follow-up` — real but out of this plan's scope, belongs in the ledger; `ask-user` — needs a decision only the user can make.

If you find nothing at a check, skip it silently. End with one line: `Findings: <n high>/<n medium>/<n low>`.
