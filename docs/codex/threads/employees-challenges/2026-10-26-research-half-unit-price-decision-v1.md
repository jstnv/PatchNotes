# Research half-unit price parity — 2026-10-26

**LOCKED design, NOT IMPLEMENTED:** Two half-steps of one existing Research installment paid at the same familiarity percentage must total **exactly the current full-installment price** after familiarity, with any indivisible cent assigned to the second half. No-staff Research keeps its present quote. The user selected this explicitly over independently rounding each half.

**Recommended exact-cent expression for the selected outcome:** For nominal full installment `N` cents and frozen action familiarity `d`, let first nominal half `N1 = floor(N/2)`. First-half due is `floor(N1 × (100-d)/100)`. Second-half due is `floor(N × (100-d)/100) - floor(N1 × (100-d)/100)`. If the halves occur on separate actions and familiarity changes, recompute only the unpaid second half using the later action's rate; retain the first paid amount. Existing final-installment nominal remainder stays in `N`. This formula implements the selected unchanged-rate parity and is recommended as the accounting rule; handling the changed-rate case and composite receipts remains implementation design, not a new balance approval.

Example: base $301.01 admits at $150.51, leaving nominal $150.50. At 10% familiarity the two Research half-steps cost $67.72 and $67.73, totaling the current $135.45 discounted installment. At 0% the down payment and both halves total $301.01. [Full proposal](2026-10-26-research-accounting-proposal-v1.md).

Branch `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac` at inspection. Design only; no gameplay, tests, simulation, Google Drive, commit or push.
