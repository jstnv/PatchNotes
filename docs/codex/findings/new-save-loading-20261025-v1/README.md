# New-save loading and neutral first Studio — 2026-10-25

Status: implemented locally; player Create now uses the existing loading component and reveals the optional tutorial invitation after the real Studio checkpoint. It shows Studio name and 1980/Month1/FirstHalf, consumes transition input and duplicate Create, and preserves the same music transport/time map. Direct synchronous fixture creation and ordinary Continue retain their contracts. The inline StoreHint nodes and unsolicited first-Studio shopping tip are removed; optional Store purchases remain available and the existing below20-Scope warning is neutral.

## Source and receipts

Shared dirty main, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. Raw immutable sources/commands/logs/captures are at `C:/Users/64jus/AppData/Local/Temp/pn-new-save-loading-20261025-v1`.

- `red-v2`: preceding runtime fails the real Create-signal loader assertion. Earlier `red` is a retained harness parse error, not behavioral evidence.
- `first-green`: new-save14/14; canonical source unchanged during that run.
- `regression-v1`:12 of13 requested suites pass on the frozen source: card motion, Continue157 checks, Store navigation/radial, first-game/tips, historical-v2 first-Studio economy, main history, new-save14, primitive initialization, specialties, Traits and folder navigation89. Tutorial was incorrectly run with an answered-onboarding seed although its first assertion requires a new profile; retained failure. Separate unseeded tutorial115/115 passes in the Employees model-transaction snapshot, with the same onboarding runtime. Canonical-unchanged is false on these longer matrices because subsequent Employees work began after copying; their copied projects remain immutable. These are passing receipts, not an uninterrupted current-source gate.
- `native-new-save`:14/14 using a real rendered window/audio transport; loading/invitation/Studio captures inspected at1280×720. Human listening is not claimed.

Changed runtime: `gameplay.gd`, `ui/continue_loading.gd`, `phases/studio_phase.gd`, `scenes/phases/studio_phase.tscn`, `ui/gameplay_hud.gd` and named predecessor source entries in `market/rival_world_checkpoint.gd`. Debug helper `ui_test_actions.gd` now awaits real new-save completion and explicitly skips optional practice in ordinary UI fixtures; affected signal-driven fixtures updated. The existing first-Studio economy oracle explicitly uses roster2; current roster3 remains covered independently.

No scoring, Store price, purchasing/cycle or Continue-boundary change. No commit/push or whole-release claim. Final integrated current-source acceptance/package follows the broader unattended task.
