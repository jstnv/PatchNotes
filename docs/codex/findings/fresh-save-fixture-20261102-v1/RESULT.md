# Fresh-save fixture timeout — 2026-11-02

FIXED at scoped Godot4.7.1 Windows source-build acceptance. Base main51293b2cf6180ecb139a83ea136e4e9114aa552c. Runtime source identity remainsa16105547ae52b2f41e33908977f53ae6a230af6434fbd637902f084e5544afb. This is a test-setup repair, not a gameplay performance optimization. [Plan](../../plans/2026-11-02-fresh-save-fixture.md) · [audit](audit-result.json).

## Root cause and change

Real New Save asynchronously hydrates the eight-rival world, durably publishes the player/world checkpoint, and reveals the tutorial invitation before clearing the transition flag. Existing UI fixtures allowed20s, while the dedicated loading test allowed15s. The previous observation20,953ms and this pass's32,471ms healthy setup exceed those limits. Warm baseline focused browsing still passed22/0, confirming intermittent timing rather than an unconditional broken state.

A controlled test delayed the first real private checkpoint publication by21s without changing gameplay. The old helper asserted with publication still pending (delay-red/). The identical fixture now completes8/0, waiting45,968ms under concurrent verification and confirming durable save, normal rivals, unchanged initial values, immediate return on an already-completed setup and player/RNG passivity. The delay is test-only, not shipped gameplay.

- ui_test_actions.gd: one shared bounded60s setup constant,10s progress lines and elapsed/phase timeout diagnostics. Existing completion, Studio-phase and tutorial-choice assertions remain.
- verify_feature_store_radial.gd: declared viewport cases drive both the loop and whole-suite watchdog:3×60s setup plus50s action allowance. The headless three-save run took147.687s, exceeding the old110s total guard. Per-focus/action deadlines are unchanged.
- verify_new_save_loading.gd: reuses the shared setup constant in place of15s; all visual/transport/invitation/durability assertions remain. Original LF format preserved.

All changes under patch-notes/ are restricted to these three debug files. No production code, data/assets, prices/balance, save schema/source admission, finance/RNG or Studio-only Continue boundary changes. Exact full-source inventory comparison confirms that scope.

## Acceptance

| Route | Result | Record |
|---|---|---|
| Controlled21s real initial-publication delay | original20s RED→8/0 GREEN | delay-red/ and delay-green/ |
| Maintained Store radial,1152×648,900×600 stress,1280×720 |255/0 headless;255/0 native | radial-headless/ and radial-native/ |
| Maintained focused Store cases,1280×720 |22/0 native | focus-native/ |
| Maintained New Save/loading/invitation/skip/audio transport |18/0 headless;18/0 native | loading-headless/ and loading-native/ |
| Genuine current paired player/world restore and unknown-source rejection |4/0; exact original typed data including source identity and all RNG | pair-final/ |
| Stuck setup guard | expected single assertion at60,007ms, raw exit1 retained | guard-timeout-strict/ |
| Finished outside-Studio guard | expected single phase assertion, raw exit1 retained | guard-wrong-phase/ |
| Independent receipt/count/source/state audit |48/0 | audit.py and audit-result.json |

The seven positive acceptance processes total580 printed passing assertions with no FAIL/SCRIPT/parse errors, and all source/harness/fixture fences true. Negative tests are intentionally failing processes, audited for the exact expected assertion; they are not counted as ordinary passing runs. Final native loading/focus and paired-save manifests exactly match current whole source. Four earlier green manifests differ only in the loading verifier's restored original line endings, proven byte-for-byte equivalent after CRLF normalization by the audit. No logical edits followed those runs.

Native loading/invitation captures and the900px missing-parent stress capture were inspected. The900px viewport is below the supported minimum and tests bounds/input rather than shipping readability. Audio checks verify transport continuity with Dummy output; no new device listening or export acceptance is claimed.

## Retained attempts and limits

Warm pre-fix baseline passed; controlled delayed publication reliably exposed the insufficient old budget. guard-timeout/ first included an extra caller sentinel after the expected assertion because GDScript resumes the awaiting caller after an assertion aborts the helper; guard_strict.gd removes that misleading sentinel and yields only the intended failure. Both attempts remain retained. Prior Store-center timeout reports remain historical evidence; the maintained current checks above close this specific fixture issue.

Fixtures use disposable private profiles/ports, never player saves. Full GPU/device, audible mix, whole-release and unrelated historical fixture acceptance remain separate. These timings were collected during concurrent checks and are not gameplay response benchmarks. No EXE/ZIP rebuild. Source publication is user-authorized; subsequent Git output establishes commit/push success.
