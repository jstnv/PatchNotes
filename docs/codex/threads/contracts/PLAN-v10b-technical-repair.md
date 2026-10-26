# Action Crown v10b policy parse repair

2026-10-11 (America/Los_Angeles). The first [v10 run](sim-v24/current-action-crown-run-01/run-report.json) stopped before any case because the external policy had invalid Beta-block indentation at line 71. The retained Godot log reports a parse error; this is a tool-policy setup failure, not a legal game-route rejection. No case, draw, score or decision was sampled.

Repair only that indentation in `current_action_crown_policy_v2.gd`. Keep the original [v10 plan](PLAN-v10-current-action-crown.md), exactly two cases, seed/traits/selection/rules, 125-command/two-release/240-second bounds and stop criteria. Increment the caller policy version to `2`, use a new input file and new isolated output directory. Do not change gameplay or tune a policy after observing route results. Retain both the parse-failed original and any repaired outcomes.
