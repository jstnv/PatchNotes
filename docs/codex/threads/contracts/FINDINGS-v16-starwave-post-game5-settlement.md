# Starwave post-Game-5 settlement continuation v16

2026-10-09 (America/Los_Angeles). **Completed bounded read-only evidence; no new rule approval.** The user asked to run the post-Game-5 comparison in this Contracts thread. This extends the three matched [v15 Game 4 pairs](FINDINGS-v15-starwave-matched-game4.md) through a real Game 5 release and two later monthly settlement opportunities. The approved ACTIVE/TRIAL Starwave rule remains $0 on acceptance, up to $2,240 earned on hand 3, and 0 Starwave Promotion.

## Source and method

- Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d` with the frozen native-v3 dirty-source overlay, original [source manifest](../../findings/starwave-implementation-v1/source-manifest-v3.json) SHA256 `8922fd57eac43ec6ec04160bce01ca8f9712d4c05d396e7ebff721741953e8db`. The separate [v14 repair-v3 analysis copy](sim-v14/repair-v3/README.md) has selected-file manifest SHA256 `7fbd2ca4263e0681ed092a747b869cf324dfe0eed34af502985324dcd56c709c`. The pin predates Education activation on the moving checkout. This finding is a longitudinal comparison on that frozen source, **not** a current-main balance claim.
- The [predeclaration](sim-v14/PREDECLARATION.md) fixed Action 1104, Puzzle 4417 and Racing 1104, each with Starwave and skip arms from its exact byte-pinned v12 before-Starwave checkpoint. V13 did not save hydratable cycle-79 checkpoints. Each v14 arm therefore replayed from the original typed payload and passed a separate stop-at-79 gate with complete, integer-preserving equality against the [accepted v13 trace](sim-v13/repair-v4/audit-summary.json), then a second full-process prefix check at cycles 75/77/79 before extension. It preserved the skip arm's pending Starwave offer. The [v14 independent audit](sim-v14/repair-v3/audit-summary.json) passed **60,165 checks** across six native arms and three matched pairs, including source/input/script hashes, legal actions, typed/RNG prefix, finance journal, sales, offer state and original bills. `run.py verify` reported no drift.
- Game 5 used six Design, six Alpha and six Beta hands in **both** arms, with native card/priority/QA/Review handling and no added Store, Bank, hire, campaign or Contract choice. The skip arm had already legally played six Design hands by v13 cycle 79; using six in both arms preserves that prefix. This is **one more Design hand** than the inherited later-game helper's ordinary 5/6/6 budget, so the finding applies to this fixed continuation policy. Game 5 launched at cycle **91** in skip and **94** in Starwave. Legal Game 6 departure and Design hands advanced each arm to common completed cycles **94, 96 and 98**, without waits or injected cash. The later arm's Game 5 actually settled sales at both 96 and 98.
- The first analysis script stopped at a parse gate before legal play because its Beta coroutine was not awaited. Repair v2 replayed legal actions to cycle 79, but an in-engine comparison of large 64-bit JSON integers falsely reported mismatch; exact Python parsing confirmed its prefix was equal. Those [preserved technical attempts](sim-v14/) are excluded. Repair v3 moved equality to the integer-preserving runner, pinned a new disposable copy and ran the final arms. No gameplay source or shared authority was edited.

## Results at common calendar cycles

Game 5 Review matched within every pair: Action **6.8**, Puzzle **6.5**, Racing **5.7**. Launch Awareness was Action **237 Starwave / 236 skip**, Puzzle **220 / 220**, Racing **209 / 209**; the Action point difference is an observed timing/Fanbase consequence, not a forced parity failure. Game 5 Promotion was 0 in all six arms. No original bill was overdue in either arm at cycles 94, 96 or 98.

All differences below are **Starwave minus skip** at the same completed cycle. Settled sales are cumulative cash settlements; the Game 5 column shows that title's cumulative **settled** sales. Game 6 work counts productive project cycles already completed.

| Cohort | Cycle | Cash | Settled portfolio sales | Settled Game 5 sales | Game 6 work |
|---|---:|---:|---:|---:|---:|
| [Action 1104](sim-v14/repair-v3/action-1104-starwave/post-game5-route.json) | 94 | −$5,075.07 | −$7,916.07 | −$7,783.20 | −2 cycles |
| Action 1104 | 96 | −$447.97 | −$3,027.97 | −$2,937.06 | −3 cycles |
| Action 1104 | 98 | **+$390.87** | −$1,874.13 | −$1,811.19 | −3 cycles |
| [Puzzle 4417](sim-v14/repair-v3/puzzle-4417-starwave/post-game5-route.json) | 94 | −$6,855.78 | −$9,216.78 | −$9,139.85 | −2 cycles |
| Puzzle 4417 | 96 | −$1,023.55 | −$3,447.55 | −$3,398.60 | −3 cycles |
| Puzzle 4417 | 98 | **−$134.90** | −$2,090.90 | −$2,062.93 | −3 cycles |
| [Racing 1104](sim-v14/repair-v3/racing-1104-starwave/post-game5-route.json) | 94 | −$3,420.86 | −$6,125.86 | −$6,097.89 | −2 cycles |
| Racing 1104 | 96 | +$299.21 | −$2,216.79 | −$2,202.80 | −3 cycles |
| Racing 1104 | 98 | **+$949.26** | −$1,251.74 | −$1,237.76 | −3 cycles |

The later Starwave arm's own Game 5 settled sales at 96 and 98 were Action **$6,678.31 → $8,944.04**, Puzzle **$7,839.15 → $10,447.54**, and Racing **$5,237.75 → $6,958.03**. These are actual cumulative settlements, not projected launch revenue. At cycle 98, exact cash reconciliation is the original Starwave receipt plus the portfolio settlement difference plus other cash movement: Action `$2,220 − $1,874.13 + $45 = +$390.87`; Puzzle `$1,920 − $2,090.90 + $36 = −$134.90`; Racing `$2,120 − $1,251.74 + $81 = +$949.26`. The [audit summary](sim-v14/repair-v3/audit-summary.json) records absolute cash, earned/settled sales, credit, Fans, offers and original obligations at each endpoint. Every Starwave arm had **3 Game 6 work cycles** at 98 versus **6** in its skip pair.

## Interpretation and recommendation

Two Game 5 settlement opportunities narrowed the early cash deficits: Starwave was ahead in cash in two of the three cohorts by cycle 98 and slightly behind in Puzzle. It still had lower cumulative portfolio and Game 5 settled sales in **all three**, plus three fewer Game 6 work cycles. A cash lead here does not mean the Contract has paid back its production delay. This sample found no liquidity rescue or unpaid original bill; its foundations began solvent with more than $15,000 before Starwave.

The study covers three successful routes under one fixed card/spend policy and the explicit 6/6/6 Game 5 continuation. Five other specialty routes in [v14's preceding reachability screen](FINDINGS-v14-starwave-cross-specialty-screen.md) never earned Crown under their two allowed seeds. Genre and roster effects were not isolated. The source is pre-Education, Review variance was fixed by the inherited verifier hook, and the horizon stops before Game 6 release. Player choice, further title sales, low-cash routes, visual/exported interaction and final balance remain outside this evidence.

**Recommendation:** retain the approved Starwave ACTIVE/TRIAL terms. The new evidence makes the cash-versus-progress tradeoff concrete but supports neither an advance nor a cap change. For the next design discussion, decide whether Starwave is meant to be a solvent studio's cash option that trades about three project cycles for an immediate receipt, or whether access and usefulness for cash-constrained studios should be a separate target. Any numerical change requires a new legal low-cash case and an explicit user ruling. The implementing thread retains the rendered/exported acceptance work; no shared To Do List update follows automatically.
