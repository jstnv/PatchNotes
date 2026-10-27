# Score merge/split easing — 2026-10-26

User refinement: ease into merges, ease outward on mitosis. Inspected current state/queue, Core/Studio design, source/diff and dirty `main` at `087df09d653858b72c6e2dc344352237433dd3ac`. Preserved shared edits and `.codex-godot-temp`.

`patch-notes/scripts/ui/card_score_floats.gd` now uses quadratic ease-in for Balanced gathering and both inward pair merges; cubic ease-out for Balanced sum/multiplier separation and the four-way split. Accelerate toward contact, separate quickly then settle without overshooting card anchors. Original bounce, shake, durations, music timestamps, deposits and scoring unchanged.

Extended the existing `verify_score_floats.gd` with sampled travel checks. Its old linear-midpoint expectation now verifies that less than half the inward movement occurs in the first half of a merge. The exact preceding source was captured in a genuine isolated Studio/world save before runtime edits; `rival_world_checkpoint.gd` admits only that additional known presentation predecessor through ordinary validation. No saved fields or RNG changes.

Evidence: `docs/codex/findings/score-easing-20261026-v1/`; byte originals, scoped patch, exact commands/logs/receipts, source manifest and audit. Runner command: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe -X utf8 docs/codex/findings/score-easing-20261026-v1/run.py LABEL SCRIPT [--native] [--out=ABSOLUTE_DIR]`. Private profiles/ports, Godot4.7.1, Dummy audio; player saves untouched.

| Label | Result |
| --- | --- |
| baseline / existing restore.gd --capture | PASS2; exact source `02e62ac6d53d7b50c642ffb2a6e70fd64afcf01eec07dee4c919d4394773c3cc` |
| red / verify_score_floats | Expected15 failures:12 inward-merge and3 split-overshoot checks. Corrected the gathering sample to occur before the later pair sample, avoiding a backward clock jump. |
| green / verify_score_floats | PASS261: easing, exact endpoints/totals, narrow stage, normal/Specialization/Balanced, low FPS, rejoin/cancel, Contract/QA and HUD timing |
| native / same --native | PASS261; nine captures at the two window sizes and short-stage fixture |
| sync / verify_soundtrack_sync | PASS3,503; original timing/grid/loops/variable sequence checks |
| cold / existing restore.gd | PASS10; exact preceding player/world/RNG, unchanged generation bytes, unknown-source rejection |

Final source `c3e80e9a7118d84803ef047dbf11e641030b3c6ebfcaeabc12dc6344f12d4c78`; audit reconstructs the preceding identity from original bytes. Successful receipts have no SCRIPT ERROR/ERROR/FAIL; existing ObjectDB cleanup warning remains. Scoped Git whitespace check recognizes CRLF. Updated design and execution records. No new whole-campaign/performance/audible acceptance claim, EXE/ZIP, commit or push.
