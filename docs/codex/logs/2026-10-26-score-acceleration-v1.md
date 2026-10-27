# Floating score acceleration — 2026-10-26

User requested replacing ease-out with ease-in, strongest acceleration in the third quarter, including Balanced splits/merges and the falling exit. Applied to the floating-score sequence (appearances, splits, merges, fall); existing card movement, popup and independent HUD punch retain their own animations. This scope was stated during implementation. Read current state/queue, Core/Studio design, branch/HEAD, source and relevant diff. Shared dirty `main` at `087df09d653858b72c6e2dc344352237433dd3ac`; preserved unrelated edits and `.codex-godot-temp`.

## Changes

- `patch-notes/scripts/ui/card_score_floats.gd`: one clamped, continuous-position/velocity ease-in profile. Gentle quadratic start0–50%; stronger acceleration50–75%; retain the resulting speed75–100% to meet the original beat. At50% it has traveled1/12 of the distance; at75%,5/12; at100%, all of it. No ease-out function remains in this component.
- Balanced gathering, sum/multiplier mitosis, inward merge and four-way split all use this curve. Specialization's horizontal shift and merge do too. Initial value/multiplier rises retain a small bounce using two accelerating legs instead of the former ease-out/back curve. The upward exit bounce remains; falling starts gently and uses the same accelerating profile.
- `scripts/debug/verify_score_floats.gd`: sampled acceleration, outward slow starts, falling motion, exact endpoints and existing music/score/cleanup checks.
- `scripts/market/rival_world_checkpoint.gd`: admit exact captured predecessor `c3e80e9a7118d84803ef047dbf11e641030b3c6ebfcaeabc12dc6344f12d4c78` through the existing full validation. No fields/RNG changed.

Durations, popup/merge/split/hold/sink boundaries, base140/minute cadence, hidden→HUD→slide ordering and authoritative scores are unchanged. This supersedes the previous cubic ease-out on mitosis and ordinary quadratic merge easing.

## Checks and source pins

Evidence/helpers: `docs/codex/findings/score-acceleration-20261026-v1/`; original bytes, genuine preceding Studio/world payload, exact command receipts, scoped patch, source manifest, native captures and audit. Runner: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe -X utf8 docs/codex/findings/score-acceleration-20261026-v1/run.py LABEL SCRIPT [--native] [--out=ABSOLUTE_DIR]`. Godot4.7.1, isolated profiles/ports, Dummy audio; player saves untouched.

| Label / script | Result |
| --- | --- |
| baseline / prior restore.gd --capture | PASS2; exact preceding source captured before runtime edits |
| red / verify_score_floats | Expected1 failure: third-quarter acceleration absent; verifier stops before scenarios on this failed prerequisite |
| green / verify_score_floats | PASS284: profile, Balanced and Specialization travel, falling start/acceleration, normal/QA/Contract scores, exact endpoints, once-only HUD, low FPS, pause/rejoin/cancel |
| native / same --native | PASS284 at1152×648,1280×720 and832×320 short-stage fixture; nine captures |
| sync / verify_soundtrack_sync | PASS3,503; original grid/durations, varied sequences, repeated loop wraps and pause/rejoin |
| cold / prior restore.gd | PASS10; exact preceding player/world/RNG, unknown-source rejection, unchanged generation bytes |

Final source `797d2689941140d51cb8637fd2d03efa1f2011a6794a3803b65af68ac6213d4c`. Audit reconstructs the exact preceding identity from preserved originals and agrees with Godot's final manifest. Successful receipts contain no SCRIPT ERROR/ERROR/FAIL; existing ObjectDB cleanup warnings remain. No broad campaign/performance/audible acceptance claim. No gameplay changes, new EXE/ZIP, commit or push. Design/status/queue updated; previous evidence retained.
