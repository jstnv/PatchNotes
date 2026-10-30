# Action 1977 provisional profile and first standard — finding, 2026-10-28

**Status: bounded formula-only DESIGN evidence. No target vector or standard transform is approved.** A single modest Action provisional profile cannot put all six examined legal first games in the intended 6.0–7.0 band. The existing `[40,26,40,26]` profile produced two in-band first Reviews; an exhaustive bounded search of **2,821** positive, 132-total vectors within ±25% of that profile reached at most **three of six**. Actual first-release variance and Core variation both contribute. Two candidate four-Core transforms have now been screened against later receipts, but current gameplay validation forbids generated historical standards that differ from the fixed Genre base. A genuine private gameplay variant needs an explicit new authority and typed provenance path.

## Authority, source and method

The [pre-run plan](2026-10-28-action-bootstrap-standards-screen-plan-v1.md) fixed inputs, profile grid, transform formulas and stopping checks. The selected [opening design](2026-10-27-legal-eight-rival-opening-design-review-v1.md) calls for one legal first 1977 release per Genre, ordinarily around 6–7, followed by a four-Core standard sourced from that title and effective for later project Begins after the following month. The numerical bootstrap, transform and progression remain **OPEN**. This screen uses the six actual Action `full_pool` first-to-third release reports: [4417](sims/one-action-full_pool-4417-20261027-v9/prelude.json), [4423](sims/one-action-full_pool-4423-20261027-v9/prelude.json), [5501](sims/one-action-full_pool-5501-20261028-v10/prelude.json), [5507](sims/one-action-full_pool-5507-20261028-v10/prelude.json), [5513](sims/one-action-full_pool-5513-20261028-v10/prelude.json) and [5519](sims/one-action-full_pool-5519-20261028-v10/prelude.json). The latter four were holdouts for the preceding Store-policy study; all six are **development data** for this new scoring screen, not independent validation of any selected target.

All six legal careers share frozen gameplay source identity `a7ec583cd23d1b33cea1dbea747f5804bd583da79184a9de3eb9916e59c02afa` and Review calculator SHA-256 `e58090fbb1562a653a4883058b1577dc9c45f49e86a48f208208b8fce4ea9098`, which matches the current checkout file at this study's inspection. V9 stops c72; v10 stops c80, so only the first three titles were used. Each first project had the actual 25/36 paid Primitive supply, full played Scope, legal hands, real QA and bills from the [prior one-Action finding](2026-10-28-one-action-adaptive-store-finding-v1.md); $25,000 starting capital and the 1977 fixed target remain **OPEN trial resources**. The [read-only analysis script](analyze_action_bootstrap_standards_v1.py) (SHA-256 `34e5eb36f870bacd011514ae28e88d558ecf1436ba1543f7447dbd4c0162f7d8`) reproduced the saved production rating and final Review of **all 18 first-to-third receipts**, with a unique one of the source's five discrete variance modifiers each time. Source identity, target vector, legal receipt completeness and Game 3 timing checks passed before candidate scoring. The full [JSON screen](sims/action-bootstrap-standards-screen-20261028-v1.json) (SHA-256 `cb219b32e7892cc48817d7de92d011fdf554a0427d884d0562070feb85311a27`) retains every input path/hash, vector count, coverage histogram, per-seed receipt, inferred variance, standard and counterfactual.

## First-release profile feasibility

The exact six first-game receipts under the existing Action profile are below. `Neutral roll` recalculates only the source's variance modifier as zero, leaving played Core/Scope/Bugs unchanged. It is an explanatory diagnostic, not a legal alternative release.

| Seed | Core G/S/T/D | Bugs | Actual variance | Actual Review | Neutral roll |
| --- | --- | ---: | ---: | ---: | ---: |
| 4417 | 35/23/32/26 | 0 | −0.50 | **6.3** | 6.8 |
| 4423 | 33/35/42/30 | 0 | 0 | **7.9** | 7.9 |
| 5501 | 34/30/44/30 | 1 | +0.25 | **8.0** | 7.7 |
| 5507 | 25/29/34/24 | 0 | 0 | **6.3** | 6.3 |
| 5513 | 24/26/34/26 | 0 | −0.50 | **5.7** | 6.2 |
| 5519 | 30/30/34/32 | 1 | +0.25 | **7.2** | 6.9 |

Only **2/6 actual** first Reviews are 6.0–7.0, while **4/6 neutral-roll diagnostics** would be. Seed5513's 5.7 is largely a legitimate −0.5 Review variance roll; 4423 and 5501 have stronger Core output even without a favorable roll. A fixed profile cannot eliminate both sources of spread while preserving the ordinary scoring formula and all legal routes.

