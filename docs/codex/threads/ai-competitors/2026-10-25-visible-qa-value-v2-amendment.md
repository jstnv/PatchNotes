# Visible QA value v2 compile amendment — 2026-10-25

The v1 private variant's first smoke import failed before any simulator case ran. `import.log` reports undeclared `score` and `candidate` at `rival_trial.gd:106–108`: the best-hand comparison was one indentation level outside the innermost card loop. Retain `sims/rival-visible-qa-value-smoke-20261025-v1` as the failed import evidence; do not interpret it as a design outcome.

Fork `rival-visible-qa-value-20261025-v2` from v1 and indent that comparison block under the `d` loop. Change no other rules, inputs, seeds, bounds or stopping screen from [the pre-run plan](2026-10-25-visible-qa-value-plan-v1.md). Use entirely new smoke/world/replay folders. The numerical scenario score and cash reserve remain OPEN trial values.
