# Floating scores and synergy choreography — 2026-10-26

Direct user implementation request. Read current state, queue, relevant design/source and diff before editing. Dirty shared `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac`; preserved unrelated work and `.codex-godot-temp`. No commit, push or player export.

## Behavior and interpretation

Values bounce out from each played card's top border, centered; multi-Core cards show combined Core. Scope and category-specific totals remain exact in the HUD. Text persists until the numeric exit. Interpreted the request's conflicting exit wording as **numbers sink out of view → HUD deposits → played cards slide away**. Gameplay commits once before visual playback, as before; presentation cannot resolve cards or advance the calendar.

Keep the base 140-card/minute cadence and corrected continuous soundtrack clock. Relative to synergy popup, in units of 60/140 seconds:

| Subdivisions | Specialization | Balanced Production |
| --- | --- | --- |
| 0–1 | Original shifts left; all right-hand ×1.5 labels bounce up together | Gather card values during 0–0.5; split sum/×1.25 during 0.5–1 |
| 1–2 | Both texts merge inward | Sum and multiplier merge inward |
| 2–3 | Shake to exact resolved per-card output | Show exact boosted sum, then split four category totals toward the four cards |
| 3–4 | Hold | Hold |
| 4–5 | Small upward bounce, then sink behind card border | Same exit |
| 5 | Explicitly hide tokens, publish confirmed HUD values, start outgoing card slide | Same handoff |

Ordinary hands hold through base activations and use a one-subdivision numeric exit. Redraw unchanged. This replaces the sequential bonus **visual** wave and ordinary victory bounce; it does not remove any gameplay trigger. HUD updates use an independent short scale/tint/rotation elastic settle. Existing replenishment/sort entrances retain their prior scene tweens; new numeric motion and outgoing played-card slide use the music reference. Pause/rejoin shifts their timestamps by the shared subdivision count.

Numbers use actual already-resolved totals, including hand rounding, QA caps/zero effects and Contract half-point storage. Contract metadata converts storage units to displayed points without changing contract arithmetic. A short-stage score lane shrinks/lowers the centered cards where needed so tutorial scores stay clear of the popup and clipping boundary. Source-bound compatibility admits only the captured exact predecessor through ordinary full validation; state fields and Studio-only Continue remain unchanged.

## Files changed in this pass

- New `patch-notes/scripts/ui/card_score_floats.gd`: bounded clipped text tokens and Balanced hub, sampled by music time; no timers, RNG or gameplay effects.
- `scripts/ui/hand_presentation.gd`: confirmed-state capture, numeric schedule, once-only delayed deposit, trace events, resume/cleanup and score lane.
- `scripts/ui/production_scoreboard.gd`, `gameplay_hud.gd`, `guided_production_tutorial.gd`: shared HUD punch and held scores/pressure.
- `scripts/ui/phase_workspace.gd`, `scripts/phases/contract_phase.gd`: captured multiplier metadata, Contract popup and point formatting/punch.
- `scripts/market/rival_world_checkpoint.gd`: exact predecessor source only.
- New `scripts/debug/verify_score_floats.gd`; refreshed `verify_soundtrack_sync.gd`, `verify_card_motion.gd`, `verify_gameplay_hud_overlay.gd` expectations. HUD fixture now recognizes the existing 75 ceiling and two-category Insider hold.
- Core/Studio design, DECISIONS, CURRENT_STATE, TODO, implementation plan and this log; evidence/helpers in the finding folder. Listed `scripts/` paths are under `patch-notes/`.

## Verification

Evidence: [score-floats-20261026-v1](../findings/score-floats-20261026-v1/). Every runner receipt records exact arguments, elapsed time, exit and diagnostics. Command template: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe -X utf8 docs/codex/findings/score-floats-20261026-v1/run.py LABEL res://scripts/debug/SCRIPT.gd [--native] [--out=ABSOLUTE_DIR]`. Private profiles/writer ports; Godot4.7.1, Dummy audio. No player saves touched.

