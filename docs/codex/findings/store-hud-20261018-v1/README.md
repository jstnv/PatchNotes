# Feature Store HUD reorganization — 2026-10-18

Direct implementation request, shared `main` at `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. [Initial source/status](before/git.json), [final source/status](closeout-git.json), [task-only diff against the pre-existing dirty project](task-diff.patch), [731-input byte audit and changed-file list](audit.json).

## Result

- Feature Store title at top left; centered Owned Pool summary to its right, with Scope followed by Graphics, Sound, Tech and Design. All three header surfaces share the sales chart's top origin. The aggregate Core Score is removed from this display.
- The chart stays in its persistent top-right corner and remains mouse-accessible. Close Store sits below it, with Debug beside Close Store. Feature detail panels stay below that corner too.
- Removed the five category shortcut buttons. Retained map pan, wheel/plus/minus zoom, Show all, arrow browsing, category regions and prerequisite details.
- Moved prototype fee/TBD counts and incomplete future-cost commentary to the Debug tooltip. Clicking or keyboard-activating Debug opens the same notes in a bounded scrollable panel; Esc closes it and restores focus. Scrolling notes does not zoom the map beneath. Known play cost remains in the Owned Pool tooltip. Real cash-shortfall warnings and itemized acquisition/blocking details remain accessible.
- Fixed header height after resizing and kept the header stationary while body content uses its existing entrance animation. Fixed a pre-existing keyboard tie whose result depended on interpolated zoom rounding: navigation uses map coordinates and favors the actual parent for an equal-distance inward choice.

No card/catalog data, pricing, research, sales, finance, scoring, RNG or Continue boundary changes. The exact pre-change world source is explicitly compatible because the runtime fingerprint includes presentation scripts; all field validation still runs.

## Verification

Godot4.7.1, frozen copies, separate APPDATA/LOCALAPPDATA/TEMP and checkpoint writer ports. Synthetic funded/released fixtures followed by real calendar and research actions; these are focused UI/system checks, not a claimed full player campaign.

[All final commands, exits and summaries](final-v2/results.json). All12 processes (import plus11 checks/captures) exit0 without script/runtime errors.

| Check | Result |
|---|---|
| Pre-change world producer | 30/30 |
| New Store HUD, headless | 130/130 |
| Store behavior | 66/66 |
| Store pointer, keyboard, Pause and zoom navigation | 84/84 |
| Spending guidance / shopping guidance | 59/59 / 38/38 |
| Store copy, quotes and blockers | 52/52 |
| Actual prior-source player/world restore | 5/5; exact fields and unknown-source rejection |
| Sales HUD behavior | 458/458 |
| Gameplay HUD/priority overlay | PASS |
| Native Store HUD | 148/148; nine PNGs |
| Other-phase sales HUD rendering | 150/150; ten PNGs |

Store rendering covers1152×648,1280×720,1920×1080 plus900×600 stress, each with a six-title portfolio and four legally researched unpriced Features. Also covers a fresh starter Studio without a chart, top alignment, summary data/text fit, corner hit-testing, Debug keyboard/wheel/Esc behavior, details below the chart, close/reopen layout and unchanged authoritative state. All nine Store PNGs inspected. Other-phase native assertions cover Studio/Design/Alpha/Beta/Contract at1152×648 and1280×720; representative Studio/Beta images inspected.

[Store1152](final-v2/store-1152x648.png) · [Store1920](final-v2/store-1920x1080.png) · [Debug1152](final-v2/debug-1152x648.png) · [starter](final-v2/starter-1152x648.png).

Final source identity: `ea4268bd65ae08e2a5a344384eb82dbd1a2fd9f3ef710def8443a0ce578f910c`. All731 canonical source/asset inputs exactly match the imported/tested project after copying its two generated verifier UID sidecars. Data files match the pre-change snapshot. No commit, push or new export was made.

## Repairs and remaining limits

Early attempts are retained: check-v1 found an inferred-bool parse error; check-v2/render-v1 caught header resize and overly strict map-height expectations; check-v3 exposed the zoom-sensitive keyboard tie. Final-v1 found four failures in the older spending fixture. The [unchanged baseline probe](before/old-guidance-probe.log) reproduces those same four: it chose the first unowned Feature without checking the newly required parent. The corrected single-purchase fixture chooses a currently available Primitive; no purchase rule was changed. Final-v2 passes all of these.

Existing missing-artwork/invalid-Alpha-fixture warnings and six ObjectDB instances at headless exit remain (also present before these edits); final native Store capture has no warnings. The full-map view remains a navigation overview; wheel/plus and node focus expose labels. Human usability and a refreshed exported binary are not claimed. Unrelated queued handoffs retain their status.

Reproduce: bundled Python `run.py <fresh-stage> verify_store_hud verify_feature_store verify_feature_store_navigation verify_feature_spending_guidance verify_store_shopping_guidance verify_feature_store_copy verify_world_restore_file verify_sales_revenue_hud verify_gameplay_hud_overlay capture_store_hud capture_sales_hud`. The preserved `before/verify_legacy_world.json` supplies the actual earlier save. `audit.py` checks final-v2 source correspondence and writes the task diff.
