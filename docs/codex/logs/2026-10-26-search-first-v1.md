# Search first in selected hands — 2026-10-26

## Request and source boundary

User requested Search for Bugs automatically first in the selected hand, referring to Alpha. Current `card_ledger.json` and `BetaHandCommand` place this QA card in Beta; Alpha permits only Features and Passes. Apply the presentation preference wherever the existing Search card appears, including practice, without moving QA into Alpha or changing resolution rules.

Branch `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac`. Before edits, only tracked worktree modification was `patch-notes/export_presets.cfg`; index empty. Preserve that preset, shared untracked work and `.codex-godot-temp`.

## Changes

- `patch-notes/scripts/ui/card_fan.gd`: stable Search-first partition for the upper selected row only. Underlying visual organization, lower pool and logical candidate slots stay intact.
- `patch-notes/scripts/ui/hand_presentation.gd`: use the same ordering for selected ghosts and their corresponding scoring timeline. The authoritative action is still invoked once; timing remains on the existing music grid.
- `patch-notes/scripts/debug/verify_search_first.gd`: duplicate Search instances selected after Debug/Marketing, stable group order, candidate identity, one authoritative action, four scoring callbacks, exact displayed totals and deselection behavior.
- `docs/codex/design/core-and-studio.md`, `docs/codex/TODO.md`: adopted presentation preference and completed work state.

## Checks

Godot `4.7.1.stable.official.a13da4feb`, executable:
`C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`

For each check, run from repository root with distinct private `APPDATA`/`LOCALAPPDATA` under `.codex-godot-temp/search-first*-20261026/`, then:

```
<godot> --headless --path patch-notes --script res://scripts/debug/verify_search_first.gd
<godot> --headless --path patch-notes --script res://scripts/debug/verify_soundtrack_sync.gd
<godot> --headless --path patch-notes --script res://scripts/debug/verify_beta_base_hand_resolution.gd
```

- RED: focused verifier before production changes exited 1 with exactly two expected failures: upper-row order and playback order. Seven other checks passed. An earlier harness draft incorrectly waited for the real-clock return-fan tween while advancing only the injected music clock; corrected before accepting the red receipt.
- GREEN: focused verifier exited 0, **9 checks, 0 failures**.
- PASS: soundtrack synchronization exited 0, **3,503 checks, 0 failures**; ordinary/specialization/balanced sequences, low-rate stepping and audio-grid behavior retained.
- PASS: maintained Beta base-hand suite exited 0 with `Beta base hand resolution verification passed.` Includes Search before Debug, specialization, retained pool and atomic rejection checks. Expected invalid-hand warnings retained.
- Cleanup diagnostics retained: focused fixture reports 11 ObjectDB instances/one resource at exit; maintained Beta reports six ObjectDB instances. These are not counted as clean teardown evidence.

Raw transcripts and SHA256 source pin are in `docs/codex/findings/search-first-20261026-v1/`.

## Limits

No separate native or human playtest, new EXE/ZIP, commit/push or whole-release claim in this pass. Existing downloaded packages are unchanged. No gameplay, QA availability, scoring, cycle, RNG, save-schema or alpha-policy change.
