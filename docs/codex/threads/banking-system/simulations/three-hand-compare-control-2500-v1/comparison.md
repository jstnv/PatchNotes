# Paired simulation observations

Pair: **control-90210-larger-v1-three-hand**. Delta convention: **right minus left**.

This is a bounded observation report. It does not select a winner or approve balance.

## Case status and observed limits

| Measure | Left | Right |
|---|---|---|
| Case / arm | control-90210-no-loan / no-loan | control-90210-borrow-2500-12 / borrow-2500-12 |
| Termination | rejected_policy_action | completed |
| Commands | 11 | 23 |
| Final cycle | 22 | 27 |
| Releases / target | 1 / 2 | 2 / 2 |
| Cash low at sampled boundary | $126.84 | $402.80 |
| Peak sampled arrears | $0.00 | $0.00 |
| Final Fans | 32 | 33 |
| Unavailable finance samples | 0 | 0 |
| New-ledger-transaction cash low | $126.84 | $402.80 |

Endpoint values can cover different calendars; use the matched-cycle table for calendar comparisons. Boundary cash low and arrears peak cover each arm's own observed prefix. Transaction cash low includes recorded cash before/after new ledger transactions and boundary cash; it excludes pre-study history and does not assert unrecorded intermediate values.

- **no-loan:** censored/incomplete; first rejected action: step 11, cycle 22, development: Unaffordable hand. Termination detail: Unaffordable hand.
- **borrow-2500-12:** target completed; first rejected action: none observed. Termination detail: none.

A malformed policy or command bound is not evidence of a financial blocker. A command rejection must be interpreted from its recorded error and request.

## Matched calendar

Last observed sample at each shared run_cycle; zero-cycle actions use their final observed boundary at that cycle. No interpolation, extrapolation or assumption of equal phase.

| Cycle | Left cash | Right cash | Δ cash | Left Fans | Right Fans | Δ Fans | Left arrears | Right arrears | Δ arrears |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 16 | $833.77 | $3333.77 | $2500.00 | 23 | 23 | 0 | $0.00 | $0.00 | $0.00 |
| 17 | $833.77 | $2478.77 | $1645.00 | 23 | 23 | 0 | $0.00 | $0.00 | $0.00 |
| 18 | $982.72 | $2794.38 | $1811.66 | 28 | 28 | 0 | $0.00 | $0.00 | $0.00 |
| 19 | $692.72 | $2594.38 | $1901.66 | 28 | 28 | 0 | $0.00 | $0.00 | $0.00 |
| 20 | $752.16 | $2122.56 | $1370.40 | 31 | 31 | 0 | $0.00 | $0.00 | $0.00 |
| 21 | $572.16 | $1982.56 | $1410.40 | 31 | 31 | 0 | $0.00 | $0.00 | $0.00 |
| 22 | $126.84 | $1388.07 | $1261.23 | 32 | 32 | 0 | $0.00 | $0.00 | $0.00 |

## Matched new release milestones

First post-command sample attaining each new release ordinal; compared launch milestones may occur at different calendar cycles

| Release ordinal | Left Review | Right Review | Δ Review | Left launch cycle | Right launch cycle | Δ launch cycle |
|---|---:|---:|---:|---:|---:|---:|

No new release milestone was observed in both arms.

Initial common releases: 1; retained separately in comparison.json. Unmatched releases are retained per arm, not imputed.

## Provenance and limits

- Mechanics identity: `18dc8fb56b762efc4852ecfc5a28da60af4b22b973821fd350251a739079ee84`
- Godot: 4.7.1-stable (official)
- Overall original run succeeded: False. Retained failed cases are allowed in this report.
- Local source/input/artifact consistency checks; no signatures or malicious-tampering guarantee. Variant tapes are not decoded here; use the separate exact replay command.
- Independent campaigns; no winner, balance approval, human feel or shared-world AI claim

Full samples, exact requests, source manifest and replay artifacts remain in the original bundle. comparison.json retains milestone cash/Fans/arrears, Features, queue and artifact hashes.
