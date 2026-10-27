# Merge momentum and final score hop — 2026-10-27

User requested inherited merge velocity during outward mitosis and an upward bounce before score values fall behind cards, like Outta Pocket's score award. Read current state/queue/README, relevant core/studio presentation records and prior reference log; inspected branch/HEAD/status/diff and current source. Shared dirty `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac`; existing edits and `.codex-godot-temp` preserved.

## Motion and scope

- `patch-notes/scripts/ui/card_score_floats.gd`: incoming Back-in contact tangent sampled into pixels/second. First gather has unequal branch speeds, so its symmetric sum/multiplier pair inherits their equal-weight mean speed magnitude, redirected left/right. Each four-way branch inherits the second pair's shared arrival speed magnitude, redirected toward its own card.
- Distance/time-aware Hermite spreading starts with that physical speed and ends at zero speed. For start tangents above3, use integrated decaying velocity instead of an overshooting cubic. This remains monotonic, bounded and independent of frame integration.
- Remove the former2–2.25 result hold: final mitosis starts immediately at contact at subdivision2, arrives at the same subdivision3. First split0.5–1, first spread hold1–1.5, inward merge1.5–2, final hold3–4 and exit/deposit4–5 remain. Exact resolved category values appear on those outgoing branches.
- Score exit:22px quadratic-out upward hop, then accelerating quadratic-in descent to100px below rest, clipped behind the card. Reference source `_animate_score_award` at `C:/Users/64jus/OneDrive/Documents/GitHub/outtapocket/outta-pocket/scripts/game_screen.gd` uses22px ascent over0.16s and a0.26s drop. Preserve that ratio (apex8/21) within the existing60/140s exit; no reference wall-clock duration or new timer adopted. Other project read only.
- Popup entrances, Specialization, card cadence, gameplay resolution, scoring/caps/rounding, HUD deposit, cards' outgoing slide, RNG, finance and Studio-only Continue unchanged.
- `scripts/market/rival_world_checkpoint.gd`: add only the verified exact predecessor identity `4bc1caa6263cc6a965101c5231288465b97d4c1b76c2890d4e507441c58be0e0` to existing presentation compatibility. Full validation and unknown-source rejection retained; no saved-field rewrite.
- `scripts/debug/verify_score_floats.gd`: physical node motion across both contacts, immediate split, inherited-speed tangents for short/long/zero/high-speed routes, monotonic bounds, zero-speed landing, exit hop/clip, plus existing score/layout/clock/cancel/HUD/QA/Contract checks.

## Evidence and exact checks

Finding: `docs/codex/findings/score-momentum-20261027-v1/`. Exact original three source files, plan/rulings, genuine predecessor Studio/world, command/exit/error receipts, captures, source manifests and scoped diff retained. Inline implementation; independent scoped read-only code review completed with no actionable findings. Reviewer confirmed inherited-speed curves/fixed endpoints and unchanged exit/deposit timing; no extra simulations or edits.

Runner: bundled Python `-X utf8 docs/codex/findings/score-momentum-20261027-v1/run.py LABEL SCRIPT [--native] [--out=ABSOLUTE_DIRECTORY]`. Godot4.7.1, Dummy audio, private user profiles/writer ports; player saves untouched.

| Label / script | Result |
| --- | --- |
| baseline / prior pause-transition restore.gd `--capture` | PASS2, genuine preceding Studio/world |
| red / verify_score_floats |45 failures; includes18 test-probe ordering failures from sampling backwards against the intentionally monotonic music cursor; retained |
| red-v2 / same, monotonic exit probes corrected | Expected27 behavioral failures on old motion |
| green / same | PASS360, initial motion implementation |
| green-final / same | PASS385, additional physical-tangent/bounds/arrival-speed checks and final source allowlist |
| native / same `--native --out=.../frames` | PASS385 at1152×648,1280×720,832×320;42 PNGs retained, representative split and short-stage exit frames inspected |
| sync / verify_soundtrack_sync | PASS3,503, varied sequences, loop wraps, pause/rejoin and original music-grid boundaries |
| cold-final / prior restore.gd | PASS10, exact old player/world/RNG and save bytes, unknown-source rejection, no replacement generation |
| identity-final / prior score-floats identity.gd; Python audit.py | PASS; all non-debug resource bytes match manifest and exact predecessor reconstructs from retained originals |

Successful receipts have no SCRIPT ERROR/ERROR/FAIL. Existing6-ObjectDB cleanup warning remains; no engine allocation fix claimed. Final runtime identity `3eb0f864ee07afc000f7ac087b5b1b7c2396d93e89056b53a84900b9e4954560`.

Whitespace: seven scoped files pass a line-ending-aware direct check. Default Git whitespace flags existing CRLF in the preserved codec; rerun with `core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol` passes. No broad line-ending rewrite performed. HEAD unchanged.

Updated core/studio record, CURRENT_STATE and TODO minimally, preserving concurrent work. No commit, push or export; existing EXE/ZIP unchanged. No campaign/performance/audible or human motion-feel acceptance claimed. During the initial few frames of four-way separation, branches intentionally share the merge origin before separating toward their cards.
