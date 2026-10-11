# 2026-10-11 G1a TODO coordination update

Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. The shared checkout and `docs/codex/TODO.md` were already dirty; the implementation thread is active. Read current state, TODO item 22, the v2 packet and candidate decision; inspected branch/status/diff before editing.

Changed only [TODO item 22](../../TODO.md) by adding a G1a coordination paragraph. It keeps the private archive packet in DESIGN review outside the active canonical gameplay slot; later review must resolve cohort/migration decisions, verify sealed hashes against current source drift, and rerun legal opening/save/live-headless checks. No gameplay, player saves, `.codex-godot-temp`, other queue item, commit or push changed in this turn.

Check: targeted `rg -n -A 3 -B 1 '2026-10-11 G1a frozen archive' docs/codex/TODO.md` found the existing packet entry at line 97 before edit. After edit, verify the new paragraph and `git diff --check -- docs/codex/TODO.md`. The packet's numerical cohort values and cross-revision migration remain OPEN; implementation sequencing is the current coordination limit.
