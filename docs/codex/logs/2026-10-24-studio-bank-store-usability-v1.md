# Studio, Store, priorities and Bank usability — 2026-10-24

## State and authority

Direct user implementation request in this chat. Branch `main`; HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. Frozen starting inventory retained1734 status entries and130 tracked changed files. Preserved inherited edits and `.codex-godot-temp`; one canonical implementation at a time. No commit/push. [Plan and bounded rulings](2026-10-24-studio-bank-store-usability-plan-v1.md).

## Changed files and behavior

The [complete63-path runtime/test delta](../findings/usability-20261024-v1/adoption-delta.json) is relative to the actual starting checkout, not the much older Git HEAD. Main groups:

- `scripts/studio_traits.gd`, `phases/main_menu.gd`: version9 uncapped choices, negative accounting, fixed balance/cash bonus and scrollable selected/available/Overview lists.
- `ui/contextual_tip.gd`, `ui/gameplay_hud.gd`: persistent tips, explicit dismissal/reopen and preservation through transient animation.
- Priority allocation classes, Design/Alpha/Beta scenes/controllers, Contract, Predevelopment and Specialist UI, chart/overlay/new `priority_budget_feedback.gd`: 10% new-command floor, sliders/pie, `X/100`, shared zero-start red pulse. Simulation/Contract/employee command gates use the same rule; saved historical weights retain their meaning.
- Store/map: concise stats/play cost, button-only acquisition prices, hover familiarity, wrapping one/two-parent navigation, no enclosing cone backgrounds.
- BankLoan, finance journal, finance UI, checkpoint schema/adapter/world codec and five frozen `persistence/pre_usability/` files: version2 adjusted recovery quotes, one lifetime cash-poor facility, shared installment capacity, exact debt/history replay, active-loan selection and named P4 predecessor migration.
- Maintained verifiers updated for the deliberate rules/UI change; five new usability verifiers. The local `all_checks.py` driver can assign a separately guarded private test port. Historical digest files remain untouched.

Relevant system documents, DECISIONS, CURRENT_STATE, TODO and this log record the new current scope. Concurrent Crown/AI design entries were preserved; their candidate gameplay was not adopted.

## Exact checks and results

Raw root: `C:/Users/64jus/AppData/Local/Temp/pn-usability-20261024-v1/`. Final runtime identity `6b39be120a228132e8cd78b6c00194fc95f734430ee485901d3479d20b61d315`. [Source/evidence/commands](../findings/usability-20261024-v1/README.md).

- `work.py freeze` froze the starting project, branch/HEAD/status; `freeze_compat.py` generated the five source-pinned P4 reader copies before expansion.
- RED→GREEN Traits, priority, Store and Bank probes, plus reviewer RED3→GREEN0; initial compile errors and failing outputs retained.
- `all_checks.py --output .../regression-v1`:182 maintained jobs,159 passes/23 old-expectation or route failures retained. Source is immutable within that run; canonical changed intentionally during independent follow-up work, so that run is **not** reported green.
- `continuation-v1/v2/v3` repair and recheck changed expectations/routes. The original historical action digests remain exact. `continuation-v4` exposed a strict fixed-port wrapper mismatch; retained as failed tooling evidence.
- `all_checks.py --output .../final-focused-v1 --port 47735 --tests verify_feature_parents verify_gameplay_hud_overlay verify_first_game_and_tips verify_pause_menu verify_research_ui verify_campaign_live_parity verify_usability_bank verify_usability_persistence verify_usability_traits verify_usability_priorities verify_usability_store verify_bank_integration verify_store_shopping_guidance verify_priority_influence verify_publisher_support verify_studio_checkpoint verify_checkpoint_runtime`: **17/17 PASS**, canonical unchanged. Bank38/0 and two-route native/headless106-boundary equality included.
- Across these explicitly source-pinned receipts, **182/182 maintained suites have a passing result**. [Machine-readable per-suite provenance](../findings/usability-20261024-v1/coverage.json); this is not a single all-green final-source full run.
- `final_audit.py`: current/predecessor persistence23/0, separate OS-process cold18/0, review regressions12/0, native52/0 with14 captures at both supported sizes. Every final snapshot input remains unchanged. Actual old P4 compiled worlds/ownership/hands and prior EXE earned saves retain every field/RNG.
- Independent read-only reviewer confirmed the three repairs, integer v2 acceptance and no remaining important finding in the follow-up deltas.

## Limits and follow-ups

All requested implementation slices are complete locally. Bank's lifetime recovery limit and the 10% floor are ACTIVE/TRIAL, with long-term tuning and human comprehension still OPEN. Graduate/College Dropout remain alternative histories. Explicit navigation/full reference menus still manage tip context. No current release EXE export, computer-control session, clean-machine/device or human acceptance is claimed. No production player profile was written; verification uses isolated profiles and retained Temp copies of prior evidence. Existing asset-fallback/leak warnings remain in logs. Studio-only Continue, scoring, publisher terms and AI policy remain intact.
