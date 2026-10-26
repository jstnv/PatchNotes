# Publisher relationship formula checks — pre-run plan v2

2026-10-18 (America/Los_Angeles). **PROPOSED formulas; deterministic arithmetic only.** Working `main` HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty checkout preserved. This revision corrects [v1](PUBLISHER-RELATIONSHIP-ARITHMETIC-PLAN-2026-10-18-v1.md): salvage cash may be proportional, but a commission earns relationship standing only when its entire frozen promise is met. No results from v1 are silently reused to establish this rule.

## Hypothesis and declared cases

The integer formulas reject a nonpositive frozen Scope denominator, preserve 0–100.00 ledger bounds, pay monotone underdelivery salvage without awarding trust for misses, give a full Brief exactly 10.00 Reputation, and let a fully delivered commission grow only its own publisher's Reputation/Investment. The two-Brief → tier1 commission → support success → two-Brief → tier2 commission → one-Brief illustrative sequence should reach tier3 gate. This is only a ledger arithmetic sequence, not a legal campaign.

Use three tiers with Reputation gates 20/50/80, fees $6,000/$8,000/$10,000, Review targets 6.0/7.0/8.0 and full ledger awards 15/20/25 points. Freeze a **positive project-specific required Scope** in each quote. For the fixed arithmetic grid, use illustrative `required_scope=30` and delivered Scope `[0,15,30]` to produce 0/50/100% Scope grades; no claim is made that 30 is a legal current project or an authored tier minimum. Reject `(required,delivered)` `[0,0]`, `[0,30]`, `[-1,15]`, `[30,-1]`. Review inputs per tier are `target−2.0`, `target−1.0`, `target−0.1`, `target`, `target+1.0`. Brief grades are `[0,5000,10000]` × `[0,5000,10000]` basis points.

Formulas: `S_bp=clamp(floor(10000×delivered_scope/required_scope))`; `V_bp=clamp(500×(review_tenths−(target_tenths−20)))`; `D_bp=min(S_bp,V_bp)`; `fee=floor(full_fee_cents×D_bp/10000)`; `ΔR=ΔI=full_tier_award` iff `D_bp=10000`, else zero. Brief `ΔR=floor(1000×min(completion_bp,promise_bp)/10000)` and `ΔI=0`. A separately stipulated successful supported title adds exactly 1000 Investment units once; this checker does not recompute Review or units. Cap each ledger at10000, isolate publishers, and test the exact sequence above.

## Command, limits and stop

Use the bundled Python in two independent processes with the same fixed script and distinct outputs:

`& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/contracts/publisher_relationship_arithmetic_v2.py --output docs/codex/threads/contracts/sims/publisher-relationship-arithmetic-20261018-v2.json`

Repeat with `...-v2-replay.json`, compare file hashes and retain failed outputs. Stop after 9 Brief cells, 45 commission cells, four invalid Scope cases and eight progression events. There are no seeds, player saves, legal starting conditions, release commands or runtime variant in this formula checker. It cannot prove offer access, Review/Scope deliverability, development liquidity, title rights, save migration, UI or balance approval. [Economic formula screen v1](PUBLISHER-SYSTEM-ARITHMETIC-FINDINGS-2026-10-18-v1.md) is separate and unchanged; its Ironclad cash-only support row is a diagnostic rejected profile under [design v3](PUBLISHER-SYSTEM-DESIGN-2026-10-18-v3.md).
