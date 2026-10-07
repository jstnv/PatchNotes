# Fanbase linear gain trial decision v1

2026-10-06, America/Los_Angeles. Source: the user's “Yeah lets keep it linear” after the [gain-curve comparison](2026-10-06-gain-curve-review-v1.md) and recommendation to retain the branch's linear shape as the trial.

## Ruling

- **ACTIVE/TRIAL shape:** Keep a linear increase in fan gain with Review above 5.0 for the next playable comparison. The `bd450a9e4e8d83ece1478cdf5a16526432e36cce` Fanbase branch already uses this shape; no gameplay change is requested to select it.
- **LOCKED boundary retained:** Review exactly 5.0 gives zero gain or loss. The linear gain rule applies only above 5.0; below-5.0 losses follow the separately approved incremental exposure structure.
- **OPEN numbers and assumptions:** The branch's 8% conversion scale, 1.5 quality cap, eligible-unit reserve, rounding, loss rate, cross-title buyer overlap and fan-to-Awareness curve remain provisional. The user chose the shape for a trial, not final balance values or a merge.
- **Alternative:** The square-root quality shape is not selected for the current trial. Its fixed-sales overlay remains comparison evidence, not an implementation instruction.

The [legal route replay](2026-10-06-current-branch-replay-v1.md) measured a difference at Review 6.1, but did not include human balance feedback. Retain the branch's existing trial behavior, observe a near-5 positive and high-Review route later only if tuning still needs it, and avoid duplicating the existing fan counter or branch code. No new TODO entry, gameplay edit, merge or push follows from this decision alone.
