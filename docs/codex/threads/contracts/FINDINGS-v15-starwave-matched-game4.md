# Starwave matched Game 4 continuation v15

2026-10-09 (America/Los_Angeles). **Completed bounded read-only evidence; no new design approval.** This study follows the [cross-specialty first pass](FINDINGS-v14-starwave-cross-specialty-screen.md). It asks what the approved three-cycle Starwave choice costs relative to starting Game 4 immediately, using the three real foundations that actually earned the offer. The ACTIVE/TRIAL terms stay $0 acceptance, a maximum $2,240 on hand 3, and 0 Starwave Promotion.

## Source, setup and audit

- Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. Gameplay came from the complete frozen native-v3 source pin, original manifest SHA256 `8922fd57eac43ec6ec04160bce01ca8f9712d4c05d396e7ebff721741953e8db`, including its original dirty overlay. The final separate analysis copy and six-arm manifest are in [sim-v13 repair v4](sim-v13/repair-v4/README.md); its selected-file manifest SHA256 is `91660036cab8e7c85ceffca9676635d9649038cc534036d4c3977e89a1d9a195`. Source, input and analysis-script hashes stayed fixed through all final arms. The moving repository gameplay tree was not run or edited.
- The [predeclaration](sim-v13/PREDECLARATION.md) fixed Action 1104, Puzzle 4417 and Racing 1104, using the exact byte-pinned v12 before-Starwave payloads. Each cohort had independent Starwave and skip arms hydrated from identical typed checkpoint state and initial RNG. Starwave completed three live hands; skip left the offer pending and began Game 4. Both arms used the same native development policy, matched project seeds and Review-variance hook, no injected release result, and the actual Bank/payroll/rent/sales/Promotion state. Game 4 launched at cycle 75 with Starwave and cycle 72 without it. Common completed-cycle endpoints were 75, 77 and 79.
- The first analysis script failed to parse before any legal action. Repair v2 and v3 reached Game 4 but stopped at an analysis-adapter Game 5 priority commit; their [preserved traces](sim-v13/) are technical failures and are excluded. Repair v4 follows the pinned native Starwave route's Game 5 priority sequence. Its [independent audit summary](sim-v13/repair-v4/audit-summary.json) passed **32,640 checks**: all six final native arms and all three matched pairs valid; exact checkpoint/RNG parity, legal actions, three-hand payout, finance journal, settled sales and source provenance reconciled. Each arm's exact command, Godot log, full native trace, stop status and after-source check is under its cohort/arm folder.

## Matched results

The Game 4 release within each pair had the same Review, launch Awareness and inherited Neon Promotion. Those were Action **8.1 / 218 / 18**, Puzzle **7.2 / 199 / 11**, and Racing **6.5 / 223 / 20**. The Promotion came from existing Neon awards; Starwave itself granted none. At every common endpoint, both arms had valid finance ledgers and **no overdue original bill**.

All differences below are **Starwave minus skip** at the same completed calendar cycle. Settled sales are cumulative portfolio cash settlements, separate from the direct Contract receipt. Game 5 work is completed project cycles in the active Game 5 project.

| Cohort | Cycle | Cash difference | Settled portfolio sales difference | Game 5 work difference |
|---|---:|---:|---:|---:|
| [Action 1104](sim-v13/repair-v4/action-1104-starwave/matched-route.json) | 75 | −$3,530.65 | −$6,335.65 | −2 cycles |
| Action 1104 | 77 | −$2,800.73 | −$5,272.73 | −3 cycles |
| Action 1104 | 79 | **−$216.48** | −$2,517.48 | −3 cycles |
| [Puzzle 4417](sim-v13/repair-v4/puzzle-4417-starwave/matched-route.json) | 75 | −$4,732.81 | −$7,174.81 | −2 cycles |
| Puzzle 4417 | 77 | −$3,591.08 | −$5,916.08 | −3 cycles |
| Puzzle 4417 | 79 | **−$751.33** | −$2,671.33 | −3 cycles |
| [Racing 1104](sim-v13/repair-v4/racing-1104-starwave/matched-route.json) | 75 | −$2,450.84 | −$5,146.84 | −2 cycles |
| Racing 1104 | 77 | −$1,867.70 | −$4,293.70 | −3 cycles |
| Racing 1104 | 79 | **+$217.90** | −$1,902.10 | −3 cycles |

At cycle 79 the direct earned Starwave receipts were Action **$2,220**, Puzzle **$1,920** and Racing **$2,120**. The audited cash reconciliation is receipt plus settled-sales difference plus other cash movement: Action `$2,220 − $2,517.48 + $81 = −$216.48`; Puzzle `$1,920 − $2,671.33 + $0 = −$751.33`; Racing `$2,120 − $1,902.10 + $0 = +$217.90`. The [audit](sim-v13/repair-v4/audit-summary.json) records both arms' absolute balances, credit, bills, earned entitlement and Game 5 Scope/Core at every endpoint. A positive Racing cash difference is not equal progress: its skip arm is three Game 5 cycles ahead.

## Interpretation and recommendation

Across these three successful, solvent foundations, the Contract receipt narrowed the early cash gap by cycle 79. It did not remove the three-cycle Game 5 work lag or the cumulative settled-sales deficit. The cash sign differs by cohort. This is evidence of a real timing tradeoff under one fixed policy, not a claim that the $2,240 cap is universally generous or insufficient. It also provides no advance-rescue case: all starting checkpoints had over $15,000, and neither paired arm had original arrears at the measured endpoints.

The sample excludes the five specialties whose declared routes never earned Crown, uses one route policy and at most two seeds, and fixes Review variance through the inherited verifier hook. It stops at cycle 79, before either arm releases Game 5. Later sales, player preferences, alternative Store/Bank decisions and rendered/exported interaction remain unmeasured. These comparisons cannot isolate roster effects from matched Genre rating effects and do not establish final balance.

**Recommendation:** retain the approved ACTIVE/TRIAL Starwave terms while the implementing thread finishes its separate maintained/rendered/exported acceptance. Do not add a Starwave advance or alter payout from this small solvent sample. If further design evidence is useful, the next targeted question is whether the Game 5 work lag persists through a common *post-Game-5 settlement* endpoint, using these same three pairs and no changed policy. A separate legal route-policy screen would be needed before making a cross-specialty access claim. Any numerical revision requires explicit user review and approval.