The predeclared grid held total targets at132 and each category in `[ceil(0.75×base), floor(1.25×base)]`: Graphics30–50, Sound20–32, Technology30–50, Design20–32. Of **2,821** vectors, **0** covered four or more of six first games, **1,126** covered three, **1,694** covered two and **1** covered one. The deterministic closest-to-current diagnostic among three-coverage vectors was `[40,26,43,23]`, yielding `[6.2,7.9,7.9,6.4,5.7,7.0]` in seed order. It is **not recommended as a new target**: it still misses three titles and was selected using the same six observations. Contextual uniform scalings also fail to cover all six: 75% covers0, 85% covers1, 95% covers3, current100% covers2, 105% covers3 and 115% covers3. The earlier [75% headless screen](2026-10-26-first-release-bootstrap-headless-finding-v1.md) remains a separate actual gameplay rejection; this screen is static formula arithmetic.

## Generated-standard transforms and effective month

The first game's actual four-Core output is needed; scalar Review cannot generate a category vector. The predeclared static candidates were **N** no historical benchmark/current fixed `[40,26,40,26]`; **M** `max(ceil(0.75×base), ceil((base+first_core)/2))` per category; and **P** `max(ceil(0.75×base), first_core+4)`. The 75% lower bound and +4 margin are exploratory arithmetic choices, not balance approval. The table applies each to the **recorded Game 3** Core/Scope/Bugs and the same inferred variance. It does not rewrite the stored title or re-run the AI policy.

| Seed | M standard G/S/T/D | P standard G/S/T/D | Game 3 saved N | Static M | Static P |
| --- | --- | --- | ---: | ---: | ---: |
| 4417 | 38/25/36/26 | 39/27/36/30 | 6.6 | 6.9 | 6.5 |
| 4423 | 37/31/41/28 | 37/39/46/34 | 6.1 | 5.9 | 5.2 |
| 5501 | 37/28/42/28 | 38/34/48/34 | 8.0 | 7.9 | 7.0 |
| 5507 | 33/28/37/25 | 30/33/38/28 | 7.1 | 7.7 | 7.3 |
| 5513 | 32/26/37/26 | 30/30/38/30 | 6.8 | 7.4 | 7.0 |
| 5519 | 35/28/37/29 | 34/34/38/36 | 6.2 | 6.4 | 5.9 |

M changes the saved Game 3 Review by **−0.2 to +0.6**; P by **−1.0 to +0.2**. Neither static transform is demonstrated to produce the desired 8+ historical population; M removes the only 8.0 in these six Game 3 counterfactuals. P is especially punitive after a high first Core in one category. M is the less volatile **OPEN prototype candidate**, not an approved standard formula.

The exact first-release cycles were `17,20,18,16,16,18`; the next-month effective cycles are `18,22,20,18,18,20`. In all six no-Store tapes, **Game 2 Began at the first release cycle**, before that effective boundary. Game 3 Began at `35,38,35,32,34,35`, after it. Therefore a next-month rule cannot be applied retroactively to Game 2 on those routes. Paid Store Research can delay Game 2 Begin across the effective boundary; the previous one-versus-two Store quality comparison used fixed standards and must be rerun under actual historical-standard rules. This is a material timing interaction, not a reason to backdate the standard.

## Runtime authority conflict and adoption boundary

The frozen and current `ProjectState.freeze_market_standards()` accept only targets between the fixed Genre base and **base+8**. `MarketTransactionTrial.valid_details()` additionally requires a `historical` snapshot to have **standards exactly equal to base**. Thus most M/P vectors above cannot be frozen as historical targets through the current command path. A legal private gameplay prototype needs a versioned historical-standard source, provenance validator, snapshot ID/effective month and checkpoint schema rules; directly overriding a Review number or bypassing the frozen target check would not establish the selected design. The first historical 6.x title must be eligible to establish that source even though the current *live* strong-Core Market gate requires Review≥7.0. Historical source must stay outside active sales/saturation/news and 1980-only rankings.

**Recommendation:** keep the current Action target as a temporary provisional control while authoring/certifying lawful first-release tapes; do not apply a blanket easier profile or claim an ordinary 6–7 distribution from the six cases. Prototype a typed first-release standard source and M versus no-history as the next bounded gameplay test, then recalibrate with new holdout seeds and all eight Genres. The planned online Store and January continuation studies must then be rerun with actual project-frozen generated standards. Exact first profile, certification threshold/catalog size, M or another transform, later standard rises, Store gate, historical 8+ yield, shared Market, save and CPU remain **OPEN**. No canonical gameplay, TODO, variant, player save, `.codex-godot-temp`, commit or push was changed by this formula screen.

## Commands and retained checks

From repository root in PowerShell:

```powershell
$pnPython='C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $pnPython -m py_compile docs/codex/threads/ai-competitors/analyze_action_bootstrap_standards_v1.py
& $pnPython docs/codex/threads/ai-competitors/analyze_action_bootstrap_standards_v1.py --output docs/codex/threads/ai-competitors/sims/action-bootstrap-standards-screen-20261028-v1.json
```

Both commands passed; the script reported `tested_vectors=2821`, `max_coverage=3` and `best_targets=[40,26,43,23]`. Existing simulator careers and their representative fresh replays are linked in the prior finding. This analysis made no new claim about CPU performance, legal future hand choice, finance, sales, typed January projection, Studio-only Continue or player challenge.
