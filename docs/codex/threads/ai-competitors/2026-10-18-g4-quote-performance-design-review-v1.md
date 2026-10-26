# G4 hand quote performance — design review, 2026-10-18

**Status: DESIGN review.** This record selects a candidate for further review, not an approved gameplay rule, ACTIVE/TRIAL value, implementation queue or population CPU limit. It supplements the [earlier current-hand quote review](2026-10-18-g4-current-hand-quote-design-review-v1.md) and uses the [bounded performance finding](2026-10-18-g4-quote-performance-finding-v1.md).

## Recommended direction

Keep an **exact, read-only current-hand cash quote** for visible Design/Alpha four-card selections as the G4 interface candidate. Prefer the private v5 implementation pattern for further review: group identical exact prices within the observation; calculate next-cycle released-game settlement and Fanbase plan once; then run the existing cost-dependent finance planner separately for each distinct price. No quote result is cached across actions or cycles. The normal productive-cycle commit path remains authoritative, and a quote does not guarantee card production/refill, future solvency or final AI selection.

The current v5 private variant matched all 560 v3 quotes and sampled actual receipts, four fresh legal first releases, maintained two-rival world behavior, and eight-rival final state/RNG/release/save payloads. Its four route observation measurements passed the provisional 1.5-times v1 screen. Repeated eight-rival elapsed-time measurements were noisy; the nearby control/candidate pair exceeded the provisional 1.5-times population screen. This evidence supports continued development of v5, **not canonical adoption**.

## Required gates before an approved implementation handoff

1. Specify unavailable quote reasons and verify low-cash/arrears and blocked-cycle states reached through legal actions; compare v5 against the normal exact preflight and receipt, including representative unselected alternatives.
2. Measure a stable two-rival and population-cap observation/world budget under controlled host conditions, with median/p95, process CPU or adequately repeated elapsed results, save bytes and memory. Set the numerical acceptance limit explicitly. Keep bad runs; do not choose a favorable pairing.
3. Reconcile the two-file v5 delta against current canonical source, especially `run_state.gd`, then run affected finance, sales/Fanbase, checkpoint, replay and native/live-path checks. The private source must never replace the canonical project wholesale.
4. Separately select and test a benefit-aware legal hand policy. The quote interface alone does not improve rival Reviews; cheapest-affordable alone was rejected by the preceding study.

**Alternatives retained:** v3 computes 35 full preflights per hand and was slow; v4 exact-price memoization preserved behavior and improved first-release observations but was still slower at eight-rival scale; a selective quote/shortlist remains OPEN if the full exact quote cannot meet a measured population budget. Simple cash subtraction from a zero-cost quote is rejected because payment order, arrears and finance rows depend on hand price. Exact AI objective, action allowances, phase exit thresholds, entrants, Store/Core planning and market effects remain OPEN.
