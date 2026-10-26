# Two-parent Store integration — 2026-10-11 to 12

**COMPLETE locally at approved structural scope.** Handoff009 adopted on dirty `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. Existing concurrent edits and `.codex-godot-temp` preserved. No authored catalog/card, price, fee, duration or eligibility change. No final balance or human-comprehension approval.

## Implementation

- `feature_store_catalog.gd`: one authority for legacy `purchase_parent` and ordered one-/two-entry `purchase_parents`; validate missing/self/duplicate/type/cycle/hybrid gates and deterministic shared ancestors.
- `run_state.gd`: every named parent must be owned; queued ownership is insufficient. Sum each parent's committed familiarity under one shared 50% cap on unpaid installments. Preserve admission deposit, FIFO, exact cents/remainders, Gameplay-count and single-parent quotes.
- `startup_data_check.gd`, `feature_store.gd`: reject invalid graphs safely.
- `feature_store_map.gd`: one node, first-parent layout anchor, AND badge, all gates/credits, scrollable details and focusable cross-lane parent navigation.
- `verify_feature_parents.gd`: focused behavior, real Studio codec/campaign parity, fresh-process ownership/payment retention and two-size rendered UI.

## Verification

`run_checks.py` records exact Godot commands/profiles and exits. Godot4.7.1, isolated APPDATA/LOCALAPPDATA. Final focused/rendered suite: **65 checks, 0 failures**. Four fresh processes (`initial`, `admit`, `complete`, `owned`) exit0; exact captured checkpoint and payment/ownership state survive. Existing Store, Research, copy and startup-recovery suites pass. Retained v1–v6 probes document implementation/test repairs; v7 and rendered results are the final focused evidence.

Both [1152×648](two-parent-1152.png) and [1280×720](two-parent-1280.png) frames were inspected: visible AND badge, parent navigation and scrollable content fit. The synthetic Recorded Sounds fixture uses two existing parents; the live catalog remains unchanged. Its legacy Run deliberately lacks an acquisition quote, so the rendered frame shows “Current acquisition price unavailable”; real Studio admission/finance/codec coverage is separate in the focused checks. This does not establish a live two-parent catalog rollout or human comprehension.

Full command: `python tools/release_gate.py --godot <Godot4.7.1-console.exe> --output docs/codex/findings/two-parent-store-20261011-v1/release-gate --defer-graphical-startup --isolate-checkpoint-writer`.

[Gate result](release-gate/gate-result.json): **135/135 suites pass**, clean import/export,281-entry package audit and isolated headless EXE startup. Includes94 live/headless boundaries,138 seeded boundaries across three routes,81-step campaign and fresh-start stress coverage. Exit1 is the declared deferred graphical-startup gate, not a failing headless suite: `headless_automated_pass=true`, `automated_pass=false`, `release_ready=false`. Later [actual exported interaction](../queue-completion-20261011-v1/README.md) uses that exact EXE/PCK; it is separately scoped.

Human Store testing remains user-deferred. No commit/push or release-readiness claim.
