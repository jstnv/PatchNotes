# Stray production hover panels — 2026-10-26

## Request and starting state

User reported random panels at production hover points, with a tutorial QA screenshot showing an empty floating bar. Branch `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac`; index empty. Prior Search-first source/docs/test additions, the local export-preset change, shared untracked files and `.codex-godot-temp` remain preserved.

## Reproduction and cause

The shared `CardFan` had populated its own `tooltip_text` during `_gui_input` mouse motion. Godot's tooltip query can precede that callback, so the queried point inherited the preceding card's help. A real engine probe showed the previous PopupPanel still visible after one motion into empty hand space, even though the fan's cached text had become empty. The custom factory also accepted empty text and created a fixed-width blank label/panel.

`verify_card_hover_tooltips.gd` reproduced four failures before the change: positional help before motion, blank-panel guard, empty-space query after card hover, and closing the old popup on the first motion into empty space. Nine checks total, exit 1. The original diagnostic source/transcript is retained with the findings.

## Changes

- `patch-notes/scripts/ui/card_fan.gd`: implement `_get_tooltip(at_position)` against the existing transformed/z-ordered card hit test; remove the mouse-motion text cache. Hidden/not-ready card views are excluded. Empty or whitespace-only text returns no custom tooltip object.
- `patch-notes/scripts/debug/verify_card_hover_tooltips.gd`: regression checks use actual engine mouse motion and PopupPanel inspection, plus optional native captures.
- `docs/codex/design/core-and-studio.md`, `docs/codex/TODO.md`: record the adopted hover behavior and completed repair.

Candidate slots, Search-first selection/playback, resolver/RNG/cycle rules and legitimate card descriptions are unchanged. Debug-only scripts are excluded from the release runtime as before.

## Exact checks and results

Executable: `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe` (`4.7.1.stable.official.a13da4feb`). From repository root, each process uses separate `APPDATA`/`LOCALAPPDATA` under `.codex-godot-temp/hover*-20261026/`. Tutorial uses `PN_CHECKPOINT_TEST_PORT=47751`; real player profiles are untouched.

```
<godot> --headless --path patch-notes --script res://scripts/debug/verify_card_hover_tooltips.gd
<godot> --path patch-notes --position 60,60 --resolution 1152x648 --script res://scripts/debug/verify_card_hover_tooltips.gd -- --out=<absolute findings folder>
<godot> --headless --path patch-notes --script res://scripts/debug/verify_guided_tutorial_ui.gd
<godot> --headless --path patch-notes --script res://scripts/debug/verify_search_first.gd
```

- PASS: focused headless **9/9**, exit 0. Real tooltip opens over a card, contains multiline text, closes on first motion into empty space; position queries exclude stale/hidden hotspots and blank factory output.
- PASS: focused native **9/9**, exit 0, OpenGL/NVIDIA. Captures `card-help.png` and `empty-space.png` inspected at1152×648: readable help at the card, no floating panel over empty space.
- PASS: complete guided tutorial UI **115/115**, exit 0. Real pointer/keyboard selection, all lessons, input gates, music-driven presentation, layout at1152/1280/1906 widths, exit/replay/Continue, exact real Studio/world/RNG/checkpoint preservation.
- PASS: Search-first regression **9/9**, exit 0; previous selected-row/playback preference retained.
- Retained diagnostics: tutorial fixture emits missing temporary artwork warnings for `4_color_palette`/`sprites` and six ObjectDB cleanup warnings. Search-first fixture retains its previously recorded11 ObjectDB/one resource cleanup diagnostics. Focused final hover runs have no such diagnostics. No clean-teardown claim for the broader fixtures.

[Raw logs, captures and source hashes](../findings/card-hover-20261026-v1/result.json).

## Limits

Existing exported EXE/ZIP packages remain unchanged. No whole-release, all-hover-target, human playtest, commit/push or Drive synchronization claim. This closes the reproduced shared card-fan defect; unrelated persistent Tip behavior and other menu/tooltips are unchanged.
