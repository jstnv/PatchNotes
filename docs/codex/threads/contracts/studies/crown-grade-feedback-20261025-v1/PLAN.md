# Crown grade feedback and zero-award streaks — preregistration

2026-10-25. User: “Ill let you cook for the grade feedback and zero-award streaks. Keep rewards unchanged.” Delegated design/evidence work; no canonical implementation or activation approval.

## Question and approach

Can visible current-card feedback explain the retained zero results without forecasting draws or misclassifying cap-clipped credit as challenge failure? Recommend selected-hand grade projection, a final-hand-only current-card availability warning, and a non-modal reminder after two consecutive zero-earned Crown Briefs. The reminder threshold is a proposed presentation choice, not an approved reward or eligibility rule.

Use the existing six earned-start routes / eighteen paid Crown Briefs from `early-brief-affordability-20261025-v1`. Source HEAD0132c4dab398a2a94dbeae3caa68a36505fbfa4f; private full identity f7de61169758dcd874972c59e584c7b6a9a36f1fedc4f24b2398f6a2edfdf60f, mechanics9dd1e4551338d38894dace6eb98bc635c38b7e6ec47427b4078cf0ccfe8b0bd6. Reward terms match the approved two-hand Scope9/Core4/spread2/fade6 / up-to10R pilot. Current shared source has later concurrent changes; no claim of current integration parity.

## Fixed evidence and checks

- Read the three completed branch logs, prior analysis/hand audit/verification, actual observed cards, selected tokens, standing, hand/sequence identity and final results. Record input hashes before/after. No new campaign, seed, draw, policy or starting state.
- Reconstruct all36 actual hand projections and compare with engine-recorded projections; all18 final grade/award/standing results must match.
- Enumerate all35 current-card quartets at each hand (1,260 projections total). Never use the next recorded draw to advise the first hand. Only final-hand options may support the “current cards cannot earn Reputation” warning. Suppress that warning on hand1, even if every provisional selection scores zero.
- Derive zero-earned streaks in the eighteen recorded completions, separately for each campaign. Every Crown Brief with requested Reputation>0 resets the count, even when credited zero at cap. Other publishers/products, rejected/incomplete actions and duplicate UI notifications do not create completions. Trusted event order/identity is required; absent or invalid history gives unavailable, not a fabricated streak.
- Check constructed fade boundaries, half points, capped completion/raw over-target values, limiting-factor ties, score increases/decreases, R100 clipping and valid zero-request semantics. Mark constructed cases separately from gameplay observations.
- Before execution: also check the finite arithmetic domain of67 completion numerators ×9 possible balance values (603 integer evaluations). This proves whether a positive pilot grade can round to zero Reputation; it adds no campaign or seed. The named constructed score/selection/history matrix remains below100 cases.
- Check repeated queries and invalid/stale/unrelated/animation-blocked selections, without changing input objects or input files. This is an offline reference contract; it cannot prove a native Godot UI query is state/RNG inert or fast.
- Validate history cases including cap zeros, unrelated product events, duplicate completion identity, out-of-order history, missing source/history, unknown completeness and interleaved publishers. Derive history from the existing trusted relationship ledger; no new persistent streak field, payout event or reward rule.

## Bounds and stopping

One offline analysis invocation, maximum60sec; fixed36 recorded selections/1,260 current-card quartets plus a bounded constructed matrix (at most100 cases). Stop and retain diagnostics on mismatch. Corrections require a named rerun output and recorded reason; do not edit the frozen source or original evidence. No new Godot run or simulator variant is necessary because no runtime addition is being prototyped. Human/native/executable usability and canonical migration remain NOT RUN.

Deliver a versioned design, dated finding and implementation-review handoff with precise copy, state/data contract, acceptance criteria and unresolved gates. Keep approved pilot rewards distinct from proposed feedback. Refresh only this thread's indexes and the existing Crown DESIGN TODO entry, rereading immediately before a minimal edit.
