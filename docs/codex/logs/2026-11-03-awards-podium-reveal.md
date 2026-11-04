# Annual Awards podium reveal, 2026-11-03

Implemented locally on `main` at base `7c60a01cbfac76d3f3cae1062849a070b1563116`. Changes for this task are the ceremony presenter, its maintained UI verifier, the annual awards design, the TODO completion entry and this log.

Each nominee counts up on the same scale until it reaches its frozen score. Its place then appears inside the base of its bar. The winning bar changes color and reveals “WINNER” on that frame. Studio and title order determines the lanes. Each centered bar is 128 layout pixels wide above its nominee card. A fixed 32-pixel base keeps the rank legible even when the score is zero. Equal scores finish together.

Godot 4.7.1, windowed, isolated profile. `res://scripts/debug/verify_annual_awards_ui.gd` reported **270 checks, 0 failures**. Coverage includes both supported window sizes, concealed rank/color, a runner-up immediately before and at the endpoint, zero and large scores, ties, empty places, animation bypass and native layout. The Gameplay capture restored the 1980 first-year career fixture, visited all ten pages via Next, scrolled the final results and exited to Studio. Inspected the moving and completed Graphics frames. The updated MP4 decoded in full with FFmpeg `-xerror`. FFprobe reported 2,177 frames at 30 fps, 1280×720, AAC audio and 11 chapters. Duration 72.567 seconds. [Recording](C:/Users/64jus/.codex/visualizations/2026/11/01/01a19550-3db3-7063-bdfc-48e0d232692c/Patch-Notes-Annual-Awards-Podium-Reveal.mp4)

The focused check and recording cover the local Windows build. Player review of the reveal pacing is open.
