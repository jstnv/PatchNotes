# Action Crown v10c typed-array policy repair

2026-10-11 (America/Los_Angeles). The [v10b run](sim-v24/current-action-crown-run-02/run-report.json) loaded the policy, accepted two setup commands in each case, then failed on a policy-only GDScript typed-array assignment at line 46 before any card hand or release. These two `malformed_policy_decision` cases are retained as technical failures, not legal game access misses.

Repair only the GDScript assignment by initializing a typed first-four array and assigning the existing `_best_four` output in a separate `if` for Game 2. No strategy, seed, action, trait, bound or stopping condition changes from [v10](PLAN-v10-current-action-crown.md). Use policy version 3, a new input file and a new isolated output. Do not drop the two earlier failed run bundles.
