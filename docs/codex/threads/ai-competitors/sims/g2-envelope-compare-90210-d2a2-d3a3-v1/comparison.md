# Paired simulation observations

Pair: **g2-envelope-90210**. Delta convention: **right minus left**.

This is a bounded observation report. It does not select a winner or approve balance.

## Case status and observed limits

| Measure | Left | Right |
|---|---|---|
| Case / arm | g2-next-90210-d2a2 / d2a2 | g2-next-90210-d3a3 / d3a3 |
| Termination | completed | completed |
| Commands | 18 | 20 |
| Final cycle | 14 | 16 |
| Releases / target | 2 / 2 | 2 / 2 |
| Cash low at sampled boundary | $3703.70 | $3192.58 |
| Peak sampled arrears | $0.00 | $0.00 |
| Final Fans | 0 | 0 |
| Unavailable finance samples | 0 | 0 |
| New-ledger-transaction cash low | $3703.70 | $3192.58 |

Endpoint values can cover different calendars; use the matched-cycle table for calendar comparisons. Boundary cash low and arrears peak cover each arm's own observed prefix. Transaction cash low includes recorded cash before/after new ledger transactions and boundary cash; it excludes pre-study history and does not assert unrecorded intermediate values.

- **d2a2:** target completed; first rejected action: none observed. Termination detail: none.
- **d3a3:** target completed; first rejected action: none observed. Termination detail: none.

A malformed policy or command bound is not evidence of a financial blocker. A command rejection must be interpreted from its recorded error and request.

## Matched calendar

Last observed sample at each shared run_cycle; zero-cycle actions use their final observed boundary at that cycle. No interpolation, extrapolation or assumption of equal phase.

| Cycle | Left cash | Right cash | Δ cash | Left Fans | Right Fans | Δ Fans | Left arrears | Right arrears | Δ arrears |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 7 | $4140.00 | $4140.00 | $0.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 8 | $4507.13 | $4507.13 | $0.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 9 | $4067.13 | $4067.13 | $0.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 10 | $4462.02 | $4462.02 | $0.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 11 | $4152.02 | $4372.02 | $220.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 12 | $3703.70 | $3883.70 | $180.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 13 | $3703.70 | $3613.70 | -$90.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 14 | $4322.58 | $3192.58 | -$1130.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |

## Matched new release milestones

First post-command sample attaining each new release ordinal; compared launch milestones may occur at different calendar cycles

| Release ordinal | Left Review | Right Review | Δ Review | Left launch cycle | Right launch cycle | Δ launch cycle |
|---|---:|---:|---:|---:|---:|---:|
| 2 | 2.2 | 3.2 | 1.0 | 14 | 16 | 2 |

Initial common releases: 1; retained separately in comparison.json. Unmatched releases are retained per arm, not imputed.

## Provenance and limits

- Mechanics identity: `13980fdeb9efabaeb070c8dddddcd8137982e3e073aa43ab87f7fdd1a57c4c4f`
- Godot: 4.7.1-stable (official)
- Overall original run succeeded: True. Retained failed cases are allowed in this report.
- Local source/input/artifact consistency checks; no signatures or malicious-tampering guarantee. Variant tapes are not decoded here; use the separate exact replay command.
- Independent campaigns; no winner, balance approval, human feel or shared-world AI claim

Full samples, exact requests, source manifest and replay artifacts remain in the original bundle. comparison.json retains milestone cash/Fans/arrears, Features, queue and artifact hashes.
