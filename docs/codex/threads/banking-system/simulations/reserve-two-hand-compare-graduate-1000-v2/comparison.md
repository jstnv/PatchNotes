# Paired simulation observations

Pair: **graduate-90210-reserve-v1-two-hand**. Delta convention: **right minus left**.

This is a bounded observation report. It does not select a winner or approve balance.

## Case status and observed limits

| Measure | Left | Right |
|---|---|---|
| Case / arm | graduate-90210-no-loan / no-loan | graduate-90210-borrow-1000-12 / borrow-1000-12 |
| Termination | completed | completed |
| Commands | 18 | 20 |
| Final cycle | 23 | 24 |
| Releases / target | 2 / 2 | 2 / 2 |
| Cash low at sampled boundary | $126.84 | $184.32 |
| Peak sampled arrears | $0.00 | $0.00 |
| Final Fans | 32 | 33 |
| Unavailable finance samples | 0 | 0 |
| New-ledger-transaction cash low | $126.84 | $184.32 |

Endpoint values can cover different calendars; use the matched-cycle table for calendar comparisons. Boundary cash low and arrears peak cover each arm's own observed prefix. Transaction cash low includes recorded cash before/after new ledger transactions and boundary cash; it excludes pre-study history and does not assert unrecorded intermediate values.

- **no-loan:** target completed; first rejected action: none observed. Termination detail: none.
- **borrow-1000-12:** target completed; first rejected action: none observed. Termination detail: none.

A malformed policy or command bound is not evidence of a financial blocker. A command rejection must be interpreted from its recorded error and request.

## Matched calendar

Last observed sample at each shared run_cycle; zero-cycle actions use their final observed boundary at that cycle. No interpolation, extrapolation or assumption of equal phase.

| Cycle | Left cash | Right cash | Δ cash | Left Fans | Right Fans | Δ Fans | Left arrears | Right arrears | Δ arrears |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 16 | $833.77 | $1833.77 | $1000.00 | 23 | 23 | 0 | $0.00 | $0.00 | $0.00 |
| 17 | $833.77 | $978.77 | $145.00 | 23 | 23 | 0 | $0.00 | $0.00 | $0.00 |
| 18 | $982.72 | $1434.38 | $451.66 | 28 | 28 | 0 | $0.00 | $0.00 | $0.00 |
| 19 | $692.72 | $1234.38 | $541.66 | 28 | 28 | 0 | $0.00 | $0.00 | $0.00 |
| 20 | $572.16 | $901.31 | $329.15 | 31 | 31 | 0 | $0.00 | $0.00 | $0.00 |
| 21 | $312.16 | $721.31 | $409.15 | 31 | 31 | 0 | $0.00 | $0.00 | $0.00 |
| 22 | $126.84 | $184.32 | $57.48 | 32 | 32 | 0 | $0.00 | $0.00 | $0.00 |
| 23 | $1126.84 | $184.32 | -$942.52 | 32 | 32 | 0 | $0.00 | $0.00 | $0.00 |

## Matched new release milestones

First post-command sample attaining each new release ordinal; compared launch milestones may occur at different calendar cycles

| Release ordinal | Left Review | Right Review | Δ Review | Left launch cycle | Right launch cycle | Δ launch cycle |
|---|---:|---:|---:|---:|---:|---:|
| 2 | 2.1 | 1.9 | -0.2 | 23 | 24 | 1 |

Initial common releases: 1; retained separately in comparison.json. Unmatched releases are retained per arm, not imputed.

## Provenance and limits

- Mechanics identity: `0629a2fef700cb555d368c80c3342f638cc55150b08ce3416362dc269b9d8691`
- Godot: 4.7.1-stable (official)
- Overall original run succeeded: False. Retained failed cases are allowed in this report.
- Local source/input/artifact consistency checks; no signatures or malicious-tampering guarantee. Variant tapes are not decoded here; use the separate exact replay command.
- Independent campaigns; no winner, balance approval, human feel or shared-world AI claim

Full samples, exact requests, source manifest and replay artifacts remain in the original bundle. comparison.json retains milestone cash/Fans/arrears, Features, queue and artifact hashes.
