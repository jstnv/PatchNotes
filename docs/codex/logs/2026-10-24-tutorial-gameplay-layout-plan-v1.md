# Tutorial gameplay layout correction — 2026-10-24

User direction: tutorial should look like ordinary gameplay; the scoreboard is obscured during QA animation. Existing sandbox/lessons/real-state isolation stay intact. Routine design choices are delegated by the existing no-input workflow.

Source diagnosis: tutorial has a plain inline score label and full-viewport HandPresentation. Hiding CardFan removes its VBox height, moving actions upwards; animated cards and the top-centered synergy banner can cover the scores/instructions. Regular play has a persistent header, a bounded development workspace, selection/backlog labels and bottom actions.

Execute inline in the shared checkout, preserving existing edits and `.codex-godot-temp`. No commit/push or export is requested.

- [x] Add a meaningful layout RED to the maintained tutorial UI verifier; freeze current source and a genuine current-source world before edits.
- [x] Extract the existing HUD's read-only score labels/rendering into `ui/production_scoreboard.gd`, used by live HUD and tutorial. Keep live array indices/targets/labels stable; show tutorial Hidden Bugs beside Known/Fixed in Beta.
- [x] Give tutorial the same persistent top HUD, selection/backlog/playfield/bottom-action arrangement. Persistent instructions and phase/Next live on the right. Keep fan/motion in a stable clipped playfield; reserve a separate synergy lane. Exit stays reachable; no real Studio/HUD rebind or gameplay changes.
- [x] Verify complete tutorial, animated score/bonus/return phases, live HUD regressions, real state/RNG/disk identity and predecessor restoration. Inspect native captures at1152×648,1280×720 and the reported1906×932 size. Record exact source, failures/limits and completion in local docs.
