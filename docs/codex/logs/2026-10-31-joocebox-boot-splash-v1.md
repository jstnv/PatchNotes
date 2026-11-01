# JooceBox boot splash — 2026-10-31

User request: replace the large initial Godot logo with supplied JooceBox artwork/studio name and a smaller Godot icon below. Branch `main`, HEAD `49d769235474a880a73d996499cefa72beec63e5`; concurrent Annual Awards DECISIONS edit preserved, no commit/push.

Changed canonical files: `patch-notes/project.godot`, new `assets/branding/joocebox_logo.png` and `joocebox_boot_splash.png`. Added reproducible `tools/build_boot_splash.gd`; updated release design, CURRENT_STATE and TODO. No gameplay code, content, main-scene identity, save rules or music transport change.

[Source hashes, original asset provenance, native/headless command lines, retained first-layout error and acceptance limits](../findings/boot-splash-20261031-v1/README.md). Final builder exit0; headless11/0; both native sizes exit0/no errors. Actual native splash seen at both sizes and1280 Main Menu transition observed. Exact input logo copy verified. Gameplay runtime remains ef14cc…; canonical source delta limited to project config/two PNGs. Source snapshots and native profiles remain separated; both .codex-godot-temp directories retained.

Existing EXE/ZIP unchanged; a future export is needed for packaged delivery. No unrelated checks or automatic follow-up started.
