# Paired simulation observations

Pair: **sidestreet-sports-1104-v3**. Delta convention: **right minus left**.

This is a bounded observation report. It does not select a winner or approve balance.

## Case status and observed limits

| Measure | Left | Right |
|---|---|---|
| Case / arm | sports-1104-skip / skip | sports-1104-take / take |
| Termination | completed | completed |
| Commands | 32 | 37 |
| Final cycle | 52 | 54 |
| Releases / target | 3 / 3 | 3 / 3 |
| Cash low at sampled boundary | $1682.82 | $1682.82 |
| Peak sampled arrears | $0.00 | $0.00 |
| Final Fans | 152 | 152 |
| Unavailable finance samples | 0 | 0 |
| New-ledger-transaction cash low | $1682.82 | $1682.82 |

Endpoint values can cover different calendars; use the matched-cycle table for calendar comparisons. Boundary cash low and arrears peak cover each arm's own observed prefix. Transaction cash low includes recorded cash before/after new ledger transactions and boundary cash; it excludes pre-study history and does not assert unrecorded intermediate values.

- **skip:** target completed; first rejected action: none observed. Termination detail: none.
- **take:** target completed; first rejected action: none observed. Termination detail: none.

A malformed policy or command bound is not evidence of a financial blocker. A command rejection must be interpreted from its recorded error and request.

## Matched calendar

Last observed sample at each shared run_cycle; zero-cycle actions use their final observed boundary at that cycle. No interpolation, extrapolation or assumption of equal phase.

| Cycle | Left cash | Right cash | Δ cash | Left Fans | Right Fans | Δ Fans | Left arrears | Right arrears | Δ arrears |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 32 | $1832.82 | $1682.82 | -$150.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 33 | $1832.82 | $1682.82 | -$150.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 34 | $8354.49 | $7870.40 | -$484.09 | 83 | 83 | 0 | $0.00 | $0.00 | $0.00 |
| 35 | $8354.49 | $7870.40 | -$484.09 | 83 | 83 | 0 | $0.00 | $0.00 | $0.00 |
| 36 | $8950.99 | $9993.26 | $1042.27 | 106 | 106 | 0 | $0.00 | $0.00 | $0.00 |
| 37 | $8700.99 | $9993.26 | $1292.27 | 106 | 106 | 0 | $0.00 | $0.00 | $0.00 |
| 38 | $9117.98 | $10100.25 | $982.27 | 122 | 122 | 0 | $0.00 | $0.00 | $0.00 |
| 39 | $9117.98 | $9850.25 | $732.27 | 122 | 122 | 0 | $0.00 | $0.00 | $0.00 |
| 40 | $9296.30 | $9938.57 | $642.27 | 132 | 132 | 0 | $0.00 | $0.00 | $0.00 |
| 41 | $8916.30 | $9938.57 | $1022.27 | 132 | 132 | 0 | $0.00 | $0.00 | $0.00 |
| 42 | $8600.85 | $9893.12 | $1292.27 | 139 | 139 | 0 | $0.00 | $0.00 | $0.00 |
| 43 | $8560.85 | $9513.12 | $952.27 | 139 | 139 | 0 | $0.00 | $0.00 | $0.00 |
| 44 | $8368.54 | $9050.81 | $682.27 | 144 | 144 | 0 | $0.00 | $0.00 | $0.00 |
| 45 | $8368.54 | $9010.81 | $642.27 | 144 | 144 | 0 | $0.00 | $0.00 | $0.00 |
| 46 | $8071.34 | $8713.61 | $642.27 | 147 | 147 | 0 | $0.00 | $0.00 | $0.00 |
| 47 | $9071.34 | $8713.61 | -$357.73 | 147 | 147 | 0 | $0.00 | $0.00 | $0.00 |
| 48 | $8704.20 | $8346.47 | -$357.73 | 149 | 149 | 0 | $0.00 | $0.00 | $0.00 |
| 49 | $8704.20 | $9346.47 | $642.27 | 149 | 149 | 0 | $0.00 | $0.00 | $0.00 |
| 50 | $8295.11 | $8937.38 | $642.27 | 151 | 151 | 0 | $0.00 | $0.00 | $0.00 |
| 51 | $8295.11 | $8937.38 | $642.27 | 151 | 151 | 0 | $0.00 | $0.00 | $0.00 |
| 52 | $7858.05 | $8500.32 | $642.27 | 152 | 152 | 0 | $0.00 | $0.00 | $0.00 |

## Matched new release milestones

First post-command sample attaining each new release ordinal; compared launch milestones may occur at different calendar cycles

| Release ordinal | Left Review | Right Review | Δ Review | Left launch cycle | Right launch cycle | Δ launch cycle |
|---|---:|---:|---:|---:|---:|---:|
| 3 | 7.3 | 7.3 | 0.0 | 52 | 54 | 2 |

Initial common releases: 2; retained separately in comparison.json. Unmatched releases are retained per arm, not imputed.

## Provenance and limits

- Mechanics identity: `13980fdeb9efabaeb070c8dddddcd8137982e3e073aa43ab87f7fdd1a57c4c4f`
- Godot: 4.7.1-stable (official)
- Overall original run succeeded: True. Retained failed cases are allowed in this report.
- Local source/input/artifact consistency checks; no signatures or malicious-tampering guarantee. Variant tapes are not decoded here; use the separate exact replay command.
- Independent campaigns; no winner, balance approval, human feel or shared-world AI claim

Full samples, exact requests, source manifest and replay artifacts remain in the original bundle. comparison.json retains milestone cash/Fans/arrears, Features, queue and artifact hashes.
