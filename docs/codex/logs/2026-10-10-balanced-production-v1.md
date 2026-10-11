# Balanced Production redistribution — 2026-10-10

## Authority and source

User requested hand-local even distribution with15% wiggle room, then equal redistribution after the cards play. Explicit follow-up approved inclusive ±15% of the four-category hand mean, whole points (21→6/5/5/5), and replacing ×1.20 with redistribution of the original total. Fixed remainder order is Graphics, Sound, Technology, Design. Shared dirty main at `41c87c76fb4d3c06a5332d93f0e7b0997007475d`; existing edits, saves and `.codex-godot-temp` preserved. No commit/push.

## Files and behavior

- `scripts/cards/balanced_production.gd`: shared integer-boundary qualification and whole-point total-preserving redistribution. Zero total does not qualify.
- `scripts/phases/design_phase.gd`, `alpha_phase.gd`: evaluate hand contributions including secondary scores, independent of historical project totals. Use shared redistribution. Existing Feature requirement and Specialization precedence retained. Scope, printed Bug Pressure, costs, action count and lifecycle unchanged.
- `scripts/ui/hand_presentation.gd`, `phase_workspace.gd`: identify Balanced presentation, show printed gains first, popup after four cards, signed redistribution one music subdivision later, hold one subdivision and exit. No second bounce wave. Only the already-committed final scores are authoritative; no extra gameplay action.
- `scripts/ui/gameplay_hud.gd`, `tutorial_overlay.gd`: replace cumulative20%/×1.20 guidance with current hand15%/equal-split guidance.
- `scripts/debug/verify_design_phase.gd`, `verify_alpha_phase.gd`, `verify_soundtrack_sync.gd`: update old-rule expectations and add remainder conservation, boundary, historical-score independence, precedence and ordered signed-transfer coverage.
- `docs/codex/design/core-and-studio.md`, TODO, CURRENT_STATE: approved rule and implementation status; earlier exported evidence remains pinned to older source.

## Verification

Run with bundled Python: `docs/codex/findings/card-presentation-v2/run.py <label> <script>`. Isolated profiles, full binary commands, source hashes and outputs are in each labeled findings directory.

| Label | Script | Result |
|---|---|---|
| balanced-design-v2 | verify_design_phase.gd | PASS, exit0/no errors |
| balanced-alpha-v4 | verify_alpha_phase.gd | PASS, exit0/no errors |
| balanced-sync-v1 | verify_soundtrack_sync.gd | PASS,3,503 checks,0 failures |
| balanced-motion-v1 | verify_card_motion.gd | PASS,71.031 seconds,exit0/no errors |
| balanced-hud-v2 | verify_gameplay_hud_overlay.gd | PASS,exit0/no errors |

Focused `git diff --check` passes. Source unchanged within each test run. Final changes after motion/sync tests were HUD/tutorial text only; the HUD suite reran after those edits. Tests cover exact15% endpoints17/20/20/23, out-of-range rejection, zero total, all four remainder cases,21-point conservation, ordinary/specialized/Feature-plus-Pass handling, atomic commits and exhaustion. Music tests cover printed5/5/5/6 then redistributed6/5/5/5 with unequal historical scores, one action, one signed transfer, no extra wave, stationary clock, loop-boundary crossing,60fps and0.31-second frames; existing audio loop/pause/specialization tests also pass.

Retained initial Alpha test failures: a fixture local-name collision caused parser failure (Godot also emitted a shutdown crash backtrace); corrected fixture then lacked Alpha phase/department metadata and failed validation. Both test-fixture issues were repaired; final Alpha suite passes. No runtime gameplay defect was concealed or assertions removed to force success.

## Limits

No new exported binary, desktop visual inspection or audible playtest. Previous108-suite/export acceptance predates this rule change; this is five focused suites, not a refreshed full release gate. Existing historical balance findings retain their original scoring version. Integer gameplay state/save format unchanged; old released results are not rerated.
