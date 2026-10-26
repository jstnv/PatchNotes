# Publisher Reputation formula shape — predeclaration v1

2026-10-18 (America/Los_Angeles). **OPEN candidate study.** The user asked this Contracts thread to develop formulas for future publisher-reputation Contract types. This study compares pure arithmetic. It does not prototype gameplay or approve a reputation system.

## Source and question

- Checkout: `main` HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; dirty worktree, with concurrent changes preserved.
- Current challenge matrix: `../../findings/queue-20261018-v1/challenges-v3/verify_contract_challenge_matrix.json`, SHA256 `4025887E0BBCD537DC14B5464D07204B39569D9A92BF227A7CBF16B513938B82`. Its verifier source hash is `B77B5F3238016F79795EED5F5FA06AFEEADB2F9CF952D75135417709FC0A4194`.
- Current scoring source identities: `patch-notes/scripts/contracts/contract_challenges.gd` SHA256 `6BE5F579DB1CC556522FFD00D772FCCD3EE1282A9EEF0D423448AF6BF54114A9`; `contract_definitions.gd` SHA256 `FE44F875AF7670BEEE5039CBCD2D3746C89D5345EB6E9427AB96AA5015E81E94`.
- Hypothesis: the weaker of completion and promise grade is a clearer reputation signal than averaging them (which rewards a missed promise) or multiplying them (which double-penalizes two moderate outcomes).

## Bounded comparison

Let `C` be a normalized Contract completion score in integer basis points, `G` the normalized fulfilled-promise grade in basis points, both clamped to `[0,10000]`. The future Relationship Brief has no defined legal scoring path yet; `G` is an interface proposal, not automatically the current challenge bonus grade. For an illustrative maximum `M=10` reputation points per brief, compare integer-floor formulas:

1. **Weakest promise:** `floor(M * min(C,G) / 10000)`.
2. **Product:** `floor(M * C * G / 100000000)`.
3. **Average:** `floor(M * (C+G) / 20000)`.

Use the full 5×5 grid `C,G ∈ {0,2500,5000,7500,10000}`. Also project the observed verifier challenge grades into the `C=10000` upper-bound slice, labeling them as projections rather than actual Relationship Brief outcomes. The matrix includes no completion score and cannot establish actual reputation gains or legal Brief reachability. Do not silently infer `C` from Scope/Core or treat equal cases as same starting state. Keep the existing Neon partial/miss infeasibility as a limitation.

No seeds, policies, saved state, RNG, player action, or headless runner are involved: this is a deterministic arithmetic comparison. Measurements: zero-promise and zero-completion behavior; both-midpoint outcome; one-full/one-half outcome; monotonicity; maximum; distinctive output count across the grid; projected gains for observed full/partial/miss grade classes. `M=10` is an analytical scale only. Starting balance, cap, cadence, losses and unlock thresholds are outside this test.

## Procedure and stop conditions

Read the pinned matrix and compute the declared formulas in PowerShell, writing one new CSV in this thread folder. Check matrix hash before calculating. No release/command budget applies because no game is run; limit output to this 25-cell grid and the 10 existing verifier cases. Stop if source hash changes, any input lies outside `[0,10000]`, any formula leaves `[0,M]`, the matrix lacks expected grade classes, or the arithmetic audit fails. Retain and report such a failure; do not alter inputs, `M`, or case coverage to make the result favorable.

Recommendation must separate formula shape from numerical magnitude and from approval. Existing cash/Promotion Contract rewards and the independent cash brief remain unchanged. A later headless candidate needs an approved, legally reachable Relationship Brief promise, offer cadence and settlement interface before it can test gameplay.
