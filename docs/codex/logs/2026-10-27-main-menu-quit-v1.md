# Main Menu Quit confirmation —2026-10-27

User requested confirmation before quitting from the Main Menu, with `Don't delay your releases too much` below the question. Clear small task under the standing no-input direction; reuse the existing themed confirmation rather than introduce another menu system.

Baseline `main`, HEAD `f3e0f2b5d35270c879327bc297b389748571feb4`, runtime `e3b0d13708d22ce1755a99012dad6a6fbdc13cb5a4a28f47e6734d3a2a327421`. Existing dirty work and `.codex-godot-temp` preserved. The pre-existing Gameplay diff was its themed-dialog constructor; that remains. No commit, push or new player EXE/ZIP.

## Implementation

- `patch-notes/scripts/gameplay.gd`: title Quit and title window-close now show **Are you sure you want to quit?**, with the exact requested joke below. Shared heading/body/animated panel and explicit Quit/Cancel are reused. Cancel is focused; Escape and the header× cancel. A small shared presenter resets the heading/body for each context. Studio save waits and non-title safe quit/rollback decisions retain their previous behavior.
- `scripts/market/rival_world_checkpoint.gd`: add only the exact preceding runtime to the existing quit-presentation/current-content pair. Ordinary field, finance, catalog, player/rival revision and RNG validation remain. No general source bypass or content migration.
- `scripts/debug/verify_main_menu_quit.gd`: actual title button, close notification, question/joke, bounds, dismissal, unchanged save metadata, supported viewports and real confirmed-exit watchdog.
- Curated `tools/fixtures/main_menu_quit_predecessor.json`/provenance preserves the actual preceding source's typed player/world snapshot. Fixture SHA `ca0b356b3201cf5ca47c0f7fe7596933f24f6c016ff6ebc344ffd955af9070cb`.

Runtime after implementation: `700d6a166649a7487ecc2abd87655435a69dfcdcaea4c5e6d09278abdc31bbee`. Comparison to the preceding source manifest changes exactly Gameplay and the world compatibility entry among runtime files. Shared UI design, CURRENT_STATE and TODO updated.

## Exact checks

Runner: `python docs/codex/findings/main-menu-quit-20261027-v1/run.py <fresh-label> <script> [--native|--confirm|input output]`, using Godot4.7.1 console and isolated profiles/ports. Full commands, source hashes and output are in [verification.json](../findings/main-menu-quit-20261027-v1/verification.json).

- `before ... verify_main_menu_quit.gd`: **RED**, real title Quit bypasses confirmation and exits. Retained failure, no production patch before this observation.
- `headless-final ... verify_main_menu_quit.gd`: **60 checks PASS**.
- `native-final ... verify_main_menu_quit.gd --native`: **62 checks PASS**, actual window/render1152×648 and1280×720. Both final captures inspected; full heading/joke fit. Initial capture setup ran before startup settings had applied; corrected setup resizes after one frame and asserts actual dimensions. Initial receipts/captures retained separately.
- `confirm-final ... verify_main_menu_quit.gd --confirm`: **9 checks PASS**, actual confirmation signal observed and process exits0 before its one-second failure fallback.
- `recovery ... verify_checkpoint_recovery_ui.gd`: **64 assertions PASS**; existing rollback warning, Cancel, modal replacement, failed-save and recovery behavior retained.
- `cold-before ... verify_world_restore_file.gd <prior fixture> <output>`: expected **RED**, source guard rejects the new runtime before the exact predecessor entry.
- `cold-after ... verify_world_restore_file.gd <prior fixture> <output>`: **7 checks PASS**; all persisted player/rival/history/ownership/finance/RNG fields survive, unknown sources and older player/rival rule pairings reject.

Native/scripted controls and OS-close notification handler are checked; this is not physical Alt+F4, a new exported build, audible acceptance or a whole-game gate. Existing unrelated resource-leak warnings are retained; final runs have no script/runtime errors. Final whitespace check is recorded in the findings.
