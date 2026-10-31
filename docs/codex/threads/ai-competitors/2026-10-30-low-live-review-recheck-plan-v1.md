# Low live-rival Review recheck — pre-run plan, 2026-10-30

**Question:** Why do current normal-save rivals publish roughly 0.9–1.3 games even when a player with a small founder pool can surpass them? The screenshot is a user-observed live save with unknown seed/actions, so this probe will reproduce the current two-rival mechanics under declared legal starts rather than claim an exact replay of that save.

## Hypothesis and comparisons

The active two-rival trial inherits the player founder pool and three historical extras per rival, but retired Audio is absent from future project supply. Both rivals therefore have only about 14 printed playable Scope against required 30 and never purchase Store Features. Their Scope multiplier is the dominant hard ceiling; Core fit and remaining Bugs further reduce actual Reviews. Compare each rival's cycle-0 future supply with required Scope, then its actual released Scope/Core/Bugs/production/Review. Compute the absolute same-supply bound `10 × min(supply,30)/30 + 0.5`; this is formula-only and not a legal reachable Review. Do not mistake it for a proposed score floor. The separate eight-rival 1977 founder candidate is held and is not a matched state or an approved fix.

## Legal cases, measurements and bounds

- Fresh ordinary Action player Studio recipes at seeds `4417` and `5607`, no Traits or grants. Activate the current two-rival `RivalTrial` at January 1980 cycle 0. Advance only the player's calendar by legal productive boundaries through cycle 18; no player project or Review is generated. Rivals use their stock policy and `RivalTrial.ZERO_STEPS=12` per boundary.
- Version a private diagnostic variant from the current-source `cycle-zero-market-visibility-20261030-v1` variant. Only its private diagnostic script may change. Freeze with two one-command cases through `tools/simulate.py run --variant`; those intentionally stop `INCOMPLETE` before a release. Use the frozen source in two fresh isolated probe processes.
- Capture per rival: future eligible Feature IDs and printed Scope, opening cash; each live release's cycle, Review, Scope/requirement, four Core and frozen standards, remaining Bugs, production rating, development cycles; phase/action counts, blocked reasons, cash; and world Market fact count. Recalculate the formula-only same-supply bound and exact production × Scope × Bug term. Verify owner release ledgers agree with world rows, source identity and JSON repeat hash.
- The runner and each probe have 240-second limits. Stop on any invalid new Studio/world, calendar or ledger mismatch, script error, timeout or source identity drift. Keep failed and incomplete cases. Do not change seeds, money, cards, AI decisions, limits, or Review rules to obtain a preferred result.

**Disposition boundary:** This is diagnosis of current behavior, not authorization to change canonical gameplay, adopt the held founder candidate, lower Genre standards, or test player Reviews.
