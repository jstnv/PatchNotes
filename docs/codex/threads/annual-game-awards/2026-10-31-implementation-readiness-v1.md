# Annual Game Awards implementation readiness — 2026-10-31

Status: **source/UI integration audited; canonical adoption remains gated by the current design handoff.** This packet is implementation preparation, not gameplay approval, a candidate adoption or a completed ceremony.

The user asked to wait five minutes, then check the to-do list for ceremony implementation and ensure the existing menu design is used. Wait began2026-11-01 04:39:26 UTC; the first queue read was04:44:40 UTC. Branch `main`, HEAD `49d769235474a880a73d996499cefa72beec63e5`. Existing JooceBox splash and concurrent Awards design edits were preserved. [Pinned sources](2026-10-31-readiness-source-v1.json).

## Authority and remaining handoff

[Design](../../design/annual-game-awards.md) directs seven awards, December Week2 current-year cutoff, nominees' Fans, winners' additional Fans and next-successful-launch Awareness. It explicitly requires the handoff to resolve these fields before canonical adoption:

1. Whether active Studios with no current-year release can enter Studio awards.
2. Gross positive yearly Fan additions versus net yearly Fan change; treatment of founding grants and other award grants.
3. Exact score/tie order; units sold cannot affect GOTY, including ties.
4. Per-nomination/per-Studio stacking and explicit ACTIVE/TRIAL Fan/Awareness amounts and caps.
5. First eligible year and migration for saves already at/past the cutoff; no fabricated historical awards.
6. Exact first/later skip, Settings and saved-stage resume contract.
7. Week2 command ordering and presentation deferral necessary to preserve Studio-only Continue.

Numeric trial selection is authorized; that permission does not by itself settle the structural OPEN choices above. Keep these decisions explicit in the adopting handoff. This packet does not choose or approve them.

## Source findings and critical integration seams

- `run_state.gd:1890–1970` publishes committed productive finance/sales/Fans and emits calendar_changed while still publishing. `gameplay.gd:359–362` drives the rival scheduler. `rival_world.gd:170–226` advances all rivals and post-boundary launches, settles engine royalties, then publishes world.cycle. Adjudication belongs at a shared committed world/command seam, not an independently timed UI listener.
- Player launch is a separate zero-cycle transaction (`simulation/launch_settlement.gd:43–61`, `gameplay.gd:479–531`), while rival post-boundary launches may already happen inside the tick (`rival_world.gd:262–298`). A trigger attached only to the productive calendar signal can exclude a same-Week2 player launch while including an equivalent rival launch. State the actual snapshot order and test both.
- Gather actual owner runs from world.player and world.studios. Use RunState release IDs and immutable metadata: `release_year`, `release_cycle`, `sales.review_tenths` and `metadata.review.cores` (`run_state.gd:1228–1301,1355–1359`). world.live_releases alone lacks complete player/year/Core provenance. Never substitute current sales, unreleased projects or historical1977 archives.
- Monthly Fan rows carry distinct gained/lost/net (`fanbase/studio_fanbase.gd:64–94`). Their full replay is validated at135–177 and `studio_checkpoint.gd:435`. Directly incrementing Fan totals would break legitimate Continue. Awards require a versioned, chronological receipt stream included in Fan validation and launch-Fan checks.
- Existing Promotion banks are consumed only by committed successful launches (`run_state.gd:1261–1262,2124–2140`), with additive Awareness assembly at `awareness/primitive_awareness_calculator.gd:31–41`. However, `studio_checkpoint.gd:500–535` currently proves those grants solely from Contracts. Reusing that bank requires explicit award provenance and same-cycle ordering; never counterfeit Contract receipts.
- Global immutable results, reward receipts and stage progress need a world checkpoint schema/codec extension (`market/rival_world_checkpoint.gd:352–428,432,746`). Continue is Studio-only (`checkpoint_coordinator.gd:188–229`, `campaign_session.gd:217–218`); an overlay must not silently create durable production checkpoints. The adopting contract must say how pending mid-production awards reach a safe Studio presentation and how quit/reload resumes.
- Preserve exact historical opening certificate bytes/generation identities and the engine guard (`market/rival_opening_loader.gd:7–24`). Any exact prior-build compatibility needs a genuine old save fixture, not blanket source acceptance.

## User-directed shared menu contract

Use the actual FolderUI.SurfaceHost and bounded FolderPanel surface (`ui/folder_ui.gd:6–38`) with `workspace_theme.tres`: Chakra Petch heading/buttons, Plex body/metadata roles, existing chamfers, colors and primary buttons. Use shared MenuTransitions ownership; do not introduce a second design system. FolderUI.header supplies a dismissible Back, so the mandatory ceremony needs a matching title row without that Back action.

Ten stages: intro, contenders overview, seven award screens, final results. Keep Next fixed bottom-left outside scrolling content. Counters are presentation only: rank from frozen authoritative values first, finish exactly on those values, display each metric's correct scale, visibly explain equal-score tie order, and leave missing podium positions empty. Overview and final derive from that same snapshot.

Prefer a Gameplay-owned overlay preserving the active Studio state/focus/visibility, analogous to guided tutorial ownership. Do not route it through StudioPhase's dismissible destination stack. Gate Escape/controller B, pause, hidden footer access and Developer Tools F8; F8 currently opens independently (`developer_tools.gd:43,94`). Existing Settings dictionary validation is strict, so a skip setting needs a narrowly tested old-preference migration and synchronized committed/draft UI state (`settings/demo_settings_store.gd`, `ui/demo_settings_menu.gd:157`). These are implementation constraints, not approval of the unresolved skip policy.

## Proposed extraction/verification order

1. Resolve/version the handoff fields above and pin the current implementation baseline.
2. Pure deterministic ranking and reward-plan module, with zero/one/two/three-plus candidates, tied scores, same-Studio nominations, no-sales GOTY and overflow tests.
3. Global annual ledger plus chronological per-owner Fan/next-launch receipt integration; verify current/old saves, original finance/RNG/history, failed-then-successful launch and once-only awards.
4. Shared live/headless world command trigger, including December Weeks1–4, player/rival zero-cycle release order and migrated clocks.
5. Shared-style ceremony/controller and preference migration. Verify all ten stages, exact counters, double activation, Escape/B/F8, skip, quit/reload, teardown, resize and animation bypass at1152x648/1280x720.
6. Cold Continue and actual native ceremony acceptance; human pacing/final balance remain separate. Keep failed attempts and do not claim readiness from a prototype alone.

Two independent read-only audits covered world/reward provenance and shared UI/Settings. No code changes, simulations, native tests or rewards were performed for this readiness pass. No commit, push, automatic follow-up or external-chat dispatch.