| Receipt label | Actual result |
| --- | --- |
| native-final / verify_score_floats | PASS255. Normal, Specialization, Balanced;1152×648,1280×720 and an832×320 short stage. Symmetry, inward merge, exact totals, once-only hidden→deposit→slide,0.31s frames, pause/rejoin, cancel, QA caps, Contract half-units, held pressure and HUD replacement/settle. Nine native captures. |
| sync-final / verify_soundtrack_sync | PASS3,503. Variable hand lengths, music grid, repeated loop wraps, pause/resume, low-frame stepping and no duplicate/missed steps. |
| motion-final / verify_card_motion | PASS full live Design/Alpha/Beta, both supported sizes, native command bindings/pointer routes, paid hands, redraw, cancellation, Contract half-units/completion and retained pools. Headless renderer with actual scene flow. |
| tutorial-final / verify_guided_tutorial_ui --native | PASS115. Full guided practice, both supported sizes, real pointer/keyboard routes, score/header/instruction layout, cancellation and exact Studio/save/RNG preservation. Twenty native captures, representative score/popup images inspected. |
| cold-final / prior pause-transition restore.gd | PASS10. Exact pre-edit player/world/RNG, unknown-source rejection and no replacement generation or byte changes. |
| design, alpha | PASS maintained phase/rule/lifecycle suites. |
| qa, marketing | PASS maintained Beta specialization/caps/rollback suites. |
| contract-model, contract-ui | PASS Balanced Primitive mechanics and Contract presentation/keyboard/completion checks. |
| card-pop | PASS28 retained charge/pop/spark checks. |
| checkpoint / verify_pause_music | PASS721 transport/reverb/rejoin checks. |
| hud-current / verify_gameplay_hud_overlay | PASS refreshed HUD/planning fixture; no runtime priority-policy change. |

Retained diagnostics: initial red2 failures; missing explicit hide at the exact handoff6 failures; native-signal name collision parse failure; Contract half-unit red1 failure; pre-refresh timing fixture117 obsolete expectations; native short-peak wall-clock sample1 failure (test now samples the exact tween peak). Original HUD fixture19 failures used the old50 ceiling, visible Insider column and unavailable Balanced Operations; refreshed only those inherited expectations. Earlier native tutorial captures exposed clipped floats in the shorter stage despite passing old card-only layout assertions; fixed the stage allocation and added short-stage score bounds. All receipts remain. Standard six-ObjectDB cleanup/missing fixture-artwork warnings remain; successful receipts contain no SCRIPT ERROR/ERROR/FAIL.

Audit reconstructs the exact pre-edit runtime identity `8593779f9afa7deab4ca218fab64118864efe5d763ff088485f8d6ad43be7ab8` from preserved original bytes; final Godot/Python manifest identity agrees at `02e62ac6d53d7b50c642ffb2a6e70fd64afcf01eec07dee4c919d4394773c3cc`. [audit.json](../findings/score-floats-20261026-v1/audit.json) pins all twelve runtime/test paths; [scoped.patch](../findings/score-floats-20261026-v1/scoped.patch) isolates this pass from earlier dirty edits. Fourteen selected passing receipts; scoped `git -c core.whitespace=cr-at-eol diff --check` passes with existing CRLF preserved. Initial audit helper ordering was corrected to sort full resource strings, matching Godot; plain Git whitespace checking treated CRLF as trailing whitespace, so the final check explicitly recognizes CR at end of line.

## Limits / follow-up

No changed gameplay rules, balance, RNG, scoring schema, music assets or transport. No whole-campaign/performance claim, export, commit or push. Existing EXE/ZIP do not contain these changes. Native captures verify rendering; Dummy audio is not an audible music-feel playtest. Human judgment of bounce/merge pacing remains to be heard/played. No unresolved text-fit case was observed in the tested fixtures; extreme future values and new card layouts need their own coverage. Design-gated queue work remains separate.
