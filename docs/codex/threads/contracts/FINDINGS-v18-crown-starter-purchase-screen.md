# Crown access through legal starter purchases

2026-10-09 (America/Los_Angeles). **Completed bounded read-only evidence; no new rule approval.** The [v18 predeclaration](sim-v18/PREDECLARATION.md) fixed one zero-cycle starter-shopping policy for Adventure, Role-Playing, Strategy and Simulation before any route ran. Each primary seed 1104 succeeded, so the conditional 4417 fallback was correctly unused. This answers a narrow Crown access question raised by the [v17 slow-first screen](FINDINGS-v17-crown-slow-first-screen.md).

## Source and method

The isolated Godot 4.7.1 runs used frozen native-v3 source from `main` `41c87c76fb4d3c06a5332d93f0e7b0997007475d` plus its recorded then-dirty overlay. [Original source manifest](../../findings/starwave-implementation-v1/source-manifest-v3.json) SHA256 `8922fd57eac43ec6ec04160bce01ca8f9712d4c05d396e7ebff721741953e8db`; [v18 selected manifest](sim-v18/source-manifest.json) SHA256 `afe10217bdc1041c1a4f63abfbef3405a8f956095645fe3075551579e62133d6`, 748 byte-verified files. Copy: `C:\Users\64jus\Downloads\Patch Notes Design Folder\contracts-starter-buy-v18-source-copy`. The source predates Education activation on moving `main`. Repository gameplay and the original pin were not run or edited.

The only change against each [v12 same-specialty/seed route](sim-v12/) was native optional Primitive purchases before Game-1 departure. The fixed policy sorted available offers by printed Scope per quoted cent, stable ID tie break; bought until the owned starter roster reached Scope33 or the quoted spend would exceed $1,500. Every route actually bought three cards for **$1,350**, with zero cycles. All other choices retained early 3/4/4 Game 1, slow 5/6/6 Games 2–3, synergy/mixed/QA selection, matching Project Genre, the same three Traits, contract-deal seed 31104, real Bank quote/hire and live publisher actions. No extra seed, card, cash, Review or offer was injected.

The [independent audit](sim-v18/audit-summary.json) passed **105,371 checks** over four legal routes. It verified source/import/driver hashes, deterministic quote order, exact Primitive price and cash/owned-ID/zero-cycle changes, all productive boundaries, original bill/journal accounting, release and offer prerequisites, three earlier Contracts, actual Starwave hands and independent payout arithmetic. All four had valid ledgers and no driver failures or development curtailments.

## Results

All four routes earned Crown after Game 2, then completed Neon and all three Starwave hands. Their first releases remained at cycle12, second at32 and third at52. The purchase policy improved the **second** Review enough to cross Crown's 7.0 gate in every tested specialty, including Strategy's narrow v12 miss at6.9. The resulting Starwave receipts were earned on hand3, not acceptance advances.

| Specialty | Bought starter IDs | Game-1 Review v12→v18 | Game-2 Review v12→v18 | Lowest observed cash | Starwave hand-3 receipt |
|---|---|---:|---:|---:|---:|
| Adventure | `enemies`, `menu_system`, `music` | 4.2→5.8 | 6.1→8.9 | $10 | $2,060 |
| Role-Playing | `enemies`, `music`, `scrolling` | 4.5→5.4 | 6.6→7.3 | $0 | $2,000 |
| Strategy | `levels`, `music`, `sprites` | 4.7→5.6 | 6.9→8.6 | $220 | $2,000 |
| Simulation | `general_combat`, `levels`, `music` | 3.7→5.8 | 6.0→8.8 | $170 | $2,000 |

The low cash is an important tradeoff: Role-Playing's original `rent:6` bill was late at Game-1 launch and later settled; the route nevertheless completed every planned production hand. There was no blocked useful action or original arrears **between Starwave acceptance and hand3** in any route, and pre-Starwave cash exceeded $12,500 in all four. Early Ironclad/Store liquidity and Starwave advance rescue are different questions. The [raw route folders](sim-v18/) preserve quotes, purchases, draws, Review components, cash, original bills and Contract receipts.

## Recommendation and limits

**Keep Crown's Review≥7.0 gate and the existing ACTIVE/TRIAL Contract terms for now.** In this fixed policy, every previously failing specialty in the declared set had a legal Crown→Neon→Starwave path without delaying its first release. This weakens any claim that those specialties require a publisher-gate or roster retune merely to reach Crown. It does not prove that the Store choice is easy for players to discover, economically preferable, or broadly safe. The sample uses one seed (fallback was not triggered), one trait bundle, one purchase heuristic and Genre matched to specialty; starter buying also changes draw supply, spending and later sales. The current source includes later Education changes that this pin does not.

No cap, Promotion, acceptance advance, Feature price, Crown gate or final balance is approved by these results. The next useful Contracts comparison is a matched-calendar continuation of **buy + publisher chain versus no-buy/no-chain** for these four routes, including early rent recovery, settled sales and delayed later work. That would measure the economic cost of this access path before considering any task handoff. A separate Feature Store thread can assess how players learn about starter buying; keep its files and shared TODO independent.
