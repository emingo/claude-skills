# Global CLAUDE.md — Emilio

## Project CLAUDE.md Authoring

When I ask you to create or improve a project's CLAUDE.md (including via /init or CLAUDE.md skills), apply these standing rules:

- **React projects** (my default stack: plain React + TypeScript + Zustand + styled-components):
  - Always include a component-reuse rule: "Before creating any component, search existing components and styled blocks for one to reuse or extend with a variant prop. Never create a near-duplicate."
  - Target latest React idioms (19+: ref as regular prop instead of forwardRef, `use()`, `useActionState`; no `defaultProps`).
  - Note that `react-reviewer` is the pre-commit review agent (see Agents section below).
- **Documentation Workflow section**: include a short section (~2 paragraphs) wiring the global `doc-sync` agent and `/followup` skill, tailored to the project:
  - After completing any task or PR, launch `doc-sync` with what landed (or the commit range) plus any follow-ups that surfaced and any ledger entries the work resolved; relay its "could not fix" findings to me. Name *this project's* doc surfaces to maintain (plan/status docs, phase checklists, READMEs — discover what actually exists) and anything doc-sync must NOT touch (historical/spec docs, generated files).
  - Follow-up ledger: any deferred item, accepted limitation, or surprising constraint discovered mid-task must be recorded in the ledger before the task is considered done — `/followup <note>` captures it and creates the ledger on first use (default: one file per entry in `docs/fu/`, plus a generated index `docs/follow-ups.md` that is for me — agents never read it, they grep `docs/fu/`; name the paths explicitly if the project uses different ones). Before planning or implementing a feature, grep the ledger for open entries whose `files:` or `areas:` overlap and address or explicitly re-defer them. When I accept a proposal that carries a compromise, or a decision I might want to revisit, record it via `/followup` with the matching Kind without being asked.
  - If the project has an implementation plan and milestone docs (`/impl-plan`, `/milestone`), name them as doc surfaces: the plan carries gate definitions plus one status line per milestone; the active milestone doc carries the acceptance checklist and the append-only As-built record; landed milestone docs are frozen. Implement milestones with `/implement <id>` — guided by default (a commit plus a doc-sync commit per work package, stack reviewer per WP, pause for my review); `/milestone mode swarm …` switches milestones to parallel worktree agents, which `/implement` runs unattended by default — one design round with me, then a fresh headless session per milestone (`--step` keeps it in the session). `/implement` refreshes docs written ahead of time before starting.
  - For a minimal/throwaway project (no docs, no README), ask me whether to include this section instead of forcing it. A project needing deeper customization can shadow the global agent/skill with project-local copies in `.claude/`.
- Keep project CLAUDE.md files short and non-obvious: conventions, commands, and gotchas the code doesn't show — don't restate what's in this global file.

## Communication

