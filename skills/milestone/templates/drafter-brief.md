You are drafting milestone execution docs for a project whose implementation plan and milestone skeleton are already fixed. Write only the files assigned to you below; read anything you need.

Project root: <path>
Plan: <plan path> (read the §refs listed for your milestones, plus §Decisions, §Conventions, §Assumption register)
Doc model: <path to doc-model.md> — follow it exactly (status words, header fields, links, content rules, style).
Template: <path to templates/milestone.md> — every heading, in order. Strip all `<!-- guidance -->` comments from the output; never delete a heading (empty → `None — <reason>`), except the `<Project obligation>` placeholder, which becomes the Section profile's sections (or is removed if the profile is "Default sections only").
Section profile: <project-specific sections in order, or "Default sections only">
Stack (approved packages): <list> — no work package may use anything else.
Ledger: <ledger path or "none"> — anchor style: <explicit #fu-nnn | GitHub slug>
Testing approach: <smoke | detailed unit | TDD>
HEAD: `<sha>`, date <YYYY-MM-DD> — use for every doc's `Written against`.

## The skeleton (fixed — do not change these fields)

<full skeleton table: every milestone's id, slug, Depends on / Blocks / Can run alongside, Execution, work packages with After:, files owned and gating notes, contracts introduced/consumed, acceptance criteria, owned [VERIFY]/Q items, ledger dispositions>

## Your assignment

<list of milestone ids + target file paths>

For each assigned milestone:

1. Copy the skeleton fields verbatim into the header, work package titles/files, Contracts introduced, Acceptance criteria, and the ledger reconciliation table.
2. Write the rest: Objective & why it matters (including the cost of getting it wrong), Spec references, Scope In/Out (each exclusion cites its owner), What exists (inventory the actual code; if a dependency hasn't landed, mark the section *Projected*), Entry criteria, Design questions (`D1`, `D2`… — one per owned [VERIFY]/register item and per genuine open choice; Proposal + *Alternative* with why not), WP scope paragraphs and Definitions of done (test-observable), Test requirements (criterion → named test), project obligation sections, Risks.
3. Status `proposed`. Refresh log `None yet.` Reviewer decisions `_Pending review._` As-built record exactly as in the template.
4. You cannot ask the user anything: an open point becomes a Proposal in Design questions or a `[VERIFY]` tag noted in your report.

If you believe a skeleton field is wrong (a missing dependency, a file two concurrent WPs would both edit, a contract in the wrong milestone) or a WP needs a package outside Stack, do not change it or write it in — add a `Skeleton objection: <what and why>` bullet under Risks and report it.

Report back, per milestone, nothing else:

```
<id> — <path> — <N> lines
Skeleton objections: <list or none>
New [VERIFY] tags: <list or none>
```
