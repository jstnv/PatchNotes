# Gravity-like score motion — 2026-10-26

User requested a bouncier gravitational feel: accelerate toward merge points; decelerate away; launch score/multiplier text upward with strong velocity, then fall slightly into place. This supersedes the preceding all-ease-in/third-quarter direction. Scope remains the floating-score sequence. Inspected CURRENT_STATE/TODO, relevant design/source/diff, branch/HEAD and status. Shared dirty `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac`; preserved unrelated edits and `.codex-godot-temp`.

## Implementation

`patch-notes/scripts/ui/card_score_floats.gd` uses complementary sine/cosine spring-like curves for travel around the merge point: move inward from rest and gain speed; launch outward quickly and slow toward rest. Balanced gathering, pair mitosis/merge, four-category split and Specialization separation/merge share this behavior. Horizontal original/multiplier placement stays symmetric throughout separation.

Score/multiplier emergence uses a bounded ballistic arc with constant downward acceleration. The initial upward velocity is strong; apex occurs80% through the existing rise interval, roughly5px above the resting position, followed by a small downward landing into alignment. Exit is one continuous upward toss: apex at25% of the existing exit interval, then accelerate down behind the border. Small captions hide while a multiplier crosses their lane and return when aligned.

Same durations, beat indices, base140/minute cadence, exact score totals and hidden→HUD deposit→card removal order. Card transforms, audio transport and independent HUD punch unchanged. This is analytic sampled presentation, not a new physics simulation or RNG source.

`scripts/debug/verify_score_floats.gd` now checks launch velocity/deceleration/apex/landing, acceleration toward the merge, deceleration away, native multiplier emergence and existing rounding/caps/low-FPS/rejoin/cancel/HUD behavior. `scripts/market/rival_world_checkpoint.gd` admits only the genuine exact preceding source through ordinary full validation; no state/RNG fields changed.

## Evidence

Folder: `docs/codex/findings/score-gravity-20261026-v1/`; before bytes, genuine predecessor payload, scoped diff, source manifest/audit, captures and exact run receipts. Runner: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe -X utf8 docs/codex/findings/score-gravity-20261026-v1/run.py LABEL SCRIPT [--native] [--out=ABSOLUTE_DIR]`. Godot4.7.1, isolated profiles/writer ports, Dummy audio; player saves untouched.

| Label / script | Result |
| --- | --- |
| baseline / prior restore.gd --capture | PASS2; pre-edit source `797d2689941140d51cb8637fd2d03efa1f2011a6794a3803b65af68ac6213d4c` captured |
| red / verify_score_floats | Expected3 failures: slow old launch, wrong upward acceleration and missing separate inward/outward curves; stops before scenario checks |
| green-final-v2 / verify_score_floats | PASS298: numeric trajectories/endpoints, actual multiplier launch/apex/landing, symmetry, native short-stage bounds, normal/Specialization/Balanced/QA/Contract values, low FPS/rejoin/cancel and once-only HUD deposit |
| native-final / same --native | PASS298;1152×648,1280×720 and832×320 short stage;15 captures including launch/apex/rest, representative native frames inspected |
| sync / verify_soundtrack_sync | PASS3,503; original grid/durations, variable sequences, repeated wraps, pause/resume and no duplicate/missed steps |
| cold-final / prior restore.gd | PASS10; exact pre-edit player/world/RNG, unknown-source rejection and no generation/byte changes |

Final runtime identity `6b46939ffd7efda8229858ecdbf9790cb9b12444180e7eea0db729ae22f82635`. Audit matches current resource bytes to Godot's manifest and reconstructs the exact preceding identity with preserved originals. Scoped whitespace check recognizes CRLF. Successful receipts have no SCRIPT ERROR/ERROR/FAIL; existing ObjectDB cleanup warnings remain. One patch had out-of-order context and did not apply; a subsequent automatic permission review timed out without mutation, confirmed by readback; one permitted retry succeeded. No rejection or user approval needed.

Updated Core/Studio and execution/status records. No rule, scoring, save-schema, campaign/performance or audible-acceptance claim. No new EXE/ZIP, commit or push. Human playtest judgment of the new feel remains separate from deterministic trajectory/render checks.
