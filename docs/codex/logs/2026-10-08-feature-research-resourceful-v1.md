# Feature research and Resourceful — 2026-10-08

## Authority and workspace

User accepted the recommended order: Feature Store research, then Resourceful. Read CURRENT_STATE/TODO, repository workflow, Store Handoff003, Store/release design, DECISIONS, Store/map/guidance, finance and checkpoint source before edits. Branch `main`, HEAD `91ce539978b87ac0a6efe3a1e028cae5f1360f19`; shared dirty worktree retained, including previous checkpoint/Contracts/menu changes and `.codex-godot-temp`. No commit, push or export.

## Implemented

- Zero-cycle FIFO admission pays half base, rounding an odd cent upward. Confirmation explains irreversible payment and no cancellation/reordering. Only the head can receive manual Research. Live nodes require one action; no catalog/duration changes.
- Each Research action pays its freshly familiarity-discounted installment, then commits one existing productive-cycle transaction. Ownership and supply appear only on final completion. Initial optional Primitive purchases remain instant; specialty grants are unchanged.
- Full current quotes reject stale/duplicate/malformed requests. The next installment must be affordable before settlement. Queue history preserves stable IDs, admission, nominal/paid installments and completed ownership; checkpoint validation checks those against the finance journal, catalog and FIFO order.
- Resourceful costs one point for new version4 selections. Following the standing instruction to use recommended answers, the integration default was announced: preserve the half-base down payment, apply up to $100 after familiarity to the final research installment, and consume the opportunity on successful completion. Instant starter purchases consume it immediately. Positive prices reduced to zero consume it; already-free acquisitions do not. Each successful release opens the next window. Version3 preview selections remain inactive.
- Store UI exposes queue order, paid amounts, next cost and actions remaining. Acquisition guidance uses split costs and counts Resourceful at most once per current path. HUD/tutorial wording follows the new flow.
- Checkpoint rules/content revision now includes research1/traits4. Incompatible earlier bytes remain preserved through the existing recovery flow; no silent migration was introduced.

## Changed files

Runtime: `scripts/run_state.gd`; new `scripts/cards/feature_research.gd`; `scripts/studio_traits.gd`; `scripts/persistence/checkpoint_schema.gd`, `studio_checkpoint.gd`; `scripts/ui/feature_store.gd`, `feature_store_map.gd`, `gameplay_hud.gd`, `tutorial_overlay.gd`; `scripts/finance/feature_spending_guidance.gd` (all under patch-notes).

New debug coverage: `verify_feature_research.gd`, `verify_research_integration.gd`, `verify_research_ui.gd`, `research_restart_probe.gd`, `research_test_actions.gd`. Existing acquisition fixtures now explicitly perform admission followed by research: Feature Store, Store cycle, first-Studio economy, specialties, Pre-Development, spending/shopping advice, SideStreet calendar and checkpoint portfolio probes. Studio Traits expects version4. Navigation/radial fixtures received correct folder-visit indentation and explicit replacement-dialog handling; this repairs two test setup errors left by the preceding menu change.

Memory: TODO, CURRENT_STATE, DECISIONS, Store/Traits design and tracked Handoff003; this log and [evidence folder](../findings/feature-research-v1/).

## Exact checks and results

Godot `4.7.1.stable.official.a13da4feb`, isolated APPDATA/LOCALAPPDATA. [Reproduction runner](../findings/feature-research-v1/run_checks.py) invokes `Godot --headless --path <repo>/patch-notes --script res://scripts/debug/<suite>.gd`; per-suite `.command.json` and `.log` retain actual commands and exit results.

17 focused suites passed, exit0, no unexpected script errors:

- Feature research; research integration; research UI.
- Studio checkpoint; Studio Traits; Studio folder menu.
- Feature Store cycle purchase; first-Studio Feature economy; Studio specialties.
- Feature spending guidance; Store shopping guidance; Pre-Development.
- SideStreet Scope/year; Feature Store; Store navigation; Store radial map; first-game/tips.

Seven fresh processes passed: initial Studio → admission → admission inspection → constructed partial step → partial inspection → completion → completion inspection. They use the real checkpoint coordinator, separate OS profiles and a dedicated writer-lease port. Every resumed process compares the complete encoded state hash before proceeding; duplicate installment callbacks reject. The two-action entry is explicitly constructed solely for persistence/arithmetic coverage; live admissions still use one action. See `restart-results.json` and logs.

Arithmetic covers one/two/three actions, odd cents, zero, MAX_INT, changing familiarity, and unchanged earlier installments. Integration covers native release-earned familiarity, Bank loan/payroll, a research month boundary compared against an identical central finance transaction, portfolio sales, rent, credit and redraw parity. One-cent-short research rejects without using same-cycle settlement. Invalid parent/count gates, stale/duplicate/malformed requests and corrupt installment/trait provenance are covered. Hypothetical cheap/free prices exist only in tests.

Rendered command: `Godot --path patch-notes --rendering-method gl_compatibility --script res://scripts/debug/verify_research_ui.gd -- --capture`, exit0. Queue and detail captures at 1152×648 and 1280×720 retained; both detail layouts inspected. Existing native Store navigation/radial checks additionally cover keyboard focus and popup bounds. Reduced the scrollable advice footprint to keep detailed prices and controls reachable.

Initial old instant-purchase assertions failed as expected and were updated to two explicit actions and the new installment-only familiarity arithmetic; reruns passed. Navigation/radial parse errors from earlier folder-test indentation were repaired. Routine root-certificate-store warnings remain environment noise; commands classify them explicitly. `git diff --check` passed.

## Limits and follow-ups

Focused correctness/restore/UI verification only: no anti-rush balance claim, broad economy rerun, exported playthrough or final numerical lock. No employee automation. Publisher Connections remains queued separately. General Task10/Task11 exported acceptance remains open. Resourceful and research are marked complete locally at this bounded scope.
