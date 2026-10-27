# Balanced mitosis hold and readable popup landing — 2026-10-26

User requested a short stationary pause after Balanced mitosis, followed by its merge, and visible downward settling after score/multiplier peaks; all music-aligned. Read current state/queue/design, branch/HEAD, status, source and relevant diff. Dirty shared `main` at `087df09d653858b72c6e2dc344352237433dd3ac`; preserved existing edits and `.codex-godot-temp`.

## Changes

`patch-notes/scripts/ui/card_score_floats.gd`: Balanced spreads its sum/multiplier over popup subdivisions0.5–1, holds their complete pose1–1.5 (half a card subdivision, about0.214s), then accelerates inward1.5–2. Merge/result boundary2, subsequent split, exit and HUD deposit remain unchanged. The hold is sampled from music position, with no timer or extra sequence duration.

Score/multiplier launches now peak halfway through the existing half-subdivision rise, leaving a quarter subdivision (about0.107s) to fall10px into place. Ascending and descending legs have zero velocity at the apex; strong launch/deceleration and soft downward acceleration retain the gravity-like feel. Same original start/rest timestamps; card cadence, scoring, exit toss and independent HUD animation unchanged.

`scripts/debug/verify_score_floats.gd` verifies exact stationary poses across the hold, subsequent inward movement, unchanged merge deadline, and real score/multiplier peak→descent→rest at music-grid fractions. `scripts/market/rival_world_checkpoint.gd` admits only the genuine exact preceding presentation source through normal validation. No save fields or RNG changes.

## Checks and evidence

Folder `docs/codex/findings/score-hold-20261026-v1/` retains original bytes, pre-edit paired Studio/world save, scoped patch, source manifest/audit,27 native captures and exact command/result receipts. Runner: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe -X utf8 docs/codex/findings/score-hold-20261026-v1/run.py LABEL SCRIPT [--native] [--out=ABSOLUTE_DIR]`. Godot4.7.1, private profiles/writer ports, Dummy audio; real player saves untouched.

| Label / script | Result |
| --- | --- |
| baseline / prior restore.gd --capture | PASS2; exact source `6b46939ffd7efda8229858ecdbf9790cb9b12444180e7eea0db729ae22f82635` captured before changes |
| red / verify_score_floats | Expected1 failure for the old late/shallow landing |
| red-hold / same, after arc only | Expected6 failures for missing stationary hold across three viewport fixtures |
| green / verify_score_floats | PASS314; hold/merge deadlines, actual popup descent, exact totals, symmetry, short-stage bounds, low FPS, rejoin/cancel, normal/QA/Contract and once-only HUD ordering |
| native-final / same --native | PASS314;1152×648,1280×720 and832×320 short stage; native hold/apex/descent captures inspected |
| sync / verify_soundtrack_sync | PASS3,503; timing, loop wraps, variable sequences, pause/resume and no missed/double steps |
| cold-final / prior restore.gd | PASS10; exact predecessor player/world/RNG, unknown-source rejection, no replacement generation/byte changes |

Final runtime identity `f9854f69fe47880510e5c933b80aefbbc7f6469226328321f8ff55e33bdbe3b4`. Audit matches current resource bytes to Godot's manifest and reconstructs the exact predecessor from preserved originals. Scoped whitespace check recognizes CRLF. Successful receipts have no SCRIPT ERROR/ERROR/FAIL; existing ObjectDB cleanup warnings remain. Updated design/status/queue. No gameplay/rule change, campaign/performance/audible acceptance claim, EXE/ZIP, commit or push.
