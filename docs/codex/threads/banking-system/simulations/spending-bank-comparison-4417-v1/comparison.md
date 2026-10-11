# Paired simulation observations

Pair: **graduate-4417-bank**. Delta convention: **right minus left**.

This is a bounded observation report. It does not select a winner or approve balance.

## Case status and observed limits

| Measure | Left | Right |
|---|---|---|
| Case / arm | graduate-4417-no-loan / no-loan | graduate-4417-borrow-500-12 / borrow-500-12 |
| Termination | completed | rejected_policy_action |
| Commands | 22 | 1 |
| Final cycle | 40 | 27 |
| Releases / target | 3 / 3 | 2 / 3 |
| Cash low at sampled boundary | $1392.75 | $1392.75 |
| Peak sampled arrears | $0.00 | $0.00 |
| Final Fans | 22 | 0 |
| Unavailable finance samples | 0 | 0 |
| New-ledger-transaction cash low | $1392.75 | $1392.75 |

Endpoint values can cover different calendars; use the matched-cycle table for calendar comparisons. Boundary cash low and arrears peak cover each arm's own observed prefix. Transaction cash low includes recorded cash before/after new ledger transactions and boundary cash; it excludes pre-study history and does not assert unrecorded intermediate values.

- **no-loan:** target completed; first rejected action: none observed. Termination detail: none.
- **borrow-500-12:** censored/incomplete; first rejected action: step 1, cycle 27, bank_borrow: Financial action rejected. Termination detail: Financial action rejected.

A malformed policy or command bound is not evidence of a financial blocker. A command rejection must be interpreted from its recorded error and request.

## Matched calendar

Last observed sample at each shared run_cycle; zero-cycle actions use their final observed boundary at that cycle. No interpolation, extrapolation or assumption of equal phase.

| Cycle | Left cash | Right cash | Δ cash | Left Fans | Right Fans | Δ Fans | Left arrears | Right arrears | Δ arrears |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 27 | $1392.75 | $1392.75 | $0.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |

## Matched new release milestones

First post-command sample attaining each new release ordinal; compared launch milestones may occur at different calendar cycles

| Release ordinal | Left Review | Right Review | Δ Review | Left launch cycle | Right launch cycle | Δ launch cycle |
|---|---:|---:|---:|---:|---:|---:|

No new release milestone was observed in both arms.

Initial common releases: 2; retained separately in comparison.json. Unmatched releases are retained per arm, not imputed.

## Provenance and limits

- Mechanics identity: `01c1d31744a0a16c128215518657d0e39dc3c6f0c54a07c29ffca90557d32d33`
- Godot: 4.7.1-stable (official)
- Overall original run succeeded: False. Retained failed cases are allowed in this report.
- Local source/input/artifact consistency checks; no signatures or malicious-tampering guarantee. Variant tapes are not decoded here; use the separate exact replay command.
- Independent campaigns; no winner, balance approval, human feel or shared-world AI claim

Full samples, exact requests, source manifest and replay artifacts remain in the original bundle. comparison.json retains milestone cash/Fans/arrears, Features, queue and artifact hashes.
