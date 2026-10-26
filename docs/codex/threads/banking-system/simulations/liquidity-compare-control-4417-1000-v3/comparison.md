# Paired simulation observations

Pair: **control-4417-liquidity**. Delta convention: **right minus left**.

This is a bounded observation report. It does not select a winner or approve balance.

## Case status and observed limits

| Measure | Left | Right |
|---|---|---|
| Case / arm | control-4417-no-loan / no-loan | control-4417-borrow-1000-12 / borrow-1000-12 |
| Termination | rejected_policy_action | rejected_policy_action |
| Commands | 6 | 6 |
| Final cycle | 20 | 19 |
| Releases / target | 1 / 2 | 1 / 2 |
| Cash low at sampled boundary | $1.60 | $165.53 |
| Peak sampled arrears | $0.00 | $0.00 |
| Final Fans | 0 | 0 |
| Unavailable finance samples | 0 | 0 |
| New-ledger-transaction cash low | $1.60 | $115.52 |

Endpoint values can cover different calendars; use the matched-cycle table for calendar comparisons. Boundary cash low and arrears peak cover each arm's own observed prefix. Transaction cash low includes recorded cash before/after new ledger transactions and boundary cash; it excludes pre-study history and does not assert unrecorded intermediate values.

- **no-loan:** censored/incomplete; first rejected action: step 6, cycle 20, development: Unaffordable hand. Termination detail: Unaffordable hand.
- **borrow-1000-12:** censored/incomplete; first rejected action: step 6, cycle 19, development: Unaffordable hand. Termination detail: Unaffordable hand.

A malformed policy or command bound is not evidence of a financial blocker. A command rejection must be interpreted from its recorded error and request.

## Matched calendar

Last observed sample at each shared run_cycle; zero-cycle actions use their final observed boundary at that cycle. No interpolation, extrapolation or assumption of equal phase.

| Cycle | Left cash | Right cash | Δ cash | Left Fans | Right Fans | Δ Fans | Left arrears | Right arrears | Δ arrears |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 16 | $735.52 | $1735.52 | $1000.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 17 | $735.52 | $880.52 | $145.00 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 18 | $478.87 | $165.53 | -$313.34 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |
| 19 | $368.87 | $165.53 | -$203.34 | 0 | 0 | 0 | $0.00 | $0.00 | $0.00 |

## Matched new release milestones

First post-command sample attaining each new release ordinal; compared launch milestones may occur at different calendar cycles

| Release ordinal | Left Review | Right Review | Δ Review | Left launch cycle | Right launch cycle | Δ launch cycle |
|---|---:|---:|---:|---:|---:|---:|

No new release milestone was observed in both arms.

Initial common releases: 1; retained separately in comparison.json. Unmatched releases are retained per arm, not imputed.

## Provenance and limits

- Mechanics identity: `0629a2fef700cb555d368c80c3342f638cc55150b08ce3416362dc269b9d8691`
- Godot: 4.7.1-stable (official)
- Overall original run succeeded: False. Retained failed cases are allowed in this report.
- Local source/input/artifact consistency checks; no signatures or malicious-tampering guarantee. Variant tapes are not decoded here; use the separate exact replay command.
- Independent campaigns; no winner, balance approval, human feel or shared-world AI claim

Full samples, exact requests, source manifest and replay artifacts remain in the original bundle. comparison.json retains milestone cash/Fans/arrears, Features, queue and artifact hashes.
