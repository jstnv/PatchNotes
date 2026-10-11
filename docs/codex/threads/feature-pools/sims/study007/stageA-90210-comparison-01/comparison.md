# Paired simulation observations

Pair: **store-817d92ebfda011b135ad79ac**. Delta convention: **right minus left**.

This is a bounded observation report. It does not select a winner or approve balance.

## Case status and observed limits

| Measure | Left | Right |
|---|---|---|
| Case / arm | store-817d92ebfda011b135ad79ac-research_now / research_now | store-817d92ebfda011b135ad79ac-defer / defer |
| Termination | completed | completed |
| Commands | 38 | 36 |
| Final cycle | 22 | 21 |
| Releases / target | 3 / 3 | 3 / 3 |
| Cash low at sampled boundary | $1827.79 | $3697.90 |
| Peak sampled arrears | $0.00 | $0.00 |
| Final Fans | 0 | 0 |
| Unavailable finance samples | 0 | 0 |
| New-ledger-transaction cash low | $1827.79 | $3697.90 |

Endpoint values can cover different calendars; use the matched-cycle table for calendar comparisons. Boundary cash low and arrears peak cover each arm's own observed prefix. Transaction cash low includes recorded cash before/after new ledger transactions and boundary cash; it excludes pre-study history and does not assert unrecorded intermediate values.

- **research_now:** target completed; first rejected action: none observed. Termination detail: none.
- **defer:** target completed; first rejected action: none observed. Termination detail: none.

A malformed policy or command bound is not evidence of a financial blocker. A command rejection must be interpreted from its recorded error and request.

## Matched calendar

Last observed sample at each shared run_cycle; zero-cycle actions use their final observed boundary at that cycle. No interpolation, extrapolation or assumption of equal phase.

| Cycle | Left cash | Right cash | Δ cash | Left Fans | Right Fans | Δ Fans | Left arrears | Right arrears | Δ arrears |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 7 | $3430.00 | $4280.00 | $850.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 8 | $2962.20 | $4577.20 | $1615.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 9 | $2962.20 | $4227.20 | $1265.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 10 | $3209.19 | $4484.19 | $1275.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 11 | $3009.19 | $4174.19 | $1165.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 12 | $2492.90 | $3697.90 | $1205.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 13 | $2222.90 | $3697.90 | $1475.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 14 | $1827.79 | $4302.79 | $2475.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 15 | $2827.79 | $4302.79 | $1475.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 16 | $3111.01 | $4741.39 | $1630.38 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 17 | $2741.01 | $4601.39 | $1860.38 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 18 | $3009.04 | $4349.01 | $1339.97 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 19 | $2879.04 | $4259.01 | $1379.97 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 20 | $2568.76 | $3891.87 | $1323.11 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 21 | $2568.76 | $4891.87 | $2323.11 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |

## Matched new release milestones

First post-command sample attaining each new release ordinal; compared launch milestones may occur at different calendar cycles

| Release ordinal | Left Review | Right Review | Δ Review | Left launch cycle | Right launch cycle | Δ launch cycle |
|---|---:|---:|---:|---:|---:|---:|
| 2 | 2.2 | 2.0 | -0.2 | 15 | 14 | -1 |
| 3 | 1.5 | 1.5 | 0.0 | 22 | 21 | -1 |

Initial common releases: 1; retained separately in comparison.json. Unmatched releases are retained per arm, not imputed.

## Provenance and limits

- Mechanics identity: `13980fdeb9efabaeb070c8dddddcd8137982e3e073aa43ab87f7fdd1a57c4c4f`
- Godot: 4.7.1-stable (official)
- Overall original run succeeded: True. Retained failed cases are allowed in this report.
- Local source/input/artifact consistency checks; no signatures or malicious-tampering guarantee. Variant tapes are not decoded here; use the separate exact replay command.
- Independent campaigns; no winner, balance approval, human feel or shared-world AI claim

Full samples, exact requests, source manifest and replay artifacts remain in the original bundle. comparison.json retains milestone cash/Fans/arrears, Features, queue and artifact hashes.
