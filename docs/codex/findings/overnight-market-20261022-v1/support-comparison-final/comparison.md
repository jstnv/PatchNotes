# Paired simulation observations

Pair: **sports-1112-support-vs-self-v1**. Delta convention: **right minus left**.

This is a bounded observation report. It does not select a winner or approve balance.

## Case status and observed limits

| Measure | Left | Right |
|---|---|---|
| Case / arm | sports-1112-self-published / self-published | sports-1112-support / support |
| Termination | completed | completed |
| Commands | 46 | 46 |
| Final cycle | 79 | 79 |
| Releases / target | 6 / 6 | 6 / 6 |
| Cash low at sampled boundary | $4492.15 | $5192.15 |
| Peak sampled arrears | $0.00 | $0.00 |
| Final Fans | 422 | 425 |
| Unavailable finance samples | 0 | 0 |
| New-ledger-transaction cash low | $4092.15 | $4792.15 |

Endpoint values can cover different calendars; use the matched-cycle table for calendar comparisons. Boundary cash low and arrears peak cover each arm's own observed prefix. Transaction cash low includes recorded cash before/after new ledger transactions and boundary cash; it excludes pre-study history and does not assert unrecorded intermediate values.

- **self-published:** target completed; first rejected action: none observed. Termination detail: none.
- **support:** target completed; first rejected action: none observed. Termination detail: none.

A malformed policy or command bound is not evidence of a financial blocker. A command rejection must be interpreted from its recorded error and request.

## Matched calendar

Last observed sample at each shared run_cycle; zero-cycle actions use their final observed boundary at that cycle. No interpolation, extrapolation or assumption of equal phase.

| Cycle | Left cash | Right cash | Δ cash | Left Fans | Right Fans | Δ Fans | Left arrears | Right arrears | Δ arrears |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 53 | $9922.15 | $9922.15 | $0.00 | 17 | 17 | 0 | $0.00 | $0.00 | $0.00 |
| 54 | $9422.15 | $10122.15 | $700.00 | 76 | 76 | 0 | $0.00 | $0.00 | $0.00 |
| 55 | $9022.15 | $9722.15 | $700.00 | 76 | 76 | 0 | $0.00 | $0.00 | $0.00 |
| 56 | $8232.15 | $8932.15 | $700.00 | 154 | 154 | 0 | $0.00 | $0.00 | $0.00 |
| 57 | $8232.15 | $8932.15 | $700.00 | 154 | 154 | 0 | $0.00 | $0.00 | $0.00 |
| 58 | $7682.15 | $8382.15 | $700.00 | 185 | 185 | 0 | $0.00 | $0.00 | $0.00 |
| 59 | $7682.15 | $8382.15 | $700.00 | 185 | 185 | 0 | $0.00 | $0.00 | $0.00 |
| 60 | $6892.15 | $7592.15 | $700.00 | 207 | 207 | 0 | $0.00 | $0.00 | $0.00 |
| 61 | $6622.15 | $7322.15 | $700.00 | 207 | 207 | 0 | $0.00 | $0.00 | $0.00 |
| 62 | $6032.15 | $6732.15 | $700.00 | 223 | 223 | 0 | $0.00 | $0.00 | $0.00 |
| 63 | $6032.15 | $6732.15 | $700.00 | 223 | 223 | 0 | $0.00 | $0.00 | $0.00 |
| 64 | $5492.15 | $6192.15 | $700.00 | 235 | 235 | 0 | $0.00 | $0.00 | $0.00 |
| 65 | $5492.15 | $6192.15 | $700.00 | 235 | 235 | 0 | $0.00 | $0.00 | $0.00 |
| 66 | $4992.15 | $5692.15 | $700.00 | 243 | 243 | 0 | $0.00 | $0.00 | $0.00 |
| 67 | $4992.15 | $5692.15 | $700.00 | 243 | 243 | 0 | $0.00 | $0.00 | $0.00 |
| 68 | $4492.15 | $5192.15 | $700.00 | 250 | 250 | 0 | $0.00 | $0.00 | $0.00 |
| 69 | $5492.15 | $6192.15 | $700.00 | 250 | 250 | 0 | $0.00 | $0.00 | $0.00 |
| 70 | $4992.15 | $5692.15 | $700.00 | 254 | 254 | 0 | $0.00 | $0.00 | $0.00 |
| 71 | $4992.15 | $5692.15 | $700.00 | 254 | 254 | 0 | $0.00 | $0.00 | $0.00 |
| 72 | $4492.15 | $5192.15 | $700.00 | 258 | 258 | 0 | $0.00 | $0.00 | $0.00 |
| 73 | $4492.15 | $5192.15 | $700.00 | 258 | 258 | 0 | $0.00 | $0.00 | $0.00 |
| 74 | $11046.68 | $10969.59 | -$77.09 | 353 | 355 | 2 | $0.00 | $0.00 | $0.00 |
| 75 | $10746.68 | $10669.59 | -$77.09 | 353 | 355 | 2 | $0.00 | $0.00 | $0.00 |
| 76 | $12259.34 | $12231.19 | -$28.15 | 394 | 397 | 3 | $0.00 | $0.00 | $0.00 |
| 77 | $11939.34 | $11911.19 | -$28.15 | 394 | 397 | 3 | $0.00 | $0.00 | $0.00 |
| 78 | $13040.74 | $13047.55 | $6.81 | 422 | 425 | 3 | $0.00 | $0.00 | $0.00 |
| 79 | $14040.74 | $14047.55 | $6.81 | 422 | 425 | 3 | $0.00 | $0.00 | $0.00 |

## Matched new release milestones

First post-command sample attaining each new release ordinal; compared launch milestones may occur at different calendar cycles

| Release ordinal | Left Review | Right Review | Δ Review | Left launch cycle | Right launch cycle | Δ launch cycle |
|---|---:|---:|---:|---:|---:|---:|
| 5 | 7.9 | 7.9 | 0.0 | 72 | 72 | 0 |
| 6 | 3.3 | 3.3 | 0.0 | 79 | 79 | 0 |

Initial common releases: 4; retained separately in comparison.json. Unmatched releases are retained per arm, not imputed.

## Provenance and limits

- Mechanics identity: `b53d9a31b1f54155324e3ec942d86baedd7facae9adf519fd644690326fc8b07`
- Godot: 4.7.1-stable (official)
- Overall original run succeeded: True. Retained failed cases are allowed in this report.
- Local source/input/artifact consistency checks; no signatures or malicious-tampering guarantee. Variant tapes are not decoded here; use the separate exact replay command.
- Independent campaigns; no winner, balance approval, human feel or shared-world AI claim

Full samples, exact requests, source manifest and replay artifacts remain in the original bundle. comparison.json retains milestone cash/Fans/arrears, Features, queue and artifact hashes.
