# Buyer identity and fan gain options v1

2026-10-06. **OPEN design choice; no numerical rule or implementation approved.** The current sales ledger stores copies, not buyer identities. A legal route capture can verify units and fan arithmetic, but cannot measure which purchasers already follow the studio or bought another title.

## Choices

1. **Keep a bounded unit proxy for the demo (recommended for discussion):** Continue using per-title cumulative earned units and reserve up to its launch fan count before converting any units to new fans. This is the `bd450a9` branch's current provisional behavior. It is deterministic, cumulative, and cheap to explain, but can undercount new buyers when most fans do not buy; simultaneous titles may each reserve the same studio fans. Call it an *eligible-unit proxy*, not observed unique people.
2. **Convert all earned units:** Simplest and generous, but counts repeat purchases and shared audiences as new people. It compounds faster and weakens the meaning of a fan count. The old Task 6 study used this only as an upper bound.
3. **Model buyers explicitly:** Add a studio audience/returning-buyer allocation and shared cross-title ownership. This could make gains and losses conceptually precise, but creates a separate unapproved sales model, persistence state, and interaction rules. The existing branch does not provide those identities.

The rent-era legal route's third release (Review 6.1) has 96 shadow fans at launch and 677 recorded Month 1 units. Under the branch linear candidate rate of 4.4%, reserving all 96 gives `floor((677−96)×0.044)=25` eligible fan gains. Converting all 677 gives 29. Reserving 14 or 29 units as illustrative 15%/30% shares of launch fans gives 29 or 28. Under the square-root candidate the corresponding values are 34, 40, 39, and 38. These are fixed-sales arithmetic examples, not observed returning-buyer rates or branch runtime results. Source and route limits: [shadow v1](2026-10-06-current-route-shadow-v1.md).

## Decision needed later

Choose what “fan” represents in this demo: an approximate audience count derived from copies, or distinct people tracked by an explicit buyer system. If the bounded proxy is retained, decide whether the current full launch-fan reserve is suitably conservative and how concurrent titles share that reserve. The forthcoming branch replay can test the arithmetic and player-facing clarity; it cannot settle the true returning-buyer share. Keep the 5.0-neutral rule regardless of this choice.
