# Annual Awards placing stamps, 2026-11-03

Implemented on local `main` at base `7c60a01cbfac76d3f3cae1062849a070b1563116`, on top of the current podium edits. Files touched for this pass are `patch-notes/scripts/ui/annual_awards_ceremony.gd`, `patch-notes/scripts/debug/verify_annual_awards_ui.gd`, the annual awards design, TODO and this log.

The bar captions read Third, Second and Winner. Each placing starts visibly compressed on the score frame, overshoots, then settles. Third and Second take 0.30 seconds. Winner takes 0.46 seconds with a larger overshoot and two brief horizontal strokes. Each caption owns its animation clock, including the final Winner after the shared score clock stops. Immediate completion and animation bypass display the resting pose.

Godot 4.7.1 windowed ceremony UI verifier passed **332 checks, zero failures** in an isolated profile. Coverage includes start timing, word choice, one entrance per score, independent settling, immediate completion, natural winner reveal and 30/120 fps bar stepping at both supported sizes. Scoped diff whitespace check passed.

Rendered the native presenter with the 1980 Best Graphics finalists at 1280×720 and 60 fps. It reported final bar heights of 94, 125 and 156 pixels in third-to-first order and a maximum frame step of one pixel. Inspected the hidden, emerging, overshooting and resting winner frames. The delivered MP4 decoded completely with FFmpeg. Player preference for the chosen motion is open. [Placing preview](C:/Users/64jus/.codex/visualizations/2026/11/01/01a19550-3db3-7063-bdfc-48e0d232692c/Best-Graphics-Placing-Stamps.mp4)
