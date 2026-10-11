# Store motion verifier timing repair

2026-10-09, local `main` at `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. The parent education gate stopped after 19 completed suites because `verify_card_motion` failed one intermediate Store assertion at 1152 width. Original failed-gate records remain untouched.

## Finding and bounded correction

The original test waited for a 0.20-second SceneTree timer, then required a 0.30-second camera Tween to be in progress. A timer callback resumes at a processed frame boundary; it does not guarantee an exact elapsed Tween time. The Store implementation starts a separate 0.20-second menu Tween after camera completion and clears `focusing` at that callback.

The original gate's precise scheduling sequence was **not reproduced**. `old-timing-v1` retains ordinary and deliberate 400 ms main-thread-delay samples: the timer requested 0.20 seconds, while observed camera times were 0.2083 and 0.1967 seconds (wall times 0.153/0.475 seconds). Both original assertions passed locally. A separate high-timescale diagnostic exposed timer/Tween sampling divergence and two subsequent layout assertions; this is a synthetic diagnostic, not a player-runtime defect or a reproduction of the original gate failure. Its original command, log and observations are retained as `old-timing-v2`.

Only `patch-notes/scripts/debug/verify_card_motion.gd` changed. The test pauses the existing runtime camera Tween and advances its clock by fixed 0.01-second increments, allowing two actual container-layout frames between increments. It samples strictly increasing zoom at 0.10/0.20 seconds, hidden details during the camera phase, and the camera's actual completion callback. The callback-created menu Tween is paused immediately, then stepped through its real slide/fade and completion/input restoration. Final bounds, passive state and cancellation checks remain.

Initial manual-step attempts are preserved: `full-v1` and `store-v2` failed eight menu/layout assertions each because large camera jumps outran ScrollContainer's deferred range updates. Smaller increments and real layout passes resolved the verifier setup issue. No runtime fix, tolerance expansion or removed animation requirement was used.

## Accepted evidence

- `store-v3`: both Store sizes pass, exit 0, no unclassified errors, 7.594 seconds.
- `full-v2`: the complete inherited motion suite passes **114 assertions**, exit 0, no unclassified errors, **76.922 seconds**. Source hashes are identical before/after.
- `audit.json`: every file in the 676-file final education pin still matches except this one debug verifier. Runtime, scenes and data are unchanged. All source before the Store test and from `_paid_hand` onward is unchanged, including real-time 140 BPM, 4:1, scoring, redraw and Contract checks.
- Actual card intervals: 1152 width `0.420, 0.435, 0.420` seconds; 900 width `0.434, 0.422, 0.434` seconds. Actual specialization cycles: `1.700` and `1.711` seconds. Existing acceptance tolerances are unchanged.
- Store traces at both sizes show strict progressive camera zoom, menu x positions `433 → 463 → 473`, and half-duration opacity `0.75`.

Final verifier SHA-256: `fdd984fccd9a1048f816eb116d34ee10a0642e1c560c79c71c5cbe64cddcee2a`. Original and preparatory verifier versions are retained alongside the logs. `git diff --check` passed, with only Git's line-ending normalization warning.

Commands used bundled Python and `run.py`; each command JSON records the exact Godot command, isolated profile and source/log/trace hashes. The inherited checkpoint wrapper uses the parent-reviewed real TCP lease on 47733. The pre-existing user Godot process owning production port 62741 was not touched. No Computer Use or visible app was launched. Education's accepted source archives and audit remain immutable; their old full manifests include the earlier card-motion verifier.

All runtime/debug/UID/tool source is frozen again. Parent owns the fresh combined gate. No native helper process remains.
