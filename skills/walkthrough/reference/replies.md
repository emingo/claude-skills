# Handling replies

For decide and review points. Tour stops and explain-only points follow `tour.md` §3 instead.

Stay on the current point until it has an outcome; restate what was decided in one line before recording it.

| Reply | Do |
|---|---|
| **A pick** (or "approve", "your call") | Record it as decided. |
| **Tell me more** | Go deeper: examples, the real code, a comparison table, a diagram, a worked scenario. If the deeper look changes your recommendation, say so explicitly ("I'm withdrawing B as the recommendation"). Then re-offer the same point's picker. |
| **A question that reshapes the point** ("what are the benefits of X? would it become a chore?") | Answer it under clear headings, propose a structure, and ask one gating question before drafting full text. |
| **Refinement** ("yes, but archive instead of delete") | Restate the refined decision in one line; ask only if it's ambiguous; record. |
| **Own answer** | Sanity-check it against the code, the docs and earlier decisions. If it's sound, record it. If it has a risk, say so once — concretely — and ask; then record whatever the user chooses. |
| **User idea stronger than the recommendation** | Say so plainly ("your version is better than mine — it fixes the cause, not the symptom") and add any guardrails it needs. |
| **User idea riskier than the recommendation** | Name the specific ways it can go wrong, each with a fix; recommend the safeguarded version. Never just reject it. |
| **"Approve, but this got me thinking…" (a new idea)** | Record the approval. Add the idea to the agenda as a new point with the next free ID, handle it now, then rework any later points it affects and say so ("Point 7 is simpler now: …"). Points it fully settles are marked `covered by #N` and not asked again. |
| **Defer** | Undecided point → `/followup` with `Kind: deferred` and a concrete **Revisit when** (a trigger, or a *later* milestone — warn before naming the milestone this point belongs to: a bare milestone id blocks that milestone from landing). A provisional choice to revisit → `Kind: decision`. Outcome `deferred (FU-NNN)`. Origin: `— walkthrough <log slug> #N`. |
| **Accepted recommendation that carries a compromise, or a choice the user may want to revisit** | `/followup` without being asked (`Kind: compromise` with **Why accepted**, or `Kind: decision`). |
| **Future / later** ("let's keep that for later releases") | Outcome `future direction`; queue an edit adding it to the document's future/later section if it has one, else a `Kind: deferred` follow-up. |
| **Hand off** ("that belongs in the technical spec") | Outcome `handed off`; note the target document or owner. Flag it there only if it's yours to edit; otherwise a follow-up or a note in the log. |
| **Scope limit** ("no technical research in this pass") | Honor it for the rest of the walkthrough; record it in the log header. |
| **Conflicts with an earlier decision** | Flag it now; ask which wins with one sub-picker; mark the loser `superseded by #N` in the log, and in the decisions section add a dated note and update the folded `**Decision:**` under the question — never delete the old entry. |
| **Side requirement** ("make sure the docs are aligned on this") | Record it as an action item in the log; it joins the queued edits. |
| **Process change** ("put the other repo's changes in a requests doc instead") | Confirm the new handling in one line, apply it to this and later points, note it in the log header. |
| **Navigation** (`back to 2`, `skip`, `accept the rest`, `pause`, …) | As SKILL.md's navigation list; going back reopens that point's outcome (a changed decision updates the folded `**Decision:**` and adds a dated note in the decisions section) and marks anything that depended on it for re-check. |
| **No answer / unclear** | Don't guess on a judgment call — ask again briefly. For a clear-cut point the user skipped in a batch, propose the recommendation as the default and say so. |
