# Paired simulation observations

Pair: **fan-4417**. Delta convention: **right minus left**.

This is a bounded observation report. It does not select a winner or approve balance.

## Case status and observed limits

| Measure | Left | Right |
|---|---|---|
| Case / arm | fan-4417-h4 / h4 | fan-4417-h8 / h8 |
| Termination | completed | rejected_policy_action |
| Commands | 192 | 31 |
| Final cycle | 104 | 22 |
| Releases / target | 8 / 8 | 0 / 8 |
| Cash low at sampled boundary | $1840.00 | $0.00 |
| Peak sampled arrears | $0.00 | $160.00 |
| Final Fans | 6 | 0 |
| Unavailable finance samples | 0 | 0 |
| New-ledger-transaction cash low | $1840.00 | $0.00 |

Endpoint values can cover different calendars; use the matched-cycle table for calendar comparisons. Boundary cash low and arrears peak cover each arm's own observed prefix. Transaction cash low includes recorded cash before/after new ledger transactions and boundary cash; it excludes pre-study history and does not assert unrecorded intermediate values.

- **h4:** target completed; first rejected action: none observed. Termination detail: none.
- **h8:** censored/incomplete; first rejected action: step 31, cycle 22, development: The run calendar cannot advance safely.. Termination detail: The run calendar cannot advance safely..

A malformed policy or command bound is not evidence of a financial blocker. A command rejection must be interpreted from its recorded error and request.

## Matched calendar

Last observed sample at each shared run_cycle; zero-cycle actions use their final observed boundary at that cycle. No interpolation, extrapolation or assumption of equal phase.

| Cycle | Left cash | Right cash | Δ cash | Left Fans | Right Fans | Δ Fans | Left arrears | Right arrears | Δ arrears |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 0 | $5700.00 | $5700.00 | $0.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 1 | $5700.00 | $5700.00 | $0.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 2 | $4850.00 | $4850.00 | $0.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 3 | $4710.00 | $4710.00 | $0.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 4 | $4120.00 | $4120.00 | $0.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 5 | $3960.00 | $3960.00 | $0.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 6 | $3100.00 | $3460.00 | $360.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 7 | $2880.00 | $3460.00 | $580.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 8 | $2340.00 | $2960.00 | $620.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 9 | $2340.00 | $2960.00 | $620.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 10 | $1840.00 | $2100.00 | $260.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 11 | $2840.00 | $1880.00 | -$960.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 12 | $2340.00 | $1340.00 | -$1000.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 13 | $2340.00 | $1340.00 | -$1000.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 14 | $3350.48 | $840.00 | -$2510.48 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 15 | $3110.48 | $840.00 | -$2270.48 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 16 | $4276.57 | $340.00 | -$3936.57 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 17 | $4116.57 | $340.00 | -$3776.57 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 18 | $4120.97 | $0.00 | -$4120.97 | 0 | 0 | 0 | $0.00 | $160.00 | $160.00 |
| 19 | $3760.97 | $840.00 | -$2920.97 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 20 | $3403.70 | $340.00 | -$3063.70 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 21 | $3363.70 | $340.00 | -$3023.70 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 22 | $2906.56 | $0.00 | -$2906.56 | 0 | 0 | 0 | $0.00 | $160.00 | $160.00 |

## Matched new release milestones

First post-command sample attaining each new release ordinal; compared launch milestones may occur at different calendar cycles

| Release ordinal | Left Review | Right Review | Δ Review | Left launch cycle | Right launch cycle | Δ launch cycle |
|---|---:|---:|---:|---:|---:|---:|

No new release milestone was observed in both arms.

Initial common releases: 0; retained separately in comparison.json. Unmatched releases are retained per arm, not imputed.

## Provenance and limits

- Mechanics identity: `62cfd4f1686a6cc6302616d98aab421f2db511971fc5655cf5b6d9e743f612c4`
- Godot: 4.7.1-stable (official)
- Overall original run succeeded: False. Retained failed cases are allowed in this report.
- Local source/input/artifact consistency checks; no signatures or malicious-tampering guarantee. Variant tapes are not decoded here; use the separate exact replay command.
- Independent campaigns; no winner, balance approval, human feel or shared-world AI claim

Full samples, exact requests, source manifest and replay artifacts remain in the original bundle. comparison.json retains milestone cash/Fans/arrears, Features, queue and artifact hashes.
