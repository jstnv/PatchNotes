# Neon focus sensitivity: predeclaration

2026-10-07, America/Los_Angeles. This is a new, bounded question after Task 34; it does not reopen the completed acceptance-advance grid.

## Source and population

- Pin gameplay mechanics and raw evidence to the Task 34 isolated main revision `b84d1a5b4e4957b044b4b52c41553cf611aff3ae`, documented by `../sim-v3/source-manifest.json` and `../sim-v3/README.md`. The shared worktree has later uncommitted changes; do not treat it as the source of these runs.
- Read only eligible `neon-*.json.gz` files named by `../sim-v3/neon-index.json`. Use each completed `publisher=neon`, `advance=0` arm once. Confirm the expected 192 arms and validate recorded automatic focus payout and Promotion before comparing variants. Exclude other advances, no-Contract controls, and ineligible routes.
- Each arm's `scope_if_committed` and four `half_if_committed` scores from its successful second hand are fixed. The four focus slots are Graphics, Sound, Technology, Design in native `ProjectState.CoreScore` order. The v3 automatic rule chose the highest total primary value among owned Primitive features at acceptance, first slot on ties.

## Comparison and stop rules

For each of the four hypothetical acceptance-frozen focus choices, calculate exactly

`f = [20*min(scope/target,1) + 3*min(H_focus,18) + sum(min(H_other,4))]/86`, clamped to [0,1].

At the recommended Neon advance of $0, calculate direct completion cash as `floor(156000*f)` cents and next-successful-launch Promotion as `floor(20*f)` whole points. Compare every choice with the recorded automatic focus on the **same hands**. The arm-wise best/worst are hindsight bounds, selected by direct cash (Promotion tie-breaker, then lowest slot); they are not a realizable acceptance-time player policy. Report ordinary and synergy hand-policy strata and targets 10/11 separately, as well as pooled descriptive values. Count exact-cent wins/losses/ties, payout and Promotion spreads, and auto-best frequency. Preserve the arm identity in a compact CSV for audit.

Stop or mark the analysis invalid if source provenance, 192-arm expectation, recorded automatic focus fraction, cash, Promotion, or completed-hand assumptions fail. Do not reselect cards, redraw, alter finance or sales continuation, infer player behavior, or approve a focus rule. The selection-policy recommendation may be only a design candidate.
