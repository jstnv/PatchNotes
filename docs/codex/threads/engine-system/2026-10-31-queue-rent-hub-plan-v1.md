# Rent and Studio hub queue implementation plan

> Execute inline with executing-plans/TDD; one final read-only reviewer. User opts out of questions and authorizes all approved queue work. Preserve dirty shared checkout and both temp directories. No commit/push/export inferred.

**Goal:** complete the two newly queued implementation items, then reconcile remaining runnable acceptance without adopting DESIGN/OPEN values.
**Architecture:** stored immutable Studio rent remains authority; widen current validation to approved old/new amounts, centralize only new-Studio rent. Retain MenuTransitions as the single motion owner; Studio hub has one root/companion/destination state, never multiple live views.
**Tech:** existing Godot4.x, FolderUI, exact-cent finance/typed checkpoint, headless simulation then native controlled scenes.
**Specs:** TODO2026-10-31 entries, economy-banking rent ruling/DECISIONS, ui-design-system root/companion/bottom-entry ruling, associated two intake logs.

## Review focus

- Existing rent/bills/loans/RNG remain byte-exact after restore; traits cannot forge mismatched rent.
- New300/315 settlement, signed arrears and three-rent Bank thresholds agree with creation/UI.
- Rapid group/Back/destination switching and resize/teardown leave exactly one input owner; bypass is synchronous.
- Destination Back/close/Escape retain selected group and valid focus at both sizes, including Store, Engines, Employees, Finances and production setup.
- New/old save paths and canonical1977 opening remain validated without fabricated histories or broad source bypass.

## Task1 — prospective rent
- [x] Capture genuine52a prior player/world and normal-start finite-policy comparison before changes.
- [x] RED new300/315, old500/515 hydration/settlement and exact quote tests.
- [x] Update finance create/validator, Run creation, trait-checkpoint cross-check, new Studio preview and help/trait copy. Bank already derives actual rent; preserve algorithms. One exact world source predecessor if needed.
- [x] GREEN rent/arrears/quotes/cold save and native creation/finance, genuine old world, normal-start matched comparison; retain failed cases.

## Task2 — Studio hub
- [x] Read current source and exact transitions/FolderUI APIs; record bounded interfaces before implementation.
- [x] RED layout/navigation/input-state tests, then integrate persistent left root/companion and shared bottom destination motion/Back normalization.
- [x] Native1152/1280 captures, rapid switches/resize/Escape/controller/bypass/focus, free-state/RNG checks and maintained fixture reconciliation.

## Task3 — acceptance and closeout
- [x] Re-read latest TODO for newly approved handoffs; inspect exact scope before any additional adoption.
- [x] Resolve runnable legacy UI fixtures and Engine remaining automatic checks; preserve human/device/design/final-balance limits.
- [x] Final source-pinned reviewer/verification, minimal fresh-read TODO/design/state updates and dated session log.

Ruling: skill commit/worktree steps are superseded by shared-checkout preservation and the user's task authorization. Keep evidence/ledger locally; do not delete the plan. No background automatic checks are scheduled.

Task1 in progress:21 RED→GREEN plus47 rent/legacy/arrears checks pass; genuine52a world/cold round trip passes. Fixed frozen comparison fixture outdated accessor (v1/v2 failures retained); v3 produces two genuine normal-start two-release8-cycle controls, new rent saves exactly80000 cents each with identical releases/RNG. Pending actual loan commit/native rent/UI regression coverage. One source-pin insertion line break was corrected after retained parse failure; original old source aliases remain. No commits.

### Task2 interface decisions after source inspection

Create `scripts/ui/studio_hub.gd` (Control, no global class): owns root/clip/group layout and latest-request companion switches, `add_group(id,title) -> VBoxContainer`, `select_group(id,focus)`, `selection_changed(id)`; receives one existing MenuTransitions instance via `motion`. Root buttons remain live while companion buttons are temporarily disabled. Add `MenuTransitions.slide_panel/finish_panel` for owned companion animation, and `push_from_bottom(view,focus,closed,bottom_global_y)` alongside existing horizontal push/pop; frames retain the axis/distance and teardown restores input. Global automatic entrances skip managed screens.

Modify StudioPhase to retain group membership and existing action handlers, add `_hub`/`_hub_motion`, use group containers in `_menu_panels`, and `_present_destination` / deferred group return so old close signals animate down once. Extend the existing navigation stack for nested review/finance paths, not gameplay state. Bank keeps CanvasLayer authority but its dialog is the animated Control. Standardize Back in existing headers (Store, Market, Publishers, Summary, Contract, Predevelopment, Finance; Employees/Rivals/Engines already use FolderUI Back). Read each exact source before changes and snapshot newly touched files. Existing group fixtures will be reconciled to root-stays-visible semantics rather than preserving stale hidden-root assertions.

Task1:51 checks in rent-full-v4 pass, both actual loan commits pay arrears once and a second facility is rejected. Rent compile/source pin break and inaccurate cash-only old-settlement assertion were retained then corrected (real sales also settle at that boundary). No economic behavior was altered to satisfy fixture errors.

Task2 evidence checkpoint: initial missing-Hub/shared-axis RED→GREEN;29 route checks and70 actual Gameplay pointer/keyboard navigation checks pass.13 actual Bank/back-target/reopen/normal overlay checks and91 complete native destination checks (all11 screens, both sizes) pass. Native header/companion stale-minimum layout and Contract3305px panel expansion were corrected. Root screen layout fits after owned motion, global automatic entrances skip managed screens; Back targets align at(32,phaseTop+28). Bank has fixed header/scrolling body and preserves HUD. Publishing notices now mount in visible hub space.

Final review by rent_hub_review (read-only, no tests) found publisher-notice consumption under hidden Layout and raw Escape during input lock. Tests: publisher-notice visibility RED; direct destination _input dispatch reproduces four cancellation failures, while the initial ordinary Input.parse event path did not reproduce those. Shared viewport weak-owner guards now block unsafe input and handle explicit B;10 direct callback tests GREEN with0 engine errors. Frame metadata getter errors were retained then fixed with has_meta. No declined-to-judge implementation rulings or deferred reviewer minors; policy/balance/human/device outside review.

Legacy fixture reconciliation: menu-navigation stable named owner, correct group visits/node-ID Back and transition waits; Search reopens newly mounted Production group. Predevelopment explicitly stages only the new Save Files addition, pays one configuration cycle, returns from launch Review before using dashboard controls, waits for cancellation, checks actual UI priority distribution and chooses a legal current-budget hand. Original bodies/assertions otherwise retained; final predevelopment, Search38 and broader menu navigation pass. Initial fixture typo/timeouts, failed assertions and parser/metadata receipts are retained. No changes to gameplay rules to fit those tests.

Completion:17 maintained verifier names have passing receipts on unchanged production code, final51 rent and91 native destination checks pass, reviewer fixes are RED→GREEN and final old world is exact. Finance UI124 and integration/ledger explicit old-rent controls pass. Broader unapproved/manual/Engine career and clean4.4-import gates remain OPEN as the dated log states. No commit/push/build.
