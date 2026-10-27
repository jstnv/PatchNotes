# Outta Pocket reference motion — 2026-10-26

User supplied `C:/Users/64jus/Videos/2026-10-26 22-49-42.mp4`, requesting player-button entrance bounce for score/multiplier popups, player-button exit counter-bounce before Balanced merges, Assign/Skip entrance for mitosis and eased alignment to card positions, on a similar music map. Inspected current state/queue/design, source/diff, branch/HEAD and status. Shared dirty `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac`; existing edits and `.codex-godot-temp` preserved.

## Reference and choices

Decoded the17.883333s,1920×1080,60fps clip locally. Reference SHA256 `d8621b4d9de1d51fed2179e926b640b29dee3a2c2bc7f8cae9cc0f66e16da89d`. Retained overview frames, detailed entrance/exit contacts and metadata in `docs/codex/findings/score-reference-20261026-v1/`. The supplied video is unchanged and not copied wholesale into the repository.

Read-only inspection also located the actual Outta Pocket implementation at `C:/Users/64jus/OneDrive/Documents/GitHub/outtapocket/outta-pocket/scripts/game_screen.gd`, SHA256 `a3d7303a7465c2e16fa2670f64193be893c81973d42153c3ac8335a4e5ce874e`. Player entry360–408 uses `TRANS_BACK/EASE_OUT` over0.34s, with a0.06s right-list delay. Exit411–422 uses `TRANS_BACK/EASE_IN`. Assign/Skip425–444 uses `TRANS_CUBIC/EASE_OUT` over0.42s. Captured source snippets/pins; did not edit or run that project. Video-to-executable/source identity is not established; clip observation and current local source are separate evidence.

Use these engine curves directly, normalized to Patch Notes' existing music intervals. Do not copy the reference's wall-clock durations or stagger the simultaneous multipliers. This supersedes the hand-shaped gravity/10px landing curves for score emergence and merge travel. The Back entrance overshoots by about7px at the current74px travel, then settles. Back-in merge travel first moves away from contact, reverses and accelerates inward. Cubic-out mitosis launches quickly and slows into its full spread/card alignment without overshooting those card positions.

## Implementation and map

`patch-notes/scripts/ui/card_score_floats.gd` uses sampled `Tween.interpolate_value` for the referenced curves. Balanced gathering and both inward pair merges gain the counter-bounce; Specialization's merge shares the style. The complete spread holds before the next reverse motion. No scene Tween or new timer drives numeric timing.

| Popup-relative subdivisions (60/140s each) | Balanced motion |
| --- | --- |
| 0–0.5 | Anticipate away, then gather toward the central merge |
| 0.5–1 | Assign/Skip-style outward sum/multiplier mitosis |
| 1–1.5 | Stationary spread hold |
| 1.5–2 | Opposite-direction anticipation, then merge at the original result beat |
| 2–2.25 | Show exact boosted total; existing shake |
| 2.25–3 | Cubic-out four-way separation; ease into card positions |
| 3–4 | Readable category totals at the cards |
| 4–5 | Existing exit toss; hide, confirmed HUD deposit, then played-card removal |

The former internal2.15 split start is replaced by the exact quarter-subdivision2.25; arrival remains3. Base left-to-right activations stay140/minute. Popup entrances retain their original half-subdivision intervals. Overall synergy duration, exact gameplay output, once-only action, rounding/caps, exit/HUD handoff and music transport unchanged.

`scripts/debug/verify_score_floats.gd` covers actual opposite-direction travel/reversal, reference overshoot/settle, static spread hold, eased arrivals and existing bounds/score/clock/cleanup cases. Screenshot helper now retains its Image while saving and logs image dimensions. `scripts/market/rival_world_checkpoint.gd` admits only exact preceding source `f9854f69fe47880510e5c933b80aefbbc7f6469226328321f8ff55e33bdbe3b4` through ordinary full validation; no field/RNG changes. Updated design/status/queue; no other runtime files changed in this pass.

## Checks / retained diagnostics

Private profiles/writer ports, Godot4.7.1, Dummy audio. Exact command/exit/log receipts in the finding. Runner: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe -X utf8 docs/codex/findings/score-reference-20261026-v1/run.py LABEL SCRIPT [--native] [--out=ABSOLUTE_DIR]`. Player saves untouched.

| Label / script | Result |
| --- | --- |
| baseline / prior restore.gd --capture | PASS2 genuine predecessor Studio/world save |
| red / verify_score_floats | Expected2 failures: missing reference anticipation and Assign/Skip-style departure |
| green / same | PASS324: reference trajectories, actual node reversal/landing/hold, exact scores, normal/Specialization/Balanced/QA/Contract, low FPS/rejoin/cancel/HUD |
| native-no-capture / same --native | PASS324 rendered checks without image export |
| native-v2 / same --native --out | PASS324 at1152×648,1280×720 and832×320;30 PNGs, reference entrance/apex/hold/counter-bounce/card-arrival frames inspected |
| sync / verify_soundtrack_sync | PASS3,503; original grid/durations, varied sequence lengths, wraps and pause/resume |
| cold-final / prior restore.gd | PASS10; exact predecessor player/world/RNG, unknown-source rejection, unchanged generation bytes |

Initial `native-final` failed during its first PNG save with Godot null-allocation/image-to-PNG errors and access-violation exit3221225477; retained log. Subsequent native run without capture and the run using an owned Image/local dimension diagnostics both pass. No engine-level allocation fix or proof of the underlying crash cause is claimed. Successful receipts have no SCRIPT ERROR/ERROR/FAIL; existing ObjectDB cleanup warnings remain. A video-decoder pip attempt failed DNS access; no package installed. Found and used existing Topaz ffmpeg/ffprobe through the repository audio helper's path instead, fully locally.

Final runtime identity `4bc1caa6263cc6a965101c5231288465b97d4c1b76c2890d4e507441c58be0e0`. Audit matches current non-debug resource bytes to Godot's manifest and reconstructs the exact predecessor with preserved originals. Scoped whitespace check recognizes CRLF. No gameplay/campaign/performance/audible or human-feel acceptance claim; no new EXE/ZIP, commit or push. Human comparison of the normalized motion remains a playtest judgment.
