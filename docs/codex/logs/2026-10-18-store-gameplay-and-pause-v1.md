# Store Gameplay convergence and pause transport — 2026-10-18

Status: Store implementation verified locally; pause transport hardening verified, original audible-stop reproduction OPEN. Direct user request in PN Implementation. Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; pre-existing dirty edits and `.codex-godot-temp` preserved. No commit, push or export performed.

## Scope and source

- Compact Research queue/Research/Debug/Close row; no central Feature Library hub; four neutral paths connect five trees. Four side headers rotated, Technology & Tools remains horizontal. Two grid columns between branch depths, zoom/drag/keyboard navigation retained.
- High Scores → Local Leaderboards; Lives System → Enemies → General Combat; Turn-Based Combat **AND** Scripted AI → Difficulty Levels. Four Gameplay roots remain. Same-tree two-parent arrows converge without intersecting other cards; other cross-tree AND links retain their existing detail links. This reconciles Feature Pools Decision019/Handoff018 and the direct user request.
- Difficulty retains Design2/Scope1, $1,100 base, one research action and existing familiarity mechanics. No other printed scores, prices, card resolution or specialty grants changed. Additional convergence choices remain OPEN.
- `branches3` accepts the exact preceding catalog hash and known historical revisions. Actual old ownership, paid queues and active-world state are tested through fresh-process restore; no automatic parent grants or retroactive charges.
- Esc explicitly restores the always-processing music transport after pause notifications, without seeking or restarting. Pause-effect fades use wall time independently of gameplay time scale. The liked filter/reverb settings are retained.

## Investigation and limits

The original reported music stop did **not** reproduce in a fresh pre-change run: WASAPI captured nonzero filtered audio and an advancing real WAV cursor throughout a72-second Esc pause (293 checks, two loop wraps). No gameplay code writes `Engine.time_scale` or SceneTree suspension; the ordinary Esc path uses SceneTree pause. No current running game process was available to inspect. Read-only saved preferences showed Master80/Music13/SFX80, none muted. Subsequent tests use that volume in an isolated profile and capture on Master, after Music-bus gain; the user's settings and saves are untouched.

Godot source investigation: [AudioStreamPlayerInternal notifications](https://raw.githubusercontent.com/godotengine/godot/master/scene/audio/audio_stream_player_internal.cpp) distinguishes SceneTree pause from whole-tree suspension. The local runtime is Godot4.7.1 `a13da4feb`; runtime checks below are the evidence for this build. A debugger/OS suspension is not an ordinary in-game Esc pause. Fresh-process success does not establish the cause of the user's previous audible stop or human mix acceptance.

## Verification

**PASS:** all20 focused suites plus import; runtime `a2772c29a42bfd7b76c25743794e8ded3fec97beecff98ac95e04a9833aab586`; all735 canonical inputs match the tested project. New rules79/79 plus extra migration10/10, generic parents65/65, navigation84/84, native map447/447, native HUD153/153, real WASAPI continuity300/300.39 native captures. See the complete suite table and exact commands in the evidence README. Evidence folder: [store-gameplay-links-20261018-v1](../findings/store-gameplay-links-20261018-v1/README.md).

Retained failed iterations: pass1 caught a nonconstant rules declaration; pass2 caught removed-gate references in a test helper; pass3 caught an AND connector crossing another card and a header bound. These were fixed before pass4 native checks (zero failures). The first final pass caught a verifier submitting Turn-Based Combat familiarity as Design rather than its actual Alpha phase; the fixture now reads the card's actual phase. No production phase/scoring rule was changed for that failure.

A temporary snapshot copy hit Windows disk-full. Only this task's disposable project copies were removed after retaining logs, manifests, screenshots and text-source archives where available; prior task data and `.codex-godot-temp` were not touched. The incomplete final copy was recreated; no checks are claimed from it.

## Files and follow-ups

Production: `data/feature_store_ledger.json`; `scripts/cards/feature_store_catalog.gd`; `scripts/ui/feature_store.gd`, `feature_store_map.gd`, `pause_menu.gd`; `scripts/audio/soundtrack.gd`; `scripts/persistence/studio_checkpoint.gd`; `scripts/market/rival_world_checkpoint.gd`. Focused verifier/capture changes are listed in `audit.json` and the task diff. Shared design, decisions, status and TODO records now reflect this bounded result.

Store implementation is complete locally, including the Decision019/Handoff018 acceptance. New-game specialty Handoff017 and future convergence designs remain separate. Pause transport/frame independence passes, but the user's prior audible stop was not reproduced; human listening in a restarted current game remains OPEN. No release-readiness, commit, push or export claim.

Final fixture corrections also retained: the Resourceful test originally chose the first unowned Primitive, now potentially parent-locked; it now chooses a legal purchase. The extra migration test initially forgot rent at cycle2; comparison now uses the real central finance transaction. Only the former debug fixture was updated within the final copied project; initial/final manifests and failed logs are retained. Production runtime stayed fixed across that final series.
