# Paired simulation observations

Pair: **store-88820c439cea3c1841286dbb**. Delta convention: **right minus left**.

This is a bounded observation report. It does not select a winner or approve balance.

## Case status and observed limits

| Measure | Left | Right |
|---|---|---|
| Case / arm | store-88820c439cea3c1841286dbb-research_now / research_now | store-88820c439cea3c1841286dbb-defer / defer |
| Termination | completed | completed |
| Commands | 38 | 36 |
| Final cycle | 22 | 21 |
| Releases / target | 3 / 3 | 3 / 3 |
| Cash low at sampled boundary | $928.46 | $2465.02 |
| Peak sampled arrears | $0.00 | $0.00 |
| Final Fans | 0 | 0 |
| Unavailable finance samples | 0 | 0 |
| New-ledger-transaction cash low | $848.38 | $2228.46 |

Endpoint values can cover different calendars; use the matched-cycle table for calendar comparisons. Boundary cash low and arrears peak cover each arm's own observed prefix. Transaction cash low includes recorded cash before/after new ledger transactions and boundary cash; it excludes pre-study history and does not assert unrecorded intermediate values.

- **research_now:** target completed; first rejected action: none observed. Termination detail: none.
- **defer:** target completed; first rejected action: none observed. Termination detail: none.

A malformed policy or command bound is not evidence of a financial blocker. A command rejection must be interpreted from its recorded error and request.

## Matched calendar

Last observed sample at each shared run_cycle; zero-cycle actions use their final observed boundary at that cycle. No interpolation, extrapolation or assumption of equal phase.

| Cycle | Left cash | Right cash | Δ cash | Left Fans | Right Fans | Δ Fans | Left arrears | Right arrears | Δ arrears |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 7 | $3280.00 | $4130.00 | $850.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 8 | $2489.44 | $4189.44 | $1700.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 9 | $2489.44 | $3919.44 | $1430.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 10 | $2342.72 | $3902.72 | $1560.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 11 | $2202.72 | $3632.72 | $1430.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 12 | $1635.52 | $3065.52 | $1430.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 13 | $1365.52 | $3065.52 | $1700.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 14 | $928.46 | $2628.46 | $1700.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 15 | $928.46 | $2628.46 | $1700.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 16 | $1498.38 | $3504.67 | $2006.29 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 17 | $1098.38 | $3214.67 | $2116.29 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 18 | $1698.02 | $3017.19 | $1319.17 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 19 | $1518.02 | $2797.19 | $1279.17 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 20 | $1189.63 | $2465.02 | $1275.39 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 21 | $1189.63 | $3465.02 | $2275.39 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |

## Matched new release milestones

First post-command sample attaining each new release ordinal; compared launch milestones may occur at different calendar cycles

| Release ordinal | Left Review | Right Review | Δ Review | Left launch cycle | Right launch cycle | Δ launch cycle |
|---|---:|---:|---:|---:|---:|---:|
| 2 | 2.4 | 2.0 | -0.4 | 15 | 14 | -1 |
| 3 | 2.1 | 1.7 | -0.4 | 22 | 21 | -1 |

Initial common releases: 1; retained separately in comparison.json. Unmatched releases are retained per arm, not imputed.

## Provenance and limits

- Mechanics identity: `13980fdeb9efabaeb070c8dddddcd8137982e3e073aa43ab87f7fdd1a57c4c4f`
- Godot: 4.7.1-stable (official)
- Overall original run succeeded: True. Retained failed cases are allowed in this report.
- Local source/input/artifact consistency checks; no signatures or malicious-tampering guarantee. Variant tapes are not decoded here; use the separate exact replay command.
- Independent campaigns; no winner, balance approval, human feel or shared-world AI claim

Full samples, exact requests, source manifest and replay artifacts remain in the original bundle. comparison.json retains milestone cash/Fans/arrears, Features, queue and artifact hashes.
