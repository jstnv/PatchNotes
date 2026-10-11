# Paired simulation observations

Pair: **sidestreet-sports-1106-v6**. Delta convention: **right minus left**.

This is a bounded observation report. It does not select a winner or approve balance.

## Case status and observed limits

| Measure | Left | Right |
|---|---|---|
| Case / arm | sports-1106-skip-v6 / skip | sports-1106-take-v6 / take |
| Termination | completed | completed |
| Commands | 59 | 64 |
| Final cycle | 70 | 72 |
| Releases / target | 4 / 4 | 4 / 4 |
| Cash low at sampled boundary | $4021.19 | $4021.19 |
| Peak sampled arrears | $0.00 | $0.00 |
| Final Fans | 334 | 334 |
| Unavailable finance samples | 0 | 0 |
| New-ledger-transaction cash low | $4021.19 | $4021.19 |

Endpoint values can cover different calendars; use the matched-cycle table for calendar comparisons. Boundary cash low and arrears peak cover each arm's own observed prefix. Transaction cash low includes recorded cash before/after new ledger transactions and boundary cash; it excludes pre-study history and does not assert unrecorded intermediate values.

- **skip:** target completed; first rejected action: none observed. Termination detail: none.
- **take:** target completed; first rejected action: none observed. Termination detail: none.

A malformed policy or command bound is not evidence of a financial blocker. A command rejection must be interpreted from its recorded error and request.

## Matched calendar

Last observed sample at each shared run_cycle; zero-cycle actions use their final observed boundary at that cycle. No interpolation, extrapolation or assumption of equal phase.

