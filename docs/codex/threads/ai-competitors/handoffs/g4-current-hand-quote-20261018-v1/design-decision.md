# G4 current-hand quote — structural design review, 2026-10-18

**Status: DESIGN review, not LOCKED/ACTIVE/TRIAL and not queued implementation.** This records the bounded disposition of the [current-hand study](2026-10-18-g4-current-hand-finding-v1.md). It does not change the existing finite, legal, phase-local rival action direction or any canonical gameplay.

## Decision

1. Retain a **read-only exact quote of the current visible four-card Design/Alpha hand** as the next interface candidate for G4. A quote may expose selected candidate IDs, direct Feature price in cents, whether the current productive-cycle cash preflight is available, next-cycle cash after settlement and due bills, and those current settlement/bill amounts. The quote must preserve full state and RNG and must be labeled as a current-cycle cash/calendar estimate, not a legal-play, future solvency or final AI-choice guarantee.
2. **Reject cheapest-affordable alone as an AI policy.** In four legal fresh Studio routes it saved $480–$560 but lowered first Review by 1.3–1.7; the sampled second Action project also had a lower Review and fewer Fans. This is a bounded negative-control result, not a universal ranking of all choices.
3. **Hold quote-only v3 at DESIGN review.** Its one-file private delta passed same-source behavior parity, 207/0 focused quote checks and 118/0 actual-world trial checks, but the measured policy-plus-observation cost rose 2.14–3.50× and no approved population CPU limit exists. The generated sealed packet is an evidence/implementation-review artifact only; no TODO queue or canonical adoption follows.

## Next gate

Specify an observation latency and world population CPU budget, then prototype an optimized shared preflight or selective quote in a **new** thread-owned simulator version. Compare it to the frozen v1 control and v3 candidate with fresh legal starts, exact state/RNG/action parity, selected quote-to-receipt checks and a representative multi-rival world run under isolated profiles. If the budget is met, separately design a benefit-versus-cost/current-calendar AI choice with explicit liquidity and legal exits. No quote array should be recomputed 35 times per hand without measuring its contribution to the full rival population.

**OPEN:** quantitative AI objective and thresholds, cash reserve/dues horizon, hand counts, entrant rules, capability math, Review/Scope/Bug benefit estimates, CPU/population limits, actual player challenge, market coefficients and migration. The market's impact on Reviews remains a separate design slice within AI Competitors. No first-game 10/10 balance inference is made.

**Alternatives logged:** adopt v3 quote-only unchanged now (deferred for cost gate); adopt cheapest-affordable action choice (rejected by sampled quality); continue token-ordered `features_first` as the final AI (not selected—it remains a reproducible control); produce fewer/selective quotes or a shared preflight (next study candidates, no particular strategy approved).
