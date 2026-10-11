# Paired simulation observations

Pair: **store-57a6262f9cf7d512c659d4ce**. Delta convention: **right minus left**.

This is a bounded observation report. It does not select a winner or approve balance.

## Case status and observed limits

| Measure | Left | Right |
|---|---|---|
| Case / arm | store-57a6262f9cf7d512c659d4ce-research_now / research_now | store-57a6262f9cf7d512c659d4ce-defer / defer |
| Termination | completed | completed |
| Commands | 20 | 18 |
| Final cycle | 29 | 28 |
| Releases / target | 4 / 4 | 4 / 4 |
| Cash low at sampled boundary | $618.36 | $2528.43 |
| Peak sampled arrears | $0.00 | $0.00 |
| Final Fans | 0 | 0 |
| Unavailable finance samples | 0 | 0 |
| New-ledger-transaction cash low | $618.36 | $2528.43 |

Endpoint values can cover different calendars; use the matched-cycle table for calendar comparisons. Boundary cash low and arrears peak cover each arm's own observed prefix. Transaction cash low includes recorded cash before/after new ledger transactions and boundary cash; it excludes pre-study history and does not assert unrecorded intermediate values.

- **research_now:** target completed; first rejected action: none observed. Termination detail: none.
- **defer:** target completed; first rejected action: none observed. Termination detail: none.

A malformed policy or command bound is not evidence of a financial blocker. A command rejection must be interpreted from its recorded error and request.

## Matched calendar

Last observed sample at each shared run_cycle; zero-cycle actions use their final observed boundary at that cycle. No interpolation, extrapolation or assumption of equal phase.

| Cycle | Left cash | Right cash | Δ cash | Left Fans | Right Fans | Δ Fans | Left arrears | Right arrears | Δ arrears |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 21 | $2615.02 | $3465.02 | $850.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 22 | $2057.39 | $3587.39 | $1530.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 23 | $2057.39 | $3207.39 | $1150.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 24 | $1968.65 | $3228.65 | $1260.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 25 | $1748.65 | $2958.65 | $1210.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 26 | $1188.43 | $2528.43 | $1340.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 27 | $1048.43 | $2528.43 | $1480.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 28 | $618.36 | $3098.36 | $2480.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |

## Matched new release milestones

First post-command sample attaining each new release ordinal; compared launch milestones may occur at different calendar cycles

| Release ordinal | Left Review | Right Review | Δ Review | Left launch cycle | Right launch cycle | Δ launch cycle |
|---|---:|---:|---:|---:|---:|---:|
| 4 | 2.2 | 1.7 | -0.5 | 29 | 28 | -1 |

Initial common releases: 3; retained separately in comparison.json. Unmatched releases are retained per arm, not imputed.

## Provenance and limits

- Mechanics identity: `13980fdeb9efabaeb070c8dddddcd8137982e3e073aa43ab87f7fdd1a57c4c4f`
- Godot: 4.7.1-stable (official)
- Overall original run succeeded: True. Retained failed cases are allowed in this report.
- Local source/input/artifact consistency checks; no signatures or malicious-tampering guarantee. Variant tapes are not decoded here; use the separate exact replay command.
- Independent campaigns; no winner, balance approval, human feel or shared-world AI claim

Full samples, exact requests, source manifest and replay artifacts remain in the original bundle. comparison.json retains milestone cash/Fans/arrears, Features, queue and artifact hashes.