| Cycle | Left cash | Right cash | Δ cash | Left Fans | Right Fans | Δ Fans | Left arrears | Right arrears | Δ arrears |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 32 | $4171.19 | $4021.19 | -$150.00 | 28 | 28 | 0 | $0.00 | $0.00 | $0.00 |
| 33 | $4171.19 | $4021.19 | -$150.00 | 28 | 28 | 0 | $0.00 | $0.00 | $0.00 |
| 34 | $11245.38 | $10600.38 | -$645.00 | 92 | 92 | 0 | $0.00 | $0.00 | $0.00 |
| 35 | $11245.38 | $10600.38 | -$645.00 | 92 | 92 | 0 | $0.00 | $0.00 | $0.00 |
| 36 | $12073.70 | $13548.70 | $1475.00 | 111 | 111 | 0 | $0.00 | $0.00 | $0.00 |
| 37 | $11733.70 | $13548.70 | $1815.00 | 111 | 111 | 0 | $0.00 | $0.00 | $0.00 |
| 38 | $12246.63 | $13761.63 | $1515.00 | 123 | 123 | 0 | $0.00 | $0.00 | $0.00 |
| 39 | $12246.63 | $13421.63 | $1175.00 | 123 | 123 | 0 | $0.00 | $0.00 | $0.00 |
| 40 | $12417.96 | $13542.96 | $1125.00 | 131 | 131 | 0 | $0.00 | $0.00 | $0.00 |
| 41 | $12147.96 | $13542.96 | $1395.00 | 131 | 131 | 0 | $0.00 | $0.00 | $0.00 |
| 42 | $11784.53 | $13469.53 | $1685.00 | 136 | 136 | 0 | $0.00 | $0.00 | $0.00 |
| 43 | $11694.53 | $13199.53 | $1505.00 | 136 | 136 | 0 | $0.00 | $0.00 | $0.00 |
| 44 | $11427.26 | $12682.26 | $1255.00 | 139 | 139 | 0 | $0.00 | $0.00 | $0.00 |
| 45 | $11427.26 | $12592.26 | $1165.00 | 139 | 139 | 0 | $0.00 | $0.00 | $0.00 |
| 46 | $11095.09 | $12220.09 | $1125.00 | 141 | 141 | 0 | $0.00 | $0.00 | $0.00 |
| 47 | $11095.09 | $12220.09 | $1125.00 | 141 | 141 | 0 | $0.00 | $0.00 | $0.00 |
| 48 | $10699.99 | $11824.99 | $1125.00 | 142 | 142 | 0 | $0.00 | $0.00 | $0.00 |
| 49 | $10699.99 | $11824.99 | $1125.00 | 142 | 142 | 0 | $0.00 | $0.00 | $0.00 |
| 50 | $10262.92 | $11387.92 | $1125.00 | 143 | 143 | 0 | $0.00 | $0.00 | $0.00 |
| 51 | $11262.92 | $11387.92 | $125.00 | 143 | 143 | 0 | $0.00 | $0.00 | $0.00 |
| 52 | $10804.88 | $10929.88 | $125.00 | 143 | 143 | 0 | $0.00 | $0.00 | $0.00 |
| 53 | $10804.88 | $11929.88 | $1125.00 | 143 | 143 | 0 | $0.00 | $0.00 | $0.00 |
| 54 | $16956.82 | $11457.85 | -$5498.97 | 235 | 143 | -92 | $0.00 | $0.00 | $0.00 |
| 55 | $16746.82 | $11457.85 | -$5288.97 | 235 | 143 | -92 | $0.00 | $0.00 | $0.00 |
| 56 | $18281.65 | $17595.81 | -$685.84 | 270 | 236 | -34 | $0.00 | $0.00 | $0.00 |
| 57 | $18281.65 | $17385.81 | -$895.84 | 270 | 236 | -34 | $0.00 | $0.00 | $0.00 |
| 58 | $19243.19 | $18913.64 | -$329.55 | 292 | 270 | -22 | $0.00 | $0.00 | $0.00 |
| 59 | $18863.19 | $18913.64 | $50.45 | 292 | 270 | -22 | $0.00 | $0.00 | $0.00 |
| 60 | $19169.21 | $19875.19 | $705.98 | 307 | 292 | -15 | $0.00 | $0.00 | $0.00 |
| 61 | $19129.21 | $19495.19 | $365.98 | 307 | 292 | -15 | $0.00 | $0.00 | $0.00 |
| 62 | $19196.55 | $19794.21 | $597.66 | 317 | 307 | -10 | $0.00 | $0.00 | $0.00 |
| 63 | $19196.55 | $19754.21 | $557.66 | 317 | 307 | -10 | $0.00 | $0.00 | $0.00 |
| 64 | $19137.11 | $19821.55 | $684.44 | 324 | 317 | -7 | $0.00 | $0.00 | $0.00 |
| 65 | $20137.11 | $19821.55 | -$315.56 | 324 | 317 | -7 | $0.00 | $0.00 | $0.00 |
| 66 | $19930.81 | $19762.11 | -$168.70 | 329 | 324 | -5 | $0.00 | $0.00 | $0.00 |
| 67 | $19930.81 | $20762.11 | $831.30 | 329 | 324 | -5 | $0.00 | $0.00 | $0.00 |
| 68 | $19626.62 | $20555.81 | $929.19 | 332 | 329 | -3 | $0.00 | $0.00 | $0.00 |
| 69 | $19626.62 | $20555.81 | $929.19 | 332 | 329 | -3 | $0.00 | $0.00 | $0.00 |
| 70 | $19259.48 | $20251.62 | $992.14 | 334 | 332 | -2 | $0.00 | $0.00 | $0.00 |

## Matched new release milestones

First post-command sample attaining each new release ordinal; compared launch milestones may occur at different calendar cycles

| Release ordinal | Left Review | Right Review | Δ Review | Left launch cycle | Right launch cycle | Δ launch cycle |
|---|---:|---:|---:|---:|---:|---:|
| 3 | 7.7 | 7.7 | 0.0 | 52 | 54 | 2 |
| 4 | 6.7 | 6.7 | 0.0 | 70 | 72 | 2 |

Initial common releases: 2; retained separately in comparison.json. Unmatched releases are retained per arm, not imputed.

## Provenance and limits

- Mechanics identity: `62cfd4f1686a6cc6302616d98aab421f2db511971fc5655cf5b6d9e743f612c4`
- Godot: 4.7.1-stable (official)
- Overall original run succeeded: True. Retained failed cases are allowed in this report.
- Local source/input/artifact consistency checks; no signatures or malicious-tampering guarantee. Variant tapes are not decoded here; use the separate exact replay command.
- Independent campaigns; no winner, balance approval, human feel or shared-world AI claim

Full samples, exact requests, source manifest and replay artifacts remain in the original bundle. comparison.json retains milestone cash/Fans/arrears, Features, queue and artifact hashes.
