# Crown two-hand planning and conservative redraw — pre-run plan

2026-10-24. User authorizes stronger first-hand planning and limited legal redraws with rewards unchanged. Private design experiment only; Crown rules remain OPEN. Prior [planning evidence](CROWN-PLANNING-FINDINGS-2026-10-24-v1.md) and [CP1 handoff](CROWN-PLANNING-HANDOFF-2026-10-24-v1.md) motivate this follow-up.

## Source and hypothesis

Shared dirty `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. Fork `crown-planning-brief-v1` into `crown-lookahead-brief-v1`. Preserve original baseline/ancestry and all prior evidence. Only private project delta: expose a detached `planning_pool` of already-owned, acceptance-eligible, currently unexhausted Feature definitions and public Core Pass definitions (type, scores, Scope, renewable flag). No RNG/deck order, future draw, or unseen content is exposed. Existing priorities and available redraw tokens are observable. Record exact source identities and any canonical drift.

Hypothesis: two-hand lookahead using legal refill distributions will make better first-hand choices; conservative redraw will preserve currently achievable final grade and sometimes improve it. No altered rewards, targets, hand counts, unlocks, finance, saves or game RNG.

## Fixed cases and bounds

Seeds4417,4418,4419, original legal Action/Cult Following recipes/Studio identities and existing development route; Crown cash precedes separate Briefs. Three Briefs maximum, stop accepting atR20, six releases and200 commands per case. Preserve known4419 pre-Crown affordability failure.

Six arms: `balanced` (old no-redraw control), `balanced_redraw` (old aggressive redraw), `skip`, `balanced_safe` (old first-hand policy + conservative redraw), `lookahead` (new first-hand policy, no redraw), `lookahead_safe` (new first-hand policy + conservative redraw). Run nine control cases first, then nine new-policy cases using the same frozen variant/policy. Each isolated batch has240-second process timeout. No seed/budget changes or outcome-driven tuning; retain failures/timeouts. A compile/structural defect permits a documented separately versioned correction, not a concealed rerun.

## First-hand planner

Enumerate all35 actual visible quartets. For every choice, score its real first-hand synergy, keep the other three actual cards, and evaluate32 hypothetical four-card refills. Refill draws follow observed category priorities, definition-ID sorting, within-category uniform choice, finite exclusion and renewable Pass rules. Every visible finite Feature is reserved during refill, whether played or retained; previously exhausted Features are absent. Thus the same hypothetical refills can be shared across all first-hand choices. Each second-hand scenario exhaustively evaluates all35 quartets with actual synergy and the unchanged integer grade.

The planner uses its own deterministic Park–Miller sequence, initial20261024, update `x=(16807*x)%2147483647`, roll `x/2147483647`, reset per first-hand decision;32 scenarios, four replacements, two rolls per replacement. This never reads or advances game RNG and is independent of the campaign seed. Rank first hands by `sum(final_grade)*1000000 + full_scenarios*10000 + positive_scenarios*100 - first_hand_spread`; stable visible-order ties. Log all35 ranks and sampled refills for independent auditing. This is sampled expectation, not exhaustive optimality or human accessibility evidence. First-hand planner assumes no later redraw; the factorial comparison isolates the added redraw effect.

## Conservative redraw

Only final hand, actual budget>0, fewer than two tokens spent in this Brief, best grade<10000. Keep the current best four tokens untouched. For each of the other three tokens, enumerate all legal same-type replacements from the observable pool, excluding currently visible finite definitions and the replaced definition, matching category priorities and uniform definition probabilities. For each replacement exhaustively score the best final quartet. Choose the token with greatest expected final grade, stable visible-order ties; redraw only for strictly positive expected improvement. Recompute after each draw. No refresh/purchase, no first-hand redraw, no speculative command, and no knowledge of which replacement will actually arrive. Rejecting a command retains a failed case.

Because the previous best quartet remains legal and visible, the maximum available grade after each conservative redraw must be at least its prior value. Assert this independently, alongside actual one-token debit, unchanged scores/cycle, zero currency/Investment and final saved redraw count. Tokens can regenerate later; report spend as well as final stock. This guarantee is local to that decision, not whole-route superiority: extra draws change later Contract RNG.

## Measurement and acceptance

Check initial complete state/RNG and common first-Brief boundaries across arms/batches. Compare controls with prior actual outcomes/RNG and entire durable saves without bypassing identity fences. Report each Brief's grade/standing, full/partial/zero counts, R20 timing, spent tokens, commands, cash/arrears, release/calendar costs and planning runtime. Independently verify refill legality, rank calculations, preserved best quartet, immutable P1 awards and finite Feature use. Retain known intake failure and any new errors.

Replay `lookahead-4417` and `lookahead_safe-4418` in fresh processes. Cold Studio Continue `lookahead_safe-4418` to release7,40 commands,240seconds; exact initial state/RNG and preserved results/standing required. If the named case is incomplete, retain it and replay its failure if supported; do not silently substitute a favorable case. Snapshot/manifest checks must prove reward/source rule files unchanged from the parent. GUI/native/exported migration/ownership/full-suite acceptance remain outside this experiment.

Stop after this bounded experiment and verification. Do not change the reward formula even if access still missesR20. Write findings/review handoff and reconcile the already-authorized CP1 TODO entry with actual results, preserving other work. Crown activation still needs explicit design approval.
