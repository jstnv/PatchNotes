# 2026-10-09 AI Competitors design session v15

**Scope:** documentation-only G2–G4 design work. No gameplay, UI, balance, test harness, PR, implementation-thread message, commit or push was performed in this session.

## Source and checkout

- Read `docs/codex/CURRENT_STATE.md` and `TODO.md` first, then relevant AI thread records, Store and Genre source. Intake and later check: branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. The shared worktree contains many pre-existing concurrent edits, including gameplay; preserved all unrelated files and `.codex-godot-temp`.
- Inspected creation-time project Feature supply (`project_state.gd:64-81`, `card_database.gd:278-288`), Design/Alpha candidate and Core-production paths (`design_phase.gd:421-470,606`; `alpha_phase.gd:645-677,853`), Review Genre profile (`primitive_review_calculator.gd:39-84`), and Store quote/admission/Research paths (`run_state.gd:525-590`). This was read-only source review, not resolver parity testing.
- The October 9 Drive log was not reread. PR #1 remains unmerged current-main design material.

## Decisions and changed documents

- Recorded [Studio-boundary new admission](2026-10-09-shopping-trigger-decision-v1.md) and resolved its [A/B brief](2026-10-09-shopping-trigger-options-v1.md). Existing FIFO Research remains legal; no active-project new-admission replan is selected.
- The user selected [conditional-completion-quote-plus-known-dues AI liquidity](2026-10-09-admission-liquidity-decision-v1.md), [Genre-independent G2 Core shopping](2026-10-09-g2-genre-planning-decision-v1.md) after the [source audit](2026-10-09-g2-genre-source-audit-v1.md), [finite G4 project plan with legal exit](2026-10-09-finite-project-policy-decision-v1.md), and [specialty as each rival's first playable project Genre](2026-10-09-first-project-genre-decision-v1.md). Alternatives remain in the corresponding briefs. F3's earlier planned-Genre input is explicitly revised; actual Review still uses project Genre.
- Updated this thread's `README.md`, `working-notes.md`, `HANDOFF.md`, delegated Feature and finite-policy briefs, remaining-systems review and staged implementation brief. Reconciled cross-system `docs/codex/DECISIONS.md`, `CURRENT_STATE.md`, `TODO.md` item 22 and `design/feature-store-progression.md`. No OPEN number was converted into a gameplay default.

## Checks, limits and next work

- Local Markdown link check over 63 AI/shared documentation files: 741 local links, 0 missing. Trailing-whitespace scan: no hits. `git diff --check` for the four touched tracked shared docs returned exit 0, with only Git LF-to-CRLF notices for TODO and Store design. The first attempted Python link check did not run because `python` is unavailable; a PowerShell checker completed instead. No game tests were run because this session changed only design documents.
- G1a exact incumbent cohort/resources/legal opening route remains **OPEN**. G2 finite planned hand/cash values, feasible-vector search and measured budget remain **OPEN**. G3 exact known-due snapshot, future eras and prerequisite dead-end evidence remain **OPEN**. G4 exact legal action/redraw/exit ranking and allowances, Theme, later Genre, traits and entrants remain **OPEN**. G5 alert threshold, Beta intel/save migration and measured CPU/memory/save limits remain **OPEN**. Market effects on Reviews remain separate.
- Next small design decision: select the G4 first-slice Theme policy or the G2 planned-hand envelope method after source-backed evidence. Do not infer a numeric hand count from this session.