- Explain decisions and tradeoffs before acting — I want to understand the *why*, not just the *what*.
- Ask me before major architectural decisions, destructive changes, or introducing new dependencies.
- Be direct. Skip preambles like "Great question!" or "Sure, I can help with that."
- When presenting alternatives, briefly state what each optimizes for so I can pick.
- In the main conversation, when a response would ask *me* to decide or weigh in on 5 or more items (decisions, questions, review findings I'm meant to judge), don't end with a wall of questions: end with a compact table (# · point · your recommendation, judgment calls flagged) and offer to go through them with `/walkthrough`. Not for findings you're about to fix yourself, not inside `/implement` runs, not when a skill is already asking via its own pickers — and never in subagent reports (they keep their own output format).
- In the main conversation, when I ask to understand a large document or what a whole repo does and a full answer would run well past a screen, give a short overview and offer a guided tour (`/walkthrough tour …`) once. A specific question, or a small doc or repo, just gets its answer. Not in subagent reports, not mid-task inside another skill's run, not again after I decline.

## Code Style

### General Philosophy

- Concise, structured, modular. Separate concerns. Keep things reusable.
- Minimal dependencies — prefer standard library and lightweight solutions over heavy frameworks.
- Strong typing and explicit contracts — avoid `dynamic`, `object`, `any`, or untyped patterns unless truly necessary.
- Pragmatic, not dogmatic — every rule below has exceptions when following it makes the code worse.

### Formatting & Density

- Prefer wider lines over splitting expressions across multiple lines.
- One-liner `if`/`for`/`while` without braces when the body is a single statement:
  ```csharp
  if (condition) DoThing();
  ```
- Inline simple expressions instead of unnecessary intermediate variables:
  ```csharp
  // prefer
  Process(a + b);
  // over
  var sum = a + b;
  Process(sum);
  ```
- Extract variables when: a deeply nested value is reused (`msg.conversation.user.email`), or nesting gets noisy enough to hurt scanning.
- A few levels of nested function calls are fine. Avoid extreme chains like `f(g(h(x).Map(r => a(b(c(r))))))`.

### Naming

- Abbreviated variable names are fine (`ctx`, `cfg`, `msg`, `evt`, `idx`, `pos`, `vel`).
- Be more descriptive only when ambiguity exists — similar locals, similar globals, or domain terms that would be confusing abbreviated.
- Types, public APIs, and method names should still be clear and descriptive.

### Functional & Structural

- Use functional elements freely: `map`, `reduce`, `Select`/`Where`/`Aggregate`, pattern matching, tuples, deconstruction.
- But don't force functional style when a loop or `if` is simpler and more readable.
- Avoid deep nesting of code blocks — prefer early returns, guard clauses, and flat control flow.
- Favor composition over inheritance.

## Error Handling

- Prefer explicit error handling — return types that encode failure (Result patterns, nullable returns with clear semantics) over silent defaults.
- Use exceptions for truly exceptional cases, not control flow.
- Don't swallow errors. If catching, at minimum log with context.

## Dependencies & Architecture

- Before adding a dependency, tell me what it does and what the alternative without it looks like.
- Prefer small, focused libraries over large frameworks.
- Keep modules loosely coupled with clear boundaries. If something can be a standalone utility, make it one.

## Testing

- **When planning or writing a substantial feature:** ask me how I want to handle tests. Present these options:
  1. Basic smoke tests — just verify the feature works end-to-end (my default).
  2. Detailed unit tests — cover edge cases and internal behavior.
  3. TDD approach — write tests first, then implement.
- For small changes, fixes, or utilities, don't write tests unless I ask.
- Suggest TDD when we're planning multiple features on a bigger project or starting a new project from scratch.

## Git

- Write commit messages in imperative mood, concise subject line.
- Prefer small, focused commits over monolithic ones.

## Agents

- Before commits, run the review agent matching the stack: `csharp-reviewer`, `react-reviewer`, `vulkan-reviewer` (GPU/graphics code), or `python-reviewer`.
- Use the generic `reviewer` only for mixed or other-language code with no dedicated reviewer.

## Language-Specific Notes

### C#

- Target latest stable C# features (top-level statements, file-scoped namespaces, primary constructors, `field` keyword where supported).
- Prefer `Span<T>`, `stackalloc`, value types, and ref structs for performance-sensitive paths.
- Use pattern matching and switch expressions over if-else chains when it improves clarity.
- Collections: prefer `ReadOnlySpan`, arrays, or `ImmutableArray` over `List<T>` when mutation isn't needed.
- Familiar with and prefer: Arch ECS, LeoECSLite, Silk.NET, CommunityToolkit.Mvvm source generators.
- Avoid reflection at runtime when source generators or compile-time solutions exist.

### Python

- Type hints on all function signatures. Use `typing` / modern union syntax (`X | None`).
- Prefer dataclasses or Pydantic models over raw dicts for structured data.
- Use list/dict comprehensions and generator expressions freely.
- Virtual environments assumed — don't suggest `--break-system-packages` or global installs.

## Documentation

- **Project docs are welcome** — README.md, docs/ folder with features, usage instructions, API specs, diagrams.
- **Inline comments during active development: no** — don't add docstrings, XML comments, or explanatory comments while writing code. They create churn and can be generated after the code is stable.
- **Comments for non-obvious logic: yes** — if something is genuinely tricky or has a gotcha, a brief comment is fine.

## Things to Avoid

- Don't wrap simple code in try-catch "just in case."
- Don't refactor code I didn't ask you to touch unless it's directly broken by the change.
- Don't suggest design patterns by name as if the pattern itself is the justification ("we should use the Strategy pattern here"). Instead, describe the actual structure and why it fits.
- Don't create abstractions preemptively — wait until there's a concrete second use case.
- Don't pad output with summaries of what you just did. If I can see the code, I can read it.
