# GDScript warning cleanup — 2026-11-05

Branch `main`, HEAD `2ad3cf2b2bb63d324a970b10864b0f69843dcb1a`; concurrent pre-existing worktree edits preserved. This is a limited debug-fixture cleanup, not a complete warning audit.

The captured Godot 4.7.1 debug editor scan at `sims/gdscript-warning-inventory-20261105/scan.stderr.txt` contains 241 distinct warning/location pairs before its watchdog stopped a debugger loop following a stale debug script parse error. The scan is partial. It identified 148 integer-division locations, 31 shadowing locations and 16 unused-variable locations. Runtime arithmetic and public/save fields were deliberately left unchanged; many warnings remain.

Changed four debug fixtures only:

- `patch-notes/scripts/debug/banking_restart_gap_probe.gd` — renamed the setup block's shadowing `run` local.
- `patch-notes/scripts/debug/checkpoint_portfolio_probe.gd` — renamed the starter block's shadowing `prior` local.
- `patch-notes/scripts/debug/contract_challenge_restore_probe.gd` — renamed two cold-restore locals shadowing later declarations.
- `patch-notes/scripts/debug/verify_sales_revenue_hud.gd` — discarded the unused second fixture's return value while retaining the call and its side effects.

Focused verification: copied the four exact current fixture files into `sims/gdscript-warning-inventory-20261105/`, then ran each with Godot 4.7.1 `--headless --debug --check-only` using `sims/feature-trail-fix-20261105/combined-project` and a private profile. All four exited 0. None emitted the five targeted warnings captured in the prior scan. The sales HUD fixture still emits four unrelated enum warnings at line 93; warnings in dependencies also remain. Compiler checks do not execute the fixtures, so runtime behavior was not independently re-run for these renames.

The original partial scan and its failed parse/debugger-loop evidence are retained. Real player profiles and saves were not used. Further cleanup requires a bounded inventory and identity/compatibility planning for runtime files; do not silence integer-division warnings by changing arithmetic or global warning settings.

## Follow-up

After concurrent Feature Store work was released, renamed four additional shadowing locals in `patch-notes/scripts/debug/capture_store_cones.gd` and `patch-notes/scripts/debug/verify_store_hud.gd`. Focused isolated Godot 4.7.1 `--headless --debug --check-only` passes for both, with none of those four targeted warnings. These account for all debug-local unused/shadow warning locations in the retained partial inventory, not necessarily all such warnings in the project.

Behavioral checks on the same isolated combined-project snapshot: the edited `verify_sales_revenue_hud.gd` passed 870 checks, 0 failures; Godot reported 20 ObjectDB instances leaked on exit. `verify_store_hud.gd` could not complete: its legacy pending-queue fixture failed, then accessing the absent Store `_map` raised a script error, and the process was stopped after 35 seconds. The exact output is retained in `sims/gdscript-warning-inventory-20261105/store-hud-behavior.*.txt`. This old Store fixture is not evidence of current UI acceptance. No behavioral run was performed for `capture_store_cones.gd`.

## Store HUD fixture reconciliation

The failed fixture used retired behavior: it tried research on the Public engine, opened the Store without a proprietary Engine browser selection, and asserted obsolete Store header/debug/starter controls. The current Store correctly refuses to open on that path. Retained the old verifier as `sims/gdscript-warning-inventory-20261105/verify_store_hud-legacy.gd` and retained the failure logs. Replaced only `patch-notes/scripts/debug/verify_store_hud.gd` with narrower current-behavior coverage: six released games, a real proprietary engine, a queued Controller implementation, opening through the engine browser, visible sales data and Store labels, in-viewport controls, browsing state digest, and completion of the queued action. It no longer claims to check removed header/debug interactions.

Exact edited verifier SHA-256 `49feeeaedc6539bfe01ac8a17f1b3f17bb5d5d4a083c88f68cb8f238db83a007` was tested as an identical isolated copy. Native Godot OpenGL: **50 checks, 0 failures**, including synthetic pointer activation at four viewport sizes. Headless: **50 checks, 0 failures**, using the button signal because a headless pointer trial did not activate it (four failures retained in `store-pointer.*`); headless reported 20 ObjectDB instances leaked at shutdown. Outputs are `store-native-final.*` and `store-headless-final.*` in the inventory folder. The native fixture verifies generated input, not a human or packaged-build run.

At that test fence, isolated and shared sources matched for `studio_phase.gd` SHA-256 `ab9dd0d71f4ada571f166ef489f280e90f7c8eefca80625d6684f04c89f1347f`, `feature_store.gd` `e21c09cfa262d1982c537291ade7a64eaf062c9475dc6a4a33cb15797e6e7c53`, and `run_state.gd` `fff4ebe0b16716ed49e2836821eeb2a5f7723e4f88fe6d1b858fcda77cac882e`. The inherited debug sales fixture differs only in the prior unused-local cleanup; other combined-project files are not asserted identical. All runs used isolated profiles and preserved player saves.
