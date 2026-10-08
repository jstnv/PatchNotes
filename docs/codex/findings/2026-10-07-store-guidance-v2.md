# Store shopping guidance — Handoff002, 2026-10-07

**COMPLETE locally, bounded advisory implementation.** Main `b84d1a5b4e4957b044b4b52c41553cf611aff3ae` plus preserved existing worktree edits. No commit/push or export refresh.

## Implemented

- Selected current Features show their singular-parent acquisition path in purchase order. Each step carries its live exact-cent quote, productive cycle count and textual owned/locked/available/insufficient-cash state. Owned ancestors contribute zero. Gameplay-count requirements remain separate; no candidate cards or invented parents were added.
- The prospective pool includes missing ancestors and child once. Current Primitive play costs use the existing charge calculation; later Feature fees remain explicitly unknown. Acquisition cost is separate from the next-project estimate.
- The known-cost estimate includes current actual rent, all typed unpaid obligations, and scheduled payroll/Bank payments falling within the observed development-plus-setup-plus-purchase horizon. It reads immutable snapshots and calls the native Bank installment calculation. Already-issued bills are not counted again as future dues. Without pacing/schedule information, future obligations are explicitly excluded and marked unknown.
- Shortfall and unknown-cost cautions can appear together. Copy suggests considering actual settlement, never promises future cash or card draw/play, and leaves purchases to the player. A scrollable breakdown stays inside the existing selected-card surface; both supported resolutions were rendered and inspected.
- Each Store refresh requotes from current state, including after productive purchases and settlement. Purchase eligibility, quotes used by transactions, ownership, cycles and RNG remain in the original transaction paths.

## Verification

Fresh Godot4.7.1 import and **10 focused suites pass**: new shopping guidance, existing spending guidance, Feature Store, navigation, radial layout, cycle purchase, candidate retention, Bank finance, Employees and Lease. Candidate retention covers144 native hands/eight seeds. Focused Bank/Employees/Lease suites report207/70/15 checks respectively. New constructed fixtures cover two missing Store steps, missing Primitive parent, owned parent, independent node, unmet count gate, distinct legacy/current funding, mid-chain rent, unknown fees and no-history disclosure.

A native finance fixture accepts payroll and a Bank loan at an odd cycle. Guidance projects six payroll/Bank dues and seven$515 rents over its horizon. Another boundary creates$571.67 unpaid rent/payroll/Bank bills and verifies those issued amounts are separate from future dues. Fixtures are accounting tests, not claimed played income routes. Existing tests retain zero-cycle starter purchases, one-cycle later purchases, earned familiarity, rejected/duplicate safety and advisory noninterference.

Both1152×648 and1280×720 renders show the missing/owned-parent paths, reachable buttons and scrollable cost disclosure without color-only meaning. The initial new capture selected before deferred layout completed; the test now waits for layout and explicitly requires a visible selected popup before accepting/rendering it.

Five purchase/offer method bodies are unchanged from HEAD: `purchase_feature`, `purchase_starter_feature`, `purchase_primitive_reserve_feature`, `get_feature_store_offer`, `get_primitive_reserve_offer`. Diff whitespace check passes. Known root-certificate warning is environmental. A mistaken verifier filename was corrected to the existing cycle-purchase suite, which passes; its failed invocation is preserved separately.

[Exact source hashes and suite list](store-guidance-v2/verification.json); command JSON/logs and renders are in the same folder. Runtime edits: `run_state.gd`, `finance/feature_spending_guidance.gd`, `ui/feature_store_map.gd`. Existing guidance verifier updated for the now-visible locked-path quote; new `verify_store_shopping_guidance.gd` adds acceptance coverage. Preexisting runtime edits remain intact.

## Limits

This is a current conditional quote, not a fixed future transaction sequence or mandatory reserve. Future receipts, optional actions, longer development and unapproved later-card fees remain excluded/disclosed. No new price, card, fee, balance gate, multi-parent system, full-suite certification, human playtest or exported acceptance is claimed. Contracts C1–C5 and checkpoint integration remain separate queue items.
