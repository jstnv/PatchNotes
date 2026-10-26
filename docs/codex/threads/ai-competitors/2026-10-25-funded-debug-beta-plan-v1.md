# Funded Debug Beta comparison plan — 2026-10-25

**DESIGN/TRIAL experiment; no canonical rule approval.** Branch `main`, intake HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. Preserve all existing edits and `.codex-godot-temp`.

## Hypothesis and cases

The two-hand ACTIVE/TRIAL rival exits sometimes leave at least two public known Bugs with a visible Debug card. A single additional funded legal Debug hand may improve Review without materially weakening release cadence or player-facing market pressure. Compare the frozen two-hand shadow baseline `rival-beta-shadow-runway-20261025-v1` with a new private `rival-funded-debug-beta-20261025-v1` variant forked from it. Change only the private rival policy. Existing Design/Alpha, Beta card, finance, Review, market and player route rules remain identical.

Candidate rule at an otherwise legal Beta exit: if public known Bugs >=2, current visible pool contains Debug, and current cash after the next known rent/payroll/overdue amount is at least a trial $1,000 reserve, select a legal four-card hand containing Debug and no Bank action. Choose the hand maximizing guaranteed known-Bug removals, then Marketing output, then actual Insider payout, then token order. An active loan, education schedule, or unmodeled liability vetoes extension for this first cohort trial. Reassess after each accepted hand; exit when the condition fails. $1,000, the Bug threshold, valuation and veto are experimental and **OPEN**. The actual Beta command settles effects. Do not inspect hidden Bugs or future draws in the policy.

## Starting state, bounds and measurements

- Two independent fresh legal new games per arm, seeds 4417 and 4418, Action/Fantasy player route, candidate mode 0, arm B. Require each same-seed arm's initial full-state digest and typed RNG to match; regenerate the starting prefix on each revision. No cross-revision checkpoint transfer. The two-hand baseline worlds are `sims/rival-beta-shadow-4417-20261025-v1` and `sims/rival-beta-shadow-4418-20261025-v1`, each already completed at eight player releases/144 player commands/cycle 56.
- Isolated runner limits: up to 210 player commands, eight player releases, cycle 64, 12 zero steps, 480 seconds per world process. Smoke limit 240 seconds. Do not change these bounds or seeds to improve the result. Stop on source/import/legality failure, initial-state mismatch or process timeout; retain the failed output. If first world passes, run the second regardless of whether it helps the hypothesis.
- Measure additional accepted Beta hands, public known Bugs at exits and releases, Reviews, 6.0+ and 7.0+ counts, rival release count/timing, player units/revenue and rival market exposures at the common cycle-56 boundary, cash/arrears/debt, and wall/CPU policy cost. A delayed title is a real cost. Report the candidate's full bounded result separately if it reaches eight releases after cycle 56.
- Run source-pinned smoke, both worlds if legal, one fresh-process exact replay and one Studio-only Continue for a representative candidate world. Retain rejected/incomplete/timed-out cases and process receipts. Compare source differences and starting RNG explicitly; matching seeds alone are insufficient.

No canonical gameplay, shared TODO, player save, commit or push. A successful run is evidence only; the numerical policy needs design review before an adoption handoff.
