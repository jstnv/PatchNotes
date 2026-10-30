# One Action rival Core policy — pre-run plan, 2026-10-27

**Status: DESIGN experiment.** Parent: `one-action-prelude-capital-20261027-v3`, original canonical baseline `91e4244586bd3bf361a0cbfdb14dedcd4c4e09a14c47f1febabc9b0bba705d7b`. Current checkout at declaration: `main` / `f3e0f2b5d35270c879327bc297b389748571feb4`, dirty with concurrent canonical and documentation edits; preserve them. The private child changes only the probe policy, not gameplay. The $25,000 founder capital, 1977 start, fixed 1980 Action Review targets, seven Beta hands and 30/35 owned Scope goals are OPEN trial inputs, not approved rules.

## Hypothesis and comparison

H1: Within the same legal Studio and paid budget, ranking eligible purchases by Action-weighted printed Core per price, while still acquiring at least 30 Scope before the first project and 35 later, improves first and later Reviews over the retained cheap-Scope control. H2: among legal four-card hands with the maximum available Feature count, an Action-weighted printed-Core tie score improves Review further. Null: equal or lower Reviews, later/blocked releases, worse finance, or unchanged purchased/played mix.

- **A control:** retained v3 cheap Scope-per-price shopping and Synergy-proxy hand selection; seeds `4417`, `4423` and retained reports/tapes.
- **B Core shop:** same v4 source and recipe, purchase ranking by `(30*graphics + 30*technology + 20*sound + 20*design) / paid cents`, with a minimum Scope-per-price feasibility term; hand choice remains A. Tie by ID. No free Features.
- **C Core shop + hand:** B purchases; for legal max-Feature hands, rank Synergy proxy plus the same Action-weighted printed Core benefit, using visible candidates only. No peeking at future draw or hidden Bugs.

All arms start a fresh Action/Fantasy Studio with `family_funding`, `cult_following`, seed as named, ten owned Features, 12 owned Scope, 20 Fans and trial $25,000 (exact 2,500,000 cents). Each legal action goes through `CampaignSession`; paid Store/Research, bills, sales and Bank terms remain in force. No change to project Genre/Theme, actual Core or Review calculation, Feature catalog, financing, required Scope, whole-supply exhaustion or QA-first Beta policy. The same seed/initial state and RNG digests must be checked; otherwise no paired inference. Retained v3 mechanics and v4 mechanics identities must match; only debug policy code may differ.

## Bounds, measurements and stopping

Two declared seeds per candidate. Horizon: exactly 72 productive cycles (January 1980 boundary), at most 300 attempted commands and 240 seconds per process. Stop early on rejected command, unaffordable legal continuation, impossible full Scope, or timeout. Do not extend horizon, increase capital or switch seeds to rescue a failure. Run the documented isolated variant runner into a new frozen bundle, then a fresh process per seed and policy; replay one full candidate tape and repeat one case. Retain rejected/incomplete/timed-out cases.

Record variant/source/runtime identities, actual initial state/RNG, purchased Feature IDs and cents, played Features/Passes, per-title release cycle, Review, four Core, Scope and Bugs, cash/Fans/debt/arrears, January state, command count, and elapsed time. Compare each release by ordinal and timing; earlier publication and 8.0+ are desired outcomes, not permission to change the rules. Passing simulation alone does not approve founding money, policy, historical standards or eight-rival adoption. No canonical gameplay, TODO, player saves, `.codex-godot-temp`, commit, push or computer control.

## Pre-run repair addendum

The v4 `core_shop` arms completed with identical release cycles, Reviews, cash, Fans and owned Scope to the v3 control for both seeds; reports have different policy metadata. The v4 `core_shop_hand` arms failed at cycle1 because the private probe accessed nonexistent `CardData.type` while evaluating hands; Godot logs retain the script errors and both outputs stop without a release. Before a hand-policy rerun, fork v5 from v4 and correct only that probe access to `CardData.card_type`. Keep both failed v4 cases. Rerun the same two seeds, start, horizon, command/time limits and policy; do not reinterpret the failed outputs as balance results.

