# Awards podium scale and Core headings, 2026-11-03

Implemented in the shared local checkout on `main` at base `7c60a01cbfac76d3f3cae1062849a070b1563116`, on top of the prior podium and pacing edits. This change touches `annual_awards_ceremony.gd`, `verify_annual_awards_ui.gd`, the annual awards design, TODO and this log.

Podiums use a common scale up to the lowest finalist, then give points between the lowest and winning scores up to five times their former height. Wide ranges reduce that magnification to fit the plot and leave a positive bar for a positive lowest score. Actual counters, rank reveal timing and stored award data use the original scores. The Core pages, contenders list and recap use Best Graphics, Best Sound, Best Technology and Best Design. The four redundant subtitles are removed.

Windowed Godot 4.7.1 ceremony UI verifier passed **315 checks with 0 failures** at 1152×648 and 1280×720. The close-score fixture showed the expected 31.2 layout pixels per two-point gap on the 156-pixel plot. Wide, tied and zero scores fit. Each Core page's heading, absence of a subtitle, and recap title passed. Scoped diff whitespace check passed.

The full Gameplay capture did not reach the ceremony during this check. The delivered preview renders the actual ceremony control directly with saved 1980 Graphics finalists. Final fill heights measured 93.6, 124.8 and 156 layout pixels for 46, 48 and 50. Inspected the finished frame and decoded the MP4 in full with FFmpeg. [Preview](C:/Users/64jus/.codex/visualizations/2026/11/01/01a19550-3db3-7063-bdfc-48e0d232692c/Best-Graphics-Podium-Scale.mp4)
