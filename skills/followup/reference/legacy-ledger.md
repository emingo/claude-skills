# Legacy single-file ledger

For projects that keep every entry in one `docs/follow-ups.md` (or a declared path) and haven't migrated. Prefer migrating (`scripts/fu-migrate.ps1`); until then, entries follow this format.

1. If the ledger file doesn't exist yet, don't create one in this format — new ledgers are per-file (`docs/fu/`).
2. Read the ledger's Index. If the note re-defers or adds evidence to an **existing** entry, don't create a new one: append `- **Update (YYYY-MM-DD, <source>):** …` to it (for a re-deferral: `Revisit when → <new> — <why>`, and set Status `open (re-deferred)`), then stop. Otherwise the next id is the highest `FU-NNN` plus one.
3. Append under `## Entries`, matching the heading style the ledger uses; with explicit anchors:

   ```markdown
   <a id="fu-001"></a>
   ### FU-001: <Title>
   ```

   Then the bullets `- **Status:** open`, `- **Kind:**`, `- **Origin:**`, `- **Areas:**`, `- **Impacts:**`, `- **What:**`, `- **Why accepted:**` (compromise/limitation), `- **Revisit when:**` (deferred) — same meanings as the per-file front matter in `SKILL.md`. Keep any extra fields the ledger already uses.
4. Add the matching row to the Index table in its existing column layout — with explicit anchors `| [FU-001](#fu-001) | <Title> | decision | open | <Areas> |`. Other docs link `../follow-ups.md#fu-001` from `docs/milestones/`; without explicit anchors the anchor is GitHub's slug of the full heading.
