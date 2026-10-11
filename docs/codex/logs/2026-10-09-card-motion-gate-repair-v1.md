# Card motion gate repair — 2026-10-09

Local `main` at `41c87c76fb4d3c06a5332d93f0e7b0997007475d`; existing dirty edits preserved. No commit/push, Computer Use, visible launch or user-process termination.

Parent's education combined gate stopped at one Store intermediate-timing assertion after 19 completed suites. The original test sampled a 0.30-second camera Tween after a frame-scheduled 0.20-second timer. Exact original scheduling was not reproduced; native diagnostics preserve the actual timer/Tween/wall measurements and their limitations.

Changed only `patch-notes/scripts/debug/verify_card_motion.gd`: pause and step the existing camera/menu Tweens, with small camera increments and actual ScrollContainer layout passes, to assert intermediate zoom, menu slide/fade, completion/input restoration and final bounds deterministically. The real-time card animation, 140 BPM/4:1, scoring, redraw, cancellation and Contract checks remain unchanged. Runtime/scenes/data match the final education source pin exactly.

Verification:

- Store-only v3 passed both sizes in 7.594 seconds.
- Full inherited suite v2: **114 assertions, 0 failures, exit 0**, 76.922 seconds; unchanged source before/after and no unclassified errors.
- Native beat intervals 0.420–0.435 seconds; specialization cycles 1.700/1.711 seconds, with unchanged existing tolerances.
- `audit.json` independently reconciles traces and confirms the sole drift among 676 pinned files is this debug verifier. Final SHA-256 `fdd984fccd9a1048f816eb116d34ee10a0642e1c560c79c71c5cbe64cddcee2a`.
- Focused `git diff --check` passed; only line-ending normalization warning.

Evidence and complete commands: `docs/codex/findings/card-motion-gate-repair-v1/README.md`. Original gate failures, diagnostic results and two failed large-step test attempts remain preserved. Education archives and accepted audit are unchanged.

All runtime/debug/UID/tool sources frozen; no native process remains. Parent may run the fresh combined gate using its isolated test writer. Actual exported rendered acceptance stays deferred overnight.
