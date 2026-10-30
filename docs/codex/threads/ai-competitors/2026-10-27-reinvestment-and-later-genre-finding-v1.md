# Rival Store reinvestment and later Genre fit — finding, 2026-10-27

**Status: DESIGN evidence, no adoption.** This follows the [per-project reinvestment pre-run plan](2026-10-27-per-project-reinvestment-plan-v1.md), [no-op audit](2026-10-27-reinvestment-noop-audit-plan-v1.md), [route correction](2026-10-27-per-project-routing-fix-plan-v1.md) and [later Genre plan](2026-10-27-later-genre-fit-plan-v1.md). The 72-cycle [U/V career finding](2026-10-27-three-year-rival-career-finding-v1.md) showed that one or two lifetime purchases left most later sales cash uninvested. Here we test the route, actual repeat purchases and later Genre response, using only private simulator copies.

## Version and comparison contract

- All four versions descend from V's recorded old-cohort private baseline and use the same two legal 35-Scope solo rivals, seeds `4417`,`4423`,`4431`, cycle72/max300 decisions per studio, actual Store/Bank/hand/QA/Review actions, neutral Market and 240-second process bound. Cycle-zero cash/Features/RNG and the first two release records match for every Y/Z versus V pair. The rule differences below are controlled private edits, **not** canonical adoption.
- W [private variant](simulators/rival-per-project-reinvestment-20261027-v1) only changes the completed-purchase limit to two per prior release. Gameplay source identity `f822db09e427a97f04b8183f06b7654c1e2ebbf70af4edaf8fbf0d415ed747ae`; [bundle](sims/rival-three-year-W-bundle-20261027-v1) manifest SHA-256 `9cf07aebba7053f27c26757bb977f5f7dfaa9b5a328c76cc37c4a9265a1ba72e`.
- X [diagnostic child](simulators/rival-reinvestment-noop-audit-20261027-v1) adds policy-choice receipts only, with unchanged gameplay source identity `f822db09e427a97f04b8183f06b7654c1e2ebbf70af4edaf8fbf0d415ed747ae`; [bundle](sims/rival-three-year-X-bundle-20261027-v1) manifest SHA-256 `6712b5a86511180fec340691a52f54d7828adcd9bb913448c6e83d650389f8ff`.
- Y [route-corrected private variant](simulators/rival-per-project-route-20261027-v1) calls the shopper at every post-first-release Studio boundary but keeps game3+ Genre at specialty to isolate Store reinvestment. Source identity `6ace6670cb89482f0b2f61303daaff6aa0e953278b95dc27a8f6f0d8857825e6`; [bundle](sims/rival-three-year-Y-bundle-20261027-v1) manifest SHA-256 `c953bca29bebd54a3003ecf9888981b98c047069e1f0398492f3c07b58ae9763`.
- Z [Genre child](simulators/rival-per-project-genre-20261027-v1) keeps Y's Store route and lets the same printed-Core diagnostic choose game3+ Genre too. Source identity `ff1e3a20924cb1d613784d5f050050ce8e55abe772eeb76d288196ff9cdce9ed`; [bundle](sims/rival-three-year-Z-bundle-20261027-v2) manifest SHA-256 `cfa387a0bc255c08e112b37e65816e285ae75359186c3ae6dec43eff55880c18`.
- Checkout `main` HEAD `f3e0f2b5d35270c879327bc297b389748571feb4`; concurrently dirty canonical Store/checkpoint/TODO files preserved. Godot `4.7.1.stable.official.a13da4feb`, executable SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`.

Reproduction example (replace W with Y/Z, their successful bundle/output name and the declared seed for each paired arm):

```powershell
$pnPython='C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$pnGodot='C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
& $pnPython tools/simulate.py run --variant docs/codex/threads/ai-competitors/simulators/rival-per-project-route-20261027-v1 --config docs/codex/threads/ai-competitors/six-hand-phase-study-20261023-v1/smoke.json --output docs/codex/threads/ai-competitors/sims/rival-three-year-Y-bundle-20261027-v1 --godot $pnGodot --timeout 240
& $pnPython docs/codex/threads/ai-competitors/run_low_review_cause_probe_v2.py --bundle docs/codex/threads/ai-competitors/sims/rival-three-year-Y-bundle-20261027-v1 --output docs/codex/threads/ai-competitors/sims/rival-three-year-Y-4417-20261027-v1 --seed 4417 --godot $pnGodot
& $pnPython tools/simulate.py replay --bundle docs/codex/threads/ai-competitors/sims/rival-three-year-Y-bundle-20261027-v1 --case foundation-legal-action-4417 --output docs/codex/threads/ai-competitors/sims/rival-three-year-Y-replay-20261027-v1 --godot $pnGodot --timeout 240
```

Each successful bundle's 50-command smoke completed 18 commands. W, Y, Z fresh 18-step replays passed. Seed4431 repeated in fresh processes with identical result SHA-256 for W `5b9a566b2a5771284c490eb660143efe6e41e1289faa2967747294c92bce8e9c`, Y `eb5773a0a2ff296e4bfcac316cb3dcd897ddda6c9b6a71e3b7f1b3e299119226`, Z `1702650a627a9083aa75152837203606dcbef6e73190bdc149ea5978041d4902`. All six careers per completed W/Y/Z arm reached cycle72 without rejected development, failure or timeout. X seed4417's release, owned-Feature and final-cash records matched W exactly.

**Retained rejected run:** [Z bundle v1](sims/rival-three-year-Z-bundle-20261027-v1) failed the canonical-source drift fence during concurrent edits. It was not used for behavior. The new v2 output passed. W's first higher-limit version is also retained as a *valid but no-op counterfactual*, not silently reinterpreted as a reinvestment test.

## Results and root cause

The W policy had no effect in all three seeds: V/W release records, final Feature sets and cash matched exactly. [X seed4417](sims/rival-three-year-X-4417-20261027-v1) showed the planner handled the game2 Store purchase and then did not run at c34/c36 or later. The source gate in `_feature_maximal_choice` called `_funded_core_studio_choice` only for `view.releases.size() == 1`. The higher allowance inside that function was unreachable after game2. W therefore tests a routing defect, not the intended reinvestment behavior.

Y corrected that private route and completed **20** Store acquisitions across six careers versus V's **10**. Ten extra admissions were paid and owned; three studios changed later projects. Y retained 22 releases and two 8.0+ games, but mean Review rose from V's 6.96 to **7.01**. In seed4417, Wayfinder's game4 went 7.2 c65 → **7.8 c70** with actual Scope 43/30; in seed4423 Arcade's game3 went 6.9 c57 → **7.6 c59** with Scope 41/30. Some releases slowed or regressed. A Bank-liability guard still prevented Arcade seed4431 from shopping despite $17,491 final cash; that guard is not proven necessary by this study.

Z retained Y's **20** acquisitions and 22 releases and raised mean Review to **7.07**. It improved some later 7-point titles, including Wayfinder seed4423 game3 from 7.0 to 7.4 and Wayfinder seed4431 game3 from 7.4 to 7.6, while other changes were neutral or negative. It still produced exactly two 8.0+ titles: Arcade seed4417's 8.0 at c70 and Wayfinder seed4431's 8.1 at c39. **No seed had two 8.0+ studios.** Actual Scope was met for every released Y/Z game, but Scope alone did not ensure high Core/Review. The probe records Core/Bugs but does not serialize chosen Genre IDs; the comparison is grounded in the private policy source and actual Review results, while exact Genre-choice receipts remain a measurement gap.

| Arm | Releases by c72 | Paid new Features | Mean Review | 8.0+ titles | Saves with two distinct 8.0+ studios |
| --- | ---: | ---: | ---: | ---: | ---: |
| V: lifetime two purchases + game2 fit | 22 | 10 | 6.96 | 2 | 0/3 |
| W: raised allowance, wrong route | 22 | 10 | 6.96 | 2 | 0/3 |
| Y: per-project shopping, later specialty | 22 | 20 | 7.01 | 2 | 0/3 |
| Z: Y plus later predicted Genre fit | 22 | 20 | 7.07 | 2 | 0/3 |

[W 4417](sims/rival-three-year-W-4417-20261027-v1) · [W 4423](sims/rival-three-year-W-4423-20261027-v1) · [W 4431](sims/rival-three-year-W-4431-20261027-v1) · [Y 4417](sims/rival-three-year-Y-4417-20261027-v1) · [Y 4423](sims/rival-three-year-Y-4423-20261027-v1) · [Y 4431](sims/rival-three-year-Y-4431-20261027-v1) · [Z 4417](sims/rival-three-year-Z-4417-20261027-v1) · [Z 4423](sims/rival-three-year-Z-4423-20261027-v1) · [Z 4431](sims/rival-three-year-Z-4431-20261027-v1).

## Recommendation and remaining uncertainty

Retain **reinvestment at later Studio boundaries** as a candidate planning need, because the route correction made real, legally paid Core supply and improved some later Reviews. Do **not** adopt two purchases per project or the printed-Core Genre selector as a rule: neither met the multi-incumbent 8.0+ objective, and the forecast ignores jointly attainable hands, finite use, synergy, true project budget and current legal mixed Store progression. The blanket loan-liability guard can strand spendable cash; evaluate it under a full known-dues affordability screen rather than removing it blindly.

The next experiment should implement the [LOCKED F1–F6 qualitative planner](2026-10-09-feature-shopping-delegated-decisions-v1.md) in a fresh private version: jointly legal finite Design/Alpha Core potential, actual quote/FIFO/known due funding, positive gap relevance, earliest live era then cheapest completed ownership, and a Genre choice from the same feasible production plan. CPU/search envelope, number of purchases, financial reserve and fallback remain **OPEN**. Rebaseline on current source and then test an actual eight-specialist 1977→1980 shared world, generated standards, frozen history accounting and save/Continue. These old-cohort solo results do not approve balance, January opening market content, a TODO handoff or canonical changes.
