# Pass Budget implementation session — 2026-10-31

Branch `main`, observed HEAD `3a61522f18db7a2bae892cb8c5be1fee68cd4100`. The worktree had extensive inherited edits; another Studio/Contract implementation was active concurrently. No commit, push, export, or release claim. Existing `.codex-godot-temp` was preserved and used for redirected Godot AppData and test output.

## Implemented locally

- Added phase-local Design and Alpha `2 + floor(printed Feature Core / 8) - played Passes` accounting. Primary, secondary, and ordered third printed contributions count once. Passes and synergy output add no budget; successful hands commit spending. The separate phase objects reset at phase start.
- Weighted deals and refills cap Pass instances after retained reservations, allow fewer than seven candidates, and permit empty exhausted pools. Redraw releases each replaced Pass reservation before sampling and excludes the immediately replaced definition. Corrective Alpha injections share the same allowance. Alpha validation and finalization accept short pools.
- Pass cards show the shared remaining budget in the former renewability slot and show `n/8` progress in their tooltip. Beta card handling is untouched.
- Added `verify_pass_budget.gd` and an empty-pool Alpha finalization case.

Changed runtime files: `scripts/simulation/pass_budget.gd`, `design_hand_command.gd`, `alpha_hand_command.gd`, `development_actions.gd`, `scripts/phases/design_phase.gd`, `alpha_phase.gd`, `scripts/first_game_tutorial.gd`, and `scripts/cards/card_view.gd`. Changed verifiers: `scripts/debug/verify_pass_budget.gd`, `verify_alpha_finalization.gd`.

## Checks and limits

Godot available here was **4.7.1**, while the task targets 4.4. The executable initially crashed because sandboxed AppData was unwritable. Setting `APPDATA` and `LOCALAPPDATA` to `.codex-godot-temp/AppData/...` resolved startup. All listed checks used `--headless --path patch-notes --script res://scripts/debug/<name>.gd` with stdout/stderr retained in `.codex-godot-temp/*pb*` or `*pass-budget*` files.

| Check | Result |
|---|---|
| `verify_pass_budget.gd` | PASS, 0 failures: formula, cumulative rounding, printed Feature hand, four-Pass spending, duplicate renewable definitions, retained Pass/redraw reservation, same-definition redraw exclusion, partial/empty draws, phase reset, empty Alpha pool, Pass UI. |
| `verify_alpha_finalization.gd` | PASS, including new zero-candidate Proceed to Beta case. |
| `verify_score_floats.gd` | PASS, 385 checks. |
| `verify_production_extraction.gd` | PASS, 80 cases. |
| `verify_card_frame.gd` | PASS, 2,246 checks. |
| Godot editor import/parse | PASS, exit 0, no parse/script errors after redirected AppData. |
| `verify_design_command.gd`, `verify_alpha_command.gd` | FAIL: old unrestricted early four-Pass acceptance, fixed refill counts, corrective deal, and pinned oracle traces. |
| `verify_design_phase.gd`, `verify_alpha_phase.gd`, `verify_candidate_retention.gd` | FAIL: many fixed seven/four replacement and unrestricted Pass expectations; priority-bound assertions also fail in the concurrently edited source. Candidate retention reports 234 failures. |
| `verify_production_alignment.gd` | FAIL 2/3 checks: old seven-card alignment fixtures exceed the new initial Pass reservation. |
| `verify_beta_command.gd` | FAIL two pinned Beta oracle trace comparisons; Beta files already had inherited edits, so this run does not isolate their cause. |

The older verifiers need budget-aware fixtures and renewed reference traces before a clean maintained-suite claim. Native visual inspection, Godot 4.4 verification, complete saved/Continue careers, and paired normal-start balance remain **NOT RUN / OPEN**. No review formula, printed card value, Scope requirement, or Engine Skill Tree code was changed by this session.
