# Annual Awards counter timing, 2026-11-03

Implemented in the shared local checkout on `main` at base `7c60a01cbfac76d3f3cae1062849a070b1563116`, on top of the existing podium reveal edits. This change touches `patch-notes/scripts/ui/annual_awards_ceremony.gd`, `patch-notes/scripts/debug/verify_annual_awards_ui.gd`, the annual awards design, the local TODO and this log.

The timing curve follows the previous opening through 80% of third place's score. It matches the incoming speed at that threshold, progressively slows until third place appears, then advances at a constant speed until the winner appears. As a presentation choice, a distinct winner's remaining distance takes 1.5–5 seconds, depending on the score gap. A zero third-place score starts on the slow segment. Fewer than three nominees use the existing opening curve.

Godot 4.7.1 windowed `res://scripts/debug/verify_annual_awards_ui.gd` passed **275 checks, 0 failures** at the two supported sizes. The new checks cover the threshold, decreasing speed, constant speed across second place, a zero third-place score and a missing third nominee.

Recorded Gameplay from a private profile using the [1980 first-year career fixture](../findings/awards-presentation-20261101-v2/current-world/fixture.json.first-year.json). At 30 fps, the Graphics counter started on frame 345, revealed third on 383 at 46, second on 405 at 48, and finished on 428 at 50. The two equal score gaps took 22 and 23 frames. FFmpeg decoded the entire 157-frame, 1280×720 H.264/AAC clip with `-xerror`. Human pacing review is open. [Graphics award clip](C:/Users/64jus/.codex/visualizations/2026/11/01/01a19550-3db3-7063-bdfc-48e0d232692c/Patch-Notes-Graphics-Counter-Slowdown.mp4)
