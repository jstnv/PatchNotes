# Paired simulation observations

Pair: **graduate-90210-eligible-loan**. Delta convention: **right minus left**.

This is a bounded observation report. It does not select a winner or approve balance.

## Case status and observed limits

| Measure | Left | Right |
|---|---|---|
| Case / arm | graduate-90210-no-loan / no-loan | graduate-90210-borrow-500-12 / borrow-500-12 |
| Termination | completed | completed |
| Commands | 23 | 24 |
| Final cycle | 29 | 29 |
| Releases / target | 2 / 2 | 2 / 2 |
| Cash low at sampled boundary | $3493.83 | $3764.65 |
| Peak sampled arrears | $0.00 | $0.00 |
| Final Fans | 34 | 34 |
| Unavailable finance samples | 0 | 0 |
| New-ledger-transaction cash low | $3493.83 | $3764.65 |

Endpoint values can cover different calendars; use the matched-cycle table for calendar comparisons. Boundary cash low and arrears peak cover each arm's own observed prefix. Transaction cash low includes recorded cash before/after new ledger transactions and boundary cash; it excludes pre-study history and does not assert unrecorded intermediate values.

- **no-loan:** target completed; first rejected action: none observed. Termination detail: none.
- **borrow-500-12:** target completed; first rejected action: none observed. Termination detail: none.

A malformed policy or command bound is not evidence of a financial blocker. A command rejection must be interpreted from its recorded error and request.

## Matched calendar

Last observed sample at each shared run_cycle; zero-cycle actions use their final observed boundary at that cycle. No interpolation, extrapolation or assumption of equal phase.

| Cycle | Left cash | Right cash | Δ cash | Left Fans | Right Fans | Δ Fans | Left arrears | Right arrears | Δ arrears |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 16 | $5433.77 | $5933.77 | $500.00 | 23 | 23 | 0 | $0.00 | $0.00 | $0.00 |
| 17 | $5433.77 | $5933.77 | $500.00 | 23 | 23 | 0 | $0.00 | $0.00 | $0.00 |
| 18 | $5582.72 | $6036.05 | $453.33 | 28 | 28 | 0 | $0.00 | $0.00 | $0.00 |
| 19 | $5292.72 | $5746.05 | $453.33 | 28 | 28 | 0 | $0.00 | $0.00 | $0.00 |
| 20 | $5352.16 | $5759.24 | $407.08 | 31 | 31 | 0 | $0.00 | $0.00 | $0.00 |
| 21 | $5302.16 | $5709.24 | $407.08 | 31 | 31 | 0 | $0.00 | $0.00 | $0.00 |
| 22 | $4936.84 | $5298.08 | $361.24 | 32 | 32 | 0 | $0.00 | $0.00 | $0.00 |
| 23 | $4676.84 | $5038.08 | $361.24 | 32 | 32 | 0 | $0.00 | $0.00 | $0.00 |
| 24 | $4178.66 | $4494.48 | $315.82 | 33 | 33 | 0 | $0.00 | $0.00 | $0.00 |
| 25 | $4178.66 | $4494.48 | $315.82 | 33 | 33 | 0 | $0.00 | $0.00 | $0.00 |
| 26 | $3493.83 | $3764.65 | $270.82 | 33 | 33 | 0 | $0.00 | $0.00 | $0.00 |
| 27 | $4493.83 | $4764.65 | $270.82 | 33 | 33 | 0 | $0.00 | $0.00 | $0.00 |
| 28 | $3767.05 | $3993.28 | $226.23 | 34 | 34 | 0 | $0.00 | $0.00 | $0.00 |
| 29 | $3767.05 | $3993.28 | $226.23 | 34 | 34 | 0 | $0.00 | $0.00 | $0.00 |

## Matched new release milestones

First post-command sample attaining each new release ordinal; compared launch milestones may occur at different calendar cycles

| Release ordinal | Left Review | Right Review | Δ Review | Left launch cycle | Right launch cycle | Δ launch cycle |
|---|---:|---:|---:|---:|---:|---:|
| 2 | 4.6 | 4.6 | 0.0 | 29 | 29 | 0 |

Initial common releases: 1; retained separately in comparison.json. Unmatched releases are retained per arm, not imputed.

## Provenance and limits

- Mechanics identity: `0f29c6a6f5648075f736756f6614da115c4d528ce1ade52611aa527e2971d645`
- Godot: 4.7.1-stable (official)
- Overall original run succeeded: True. Retained failed cases are allowed in this report.
- Local source/input/artifact consistency checks; no signatures or malicious-tampering guarantee. Variant tapes are not decoded here; use the separate exact replay command.
- Independent campaigns; no winner, balance approval, human feel or shared-world AI claim

Full samples, exact requests, source manifest and replay artifacts remain in the original bundle. comparison.json retains milestone cash/Fans/arrears, Features, queue and artifact hashes.
