# Beta shadow audit v2 counting amendment — 2026-10-25

The [v1 audit output](sims/rival-beta-shadow-audit-20261025-v1.json) passes finance/state parity, but its `accepted_beta_hands_selecting_insider_payout` value is **INVALID**. The world harness traces a productive choice again during post-cycle lookahead, before that choice is executed on the next player cycle. V1 counted every proposed `play` row and double counted those hands. Keep the output as a rejected semantic result.

V2 changes only the Insider-hand count: for each completed project, consider unique `(seed, studio, project, sequence)` Beta `play` choices with sequence below that project's observed `request_exit` sequence; require two such hands per completed project under the frozen two-hand control. Use the same two world reports, all finance/state parity tests and reserve arithmetic. Write a new output path and preserve v1. No new simulation, seed, policy, reserve or horizon change.
