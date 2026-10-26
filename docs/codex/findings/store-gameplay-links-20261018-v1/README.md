# Store Gameplay convergence and pause transport — verified 2026-10-18

**PASS locally; original audible-stop reproduction remains OPEN.** All20 focused suites and the Godot import completed with exit0 and no script/runtime errors in their final runs. Source identity: `a2772c29a42bfd7b76c25743794e8ded3fec97beecff98ac95e04a9833aab586`; all735 canonical inputs equal the final tested project. Shared branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; dirty work was preserved. No export/commit/push was done.

## Evidence and commands

- [Source and file audit](audit.json), [scoped task diff](task-diff.patch), [final results and exact per-process commands](final-v2/results.json), [additional migration probe](final-v2/extra-results.json).
- Runner: bundled Python `-X utf8 docs/codex/findings/store-gameplay-links-20261018-v1/run.py <fresh-stage> <suite names>`. Runtime: Godot4.7.1 `a13da4feb`. Each suite uses an isolated profile and checkpoint port. Headless checks use Dummy; the audio transport check uses WASAPI; captures use native OpenGL. Exact arguments are recorded, including source project and output locations.
- `run_existing.py` continues an already-imported evidence project. `verify_gameplay_extra.gd` reads `PN_GAMEPLAY_PRIOR_SAVES` from the real pre-change producer output. Baseline producer ran on the original frozen runtime, before any rule change.
- [Pre-change queued/owned/partially paid checkpoints](before/produce_gameplay_prior.json), [pre-change active world](before/verify_legacy_world.json), [restored world](final-v2/restored-world.json).
- [Audio trace](final-v2/verify_pause_track_continuity.json):144 half-second audio captures, 2 raw loop wraps, 72.032s between first/last corrected-clock samples; minimum Master-capture energy 0.015408. Uses saved-volume-equivalent Master80/Music13/SFX80 in an isolated profile. Tests72 seconds paused, zero gameplay time scale, main/Studio arrangement changes, paused Settings, frozen game state, unchanged playback instance and recovery from a deliberately latched transport pause/disabled callback.300 checks passed. Original pre-change72-second test also passed293 checks; this is hardening, not a claimed reproduction of the user's stop.

## Final checks

| Suite | Result |
|---|---|
| `import` | PASS import |
| `verify_gameplay_tree` | GAMEPLAY_TREE checks=79 failures=0 |
| `verify_feature_store` | PASS 67 assertions |
| `verify_feature_parents` | PASS 65 assertions |
| `verify_feature_research` | PASS 26 assertions |
| `verify_research_integration` | PASS 46 assertions |
| `verify_store_cone_parents` | STORE_CONE_PARENTS checks=171 failures=0 |
| `verify_primitive_branches` | PRIMITIVE_BRANCHES checks=205 failures=0 |
| `verify_store_shopping_guidance` | PASS 38 assertions |
| `verify_feature_spending_guidance` | PASS 59 assertions |
| `verify_feature_store_navigation` | PASS 84 assertions |
| `verify_store_hud` | STORE_HUD checks=135 failures=0 |
| `verify_world_restore_file` | PASS 5 assertions |
| `verify_pause_menu` | PAUSE_MENU checks=64 failures=0 |
| `verify_pause_music` | PAUSE_MUSIC checks=713 failures=0 |
| `verify_soundtrack_sync` | Soundtrack sync: 3503 checks, 0 failures |
| `verify_studio_soundtrack` | Studio soundtrack: 7621 checks, 0 failures |
| `capture_store_cones` | PASS 447 assertions |
| `capture_store_hud` | STORE_HUD checks=153 failures=0 |
| `verify_pause_track_continuity` | PAUSE_TRACK backend=WASAPI checks=300 failures=0 |
| `verify_gameplay_extra` | GAMEPLAY_EXTRA checks=10 failures=0 |

## Screenshots and visual review

39 native PNGs retained. Geometry, connector clearance, heading bounds, passive navigation, Debug and the compact Research row were verified at1152×648 and1280×720;900×600 is an extra stress size, and HUD also covers1920×1080. Representative final captures visually inspected include both-size Gameplay convergence, Difficulty details, Visuals/Audio headers, and1152/900/1920 HUDs. “Show all” is a compact structural overview; use zoom/focus to read individual card labels.

- [Research row and chart](final-v2/store-1152x648.png)
- [Gameplay two-parent merge](final-v2/store-gameplay-merge-1280.png)
- [Difficulty Levels details](final-v2/store-difficulty-details-1152.png)
- [Whole map](final-v2/store-1920x1080.png)

## Boundaries and retained failures

The card/price audit confirms the ledger delta is only Difficulty Levels' prerequisite fields. Normal same-tree ownership requirements and the shared50% familiarity cap apply to new admissions. Old owned sets, paid queues, a constructed historical two-action partial queue, historical releases and active rival project supply retain all fields except version/source markers. Fresh restoration still rejects unknown source identities. Further two-parent design choices and specialty Handoff017 remain outside this change.

Iteration failures remain in logs. Corrected: nonconstant version declaration; obsolete synthetic-gate test references; an arrow crossing another card; rotated header minimum-size bounds. Two verifier fixtures needed legitimate acquisitions/current card phases: Resourceful now chooses an actually purchasable Primitive, and Turn-Based Combat credit is submitted in Alpha. The extra partial-payment probe initially omitted the normal cycle2 rent; its corrected native finance control includes that real bill. No production scoring, finance, trait or phase rule was changed to satisfy those fixture repairs.

`final-v2/source.initial.json` and the failed Research integration log retain the initial test revision. Only that debug fixture changed inside the final test project; `source.json` records the corrected fixture. The runtime source was unchanged throughout this final series. `audit.json` confirms every current source byte matches the tested project after generated debug UIDs were copied back.

Existing missing-art warnings, a deliberate invalid-Alpha fixture warning and the known six ObjectDB exit leaks remain. No parse errors, unexpected runtime errors or failed final assertions. Human listening/mix acceptance and an exported application playtest were not performed. The prior stop's exact cause remains unproven; the new Esc transport recovery and unscaled fade are verified.

Windows disk-full interrupted one temporary copy. Only this task's disposable project directories were removed; logs, images and manifests remain. `before/source-text.zip` preserves the original text source, including the old rules/catalog; pass3/pass4 have corresponding text archives. Their unchanged binary assets can be reconstructed from canonical files only after verifying the recorded source hashes. The current final tested project remains available. Existing worktrees, older task evidence and `.codex-godot-temp` were not removed.
