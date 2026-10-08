# Store guidance implementation session — 2026-10-07

User reported more tasks in the internal TODO. Read CURRENT_STATE/TODO first; identified new READY Feature Pools Handoff002, read approved design/local brief/current guidance and refreshed Bank/payroll/Lease sources. Inspected branch/HEAD/status/diff before editing: main b84d1a5b4e4957b044b4b52c41553cf611aff3ae, extensive preexisting edits preserved. No overlapping implementation, worktree cleanup, commit, push or Drive change.

Changed runtime: `patch-notes/scripts/run_state.gd`, `scripts/finance/feature_spending_guidance.gd`, `scripts/ui/feature_store_map.gd`. Updated `scripts/debug/verify_feature_spending_guidance.gd`; added `scripts/debug/verify_store_shopping_guidance.gd`. Added findings/evidence in `docs/codex/findings/store-guidance-v2/` and `2026-10-07-store-guidance-v2.md`; updated TODO/CURRENT_STATE/Store design and local handoff status. `.codex-godot-temp` untouched.

Checks use saved Python/Godot paths in `findings/store-guidance-v2/run_checks.py`. Exact per-command argv/results are adjacent `.command.json` and `.log` files:

- `run_checks.py import`:exit0.
- `run_checks.py verify_store_shopping_guidance verify_feature_spending_guidance verify_feature_store verify_feature_store_navigation verify_feature_store_radial verify_feature_store_cycle_purchase verify_candidate_retention verify_bank_finance verify_employees verify_trait_lease`:all10 existing/new named suites pass across the recorded invocations. Final new suite rerun passes after copy refinement.
- `render.py verify_store_shopping_guidance`:exit0 with1152×648/1280×720 missing-parent/owned-parent and scrolled-detail PNGs; inspected actual images. Initial capture timing weakness fixed with layout wait and explicit visible-selected-popup assertion.
- Source audit confirms five purchase/offer methods exactly match HEAD; source hashes saved in verification.json. Current runtime retained prior employee/trait changes outside this scope.
- `git diff --check` for edited runtime/existing verifier:exit0.

During test development, initial synthetic fixtures omitted required cash initialization and assumed a nonexistent three-node catalog chain; corrected to native initialization and actual two-step Save Files→Branching Nodes. No catalog/runtime rule changed to satisfy a test. Mistyped `verify_primitive_reserve_store` invocation failed because that file does not exist; replaced with actual `verify_feature_store_cycle_purchase`, which passed. Root-certificate warning remains environmental.

Result: Handoff002 complete locally as advisory-only UI/data projection. All typed unpaid bills and scheduled payroll/Bank within known horizon included; no-history future horizon explicitly unknown. Unknown fees/optional actions/future revenue disclosed. No new gameplay numbers/eligibility changes, broad Task2 rerun, full-suite/export certification or human playtest. Contracts C1–C5 and full checkpoint integration remain separate queued work.
