# Crown visible planning and bounded redraw — pre-run plan v1

2026-10-24. **DESIGN experiment; Crown rules remain OPEN.** User authorizes the follow-up and a subsequent internal TODO update. No computer control, canonical gameplay changes, commits or pushes.

## Hypothesis and source

The previous current-hand policy missed R20 in three Briefs. Considering visible retained cards and spending at most two legal redraw tokens per Brief may improve accessibility without changing its rewards. This is a strategy screen, not a proof of optimal play or a balance approval.

Fork `simulators/crown-balance-brief-v1` into `simulators/crown-planning-brief-v1`. Preserve its original baseline and ancestry. Shared branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty worktree; P4 is now accepted locally, but this controlled comparison deliberately retains the prior intermediate-P4 baseline. Record exact identities from the runner. Reconciliation with accepted P4 is required before adoption. The sole added runtime observation is remaining redraw tokens; no reward, draw, finance, progression or save rule change.

## Cases fixed before execution

Seeds **4417,4418,4419**, same legal Action/Cult Following/Fantasy recipe, Studio identity and development policy as the prior study. No injected unlocks, finances, cards or checkpoints from a different revision. Five arms per seed:

1. `balanced`: previous policy, no redraw (control).
2. `retained`: retained-card forecast first hand; same final-hand exhaustive selection, no redraw.
3. `balanced_redraw`: control plus bounded final-hand redraw.
4. `retained_redraw`: forecast plus the same redraw rule.
5. `skip`: unchanged development, skip Crown Briefs.

Three Briefs maximum, stop accepting at R20; six releases, 200 commands per case, 240-second runner timeout. Keep seed4419's prior pre-Crown affordability failure in the cohort. Do not expand bounds or replace seeds to improve results. Rejected, incomplete and timed-out records remain evidence.

## Exact policy assumptions

All policy inputs are detached current observations. No future RNG or unobserved catalog inspection.

Control: enumerate all35 visible quartets; rank hand1 by `grade*1000000 - sum(max(0,4-H_i))*1000 - spread`; final hand by `grade*1000000 + completion*100 - spread`. First visible quartet wins exact ties.

Retained forecast: for each first-hand quartet, resolve its actual synergy and retain the other three visible cards. Enumerate all8 subsets of those retained cards as possible second-hand inclusions. Add their ordinary2x contributions to the projected first-hand scores. Fill remaining slots, arithmetically only, with the mean ordinary2x contributions/Scope of the seven currently visible cards. Rank by the best forecast `grade*1000000 + actual first-hand grade*100 - actual spread`. Forecast grade uses continuous completion/promise, capped to10000; official scores/awards remain the unchanged integer runtime. This is an uncertain observed-pool heuristic: imagined mean cards are not legal draws, no future cards are materialized, finite-pool exclusion and future synergy are not forecast. Final-hand play always uses four actual visible tokens and the exact integer formula.

Redraw: only on final hand, only if current best grade <10000, observable budget >0 and fewer than two tokens used in this Brief. Replace one token at a time. Among the current best quartet choose the card whose ordinary2x Core contribution has greatest dot product with `(projected Core - projected Core mean)`; tie by quartet order. This targets excess contribution; it does not know whether a replacement will help. Re-enumerate after each redraw. Stop at full grade, two tokens, or depleted budget; never purchase/refresh tokens or add productive cycles. Verify actual debit and unchanged scores before proceeding. A rejected redraw is retained and stops that case.

## Measurements and gates

Report actual completed/partial/zero Briefs, individual grades and P1 Reputation, R20 access and first cycle/release, successful redraw tokens and remaining resource, accepted/rejected commands, cash/arrears and matched release/calendar opportunity costs. Verify same initial complete state/RNG across arms, shared first-Brief boundaries, finite Feature legality, two hands, zero currency/Investment awards, distinct release-linked offers, immutable ledger awards and saved redraw counts.

Run all existing behavior controls first within the same frozen batch ordering, then candidates. Replay `balanced-4417` and `retained_redraw-4417` in fresh processes; cold Studio Continue for `retained_redraw-4417` to release7 with40-command cap, verifying full initial state/RNG and stored completed Briefs/standing. Runtime/import errors trigger bounded diagnosis and a separately versioned retry with failures retained; no silent policy tuning. Do not broaden testing absent a concrete defect.

If strategy still misses access, recommend separate DESIGN review of progression/award structure. Do not automatically reduce thresholds. TODO should distinguish completed private evidence from proposed gameplay and include accepted-P4 reconciliation, prospective saves, ownership and future graphical/exported acceptance.
