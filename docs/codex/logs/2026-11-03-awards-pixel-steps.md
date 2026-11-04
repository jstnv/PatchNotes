# Annual Awards single-pixel bar motion, 2026-11-03

Implemented on local `main` at base `7c60a01c`, with existing working tree edits. Updated `annual_awards_ceremony.gd`, `verify_annual_awards_ui.gd`, the awards design, TODO and this log.

The presenter drives the fill from the fractional score on the shared reveal clock and quantizes it to viewport pixels. When one frame would cover several pixel rows, it advances that clock only to the next row. Each displayed score, rank and bar endpoint stays synchronized. Lower frame rates can take longer to display every row.

The windowed Godot 4.7.1 verifier passed **323 checks with zero failures** in a fresh profile, including 30 and 120 fps intervals at both supported sizes and scaled-window coverage. One earlier rerun using a reused test profile failed its draft Settings preference assertion. The fresh-profile run passed it. Scoped diff whitespace checks passed.

Captured the native Best Graphics presenter with the 1980 fixture at 1280×720, 60 fps. An initial movie rescaled the viewport and skipped rows in the encode. The final movie used matching viewport and encoding dimensions. Scanned one luminance column per bar across all 282 decoded MP4 frames. The three edges traveled 94, 125 and 156 pixels respectively. All per-frame changes were either zero or one pixel. Winner and frozen score appeared together. [Verified preview](C:/Users/64jus/.codex/visualizations/2026/11/01/01a19550-3db3-7063-bdfc-48e0d232692c/Best-Graphics-Pixel-Steps.mp4)
