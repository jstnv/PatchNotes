# Banking liquidity simulator session — 2026-10-11

Branch `main`; HEAD at plan/source capture `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. The shared worktree was already dirty and other design threads edited their own records concurrently. This session touched Banking-owned documents, policies, configs, the private `education-bank-quote-v3/project/` observation, and one minimal shared TODO disposition. It did not edit canonical `patch-notes/`, other threads, `.codex-godot-temp` or player saves; no commit/push.

## Changed files and retained outputs

- Added [plan](2026-10-11-liquidity-study-plan-v1.md), [finding](2026-10-11-liquidity-finding-v1.md), [handoff](HANDOFF-LIQUIDITY-v1.md), this log, and thread README links.
- Created [v3 private simulator](simulators/education-bank-quote-v3/variant.json) from v2. Added only a read-only $1,000/12 Bank quote to `project/scripts/simulation/campaign_session.gd`.
- Added `simulations/build_liquidity_configs_v1.py`, `liquidity_admit_policy_v1.gd`, `liquidity_pair_policy_v1.gd`, corrected input-only `liquidity_pair_policy_v2.gd`, `run_liquidity_verifiers_v3.py` and `analyze_liquidity_v3.py`. Retained all generated configs, source-frozen run bundles, six comparison reports, twelve replay folders, three successful reductions, the initial failed reducer attempt, verifier logs and `liquidity-summary-v3.json` under `simulations/`.

## Commands, checks and failures

The [finding](2026-10-11-liquidity-finding-v1.md) gives exact primary commands, executables, hashes and output links. Four fresh first-release cases completed c13. Four c16 prefixes stopped at their expected five-command bound after all legal actions. V2/v3 state digests, cash and command counts matched in all four cohorts at both boundaries. Three admitted-Research prefixes stopped at their declared bounds at c16, cash $735.52/$485.52/$833.77, no arrears. The fourth rejected its fifth admission because 16-Bit Music's 8-Bit Music parent was absent; a one-command fresh-process reduction reproduced this failure.

The first nine-arm comparison batch produced `invalid_policy` before commands because the policy factory treated JSON floats as invalid integer amounts. Its frozen bundle remains. Policy v2 validates exact whole-cent numeric values without changing the planned actions; a separate new-output rerun accepted all loan requests and recorded nine rejected game-two actions. The three loan/no-loan/$1,000 triplets had identical starting state/RNG; none released game two. Six comparison reports mark `both_cases_completed=false`. The accepted command counts show zero queued Research without a loan, one after $500, and one or two after $1,000. Graduate4417/$1,000 accrued $199.25 overdue at c20; all other endpoints had $0 overdue. Two additional fresh-confirmed reductions reproduced representative unaffordable-hand and calendar blockers.

Twelve `tools/simulate.py replay` runs in unique private folders passed `ok=true` and `telemetry_verified=true`; failed-arm replay confirms only accepted command prefixes, while reductions confirm the actual rejections. Six focused private-project checks exited 0 without script errors or printed failures: Campaign Session 81 steps/55 reentrant, Finance Observation 108 checks/21 comparisons, Bank Loan 14,112 checks, Feature Research, Research Integration and Education Atomicity 36 checks. `analyze_liquidity_v3.py` passed three triplets/nine censored arms/twelve replays. The v2 Education Debt/Edges external fixture issue was not retested as a full pass.

## Disposition

Current Bank rules worked as implemented in this stress route: both $500 and $1,000 quotes qualified, and loans unlocked queued Research. The deliberately depleted Studios could not finish game two under the declared four-hand policy, and the larger Graduate loan incurred arrears. This cannot establish a net loan benefit or a new balance rule. The [handoff](HANDOFF-LIQUIDITY-v1.md) frames a reserved-cash, build-capable follow-up for DESIGN review; PN Implementation has no action.
