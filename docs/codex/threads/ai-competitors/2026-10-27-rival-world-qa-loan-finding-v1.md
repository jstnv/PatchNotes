# Rival-world Beta QA and legal Bank routing — finding, 2026-10-27

**Status:** Bounded DESIGN evidence. No canonical gameplay, TODO, approval, commit or push. Branch `main`, starting HEAD `087df09d653858b72c6e2dc344352237433dd3ac`; dirty concurrent checkout and `.codex-godot-temp` preserved. The qualitative user direction is QA before Marketing and willingness to consider legal loans. Seven Beta hands, the three-rent/12-month loan trigger, and the two-rival cohort numbers are diagnostic **OPEN** proposals. A completed simulation does not approve balance.

## Question and fixed comparison

Can more legal Beta work and a legal loan lift first rival Reviews without breaking a shared 24-cycle market? [Initial plan](2026-10-27-rival-world-qa-reviews-plan-v1.md), [selector routing](2026-10-27-rival-world-qa-routing-amendment-v1.md), [rent-boundary loan](2026-10-27-rival-world-beta-loan-preflight-plan-v1.md), [cash-poor loan](2026-10-27-rival-world-beta-loan-affordability-amendment-v1.md), [Bank routing](2026-10-27-rival-world-bank-action-routing-amendment-v1.md), and [receipt probe](2026-10-27-rival-world-bank-receipt-plan-v1.md) were written before their respective arms. Fresh seeds `4417` and `4423`; same legal two-rival cohort, 35 owned Scope supply, $5,850 initial cash and 20 Fans; clock-only Studio player; 24 shared cycles; 12 zero-cycle rival steps per player cycle; one 50-command legal-action smoke per new variant; 240-second process bound. Neither seed nor horizon changed after a failure. H is a one-seed receipt-only child of G.

| Arm | Private change from parent | Seed 4417 | Seed 4423 |
| --- | --- | --- | --- |
| A | Existing whole-supply/full-Scope control; 3 Beta hands | Complete c24, 3 titles | Complete c24, 4 titles |
| B | Seven Beta hands | Complete c24, 2 titles | **FAIL** c19 idle calendar, 2 titles through c18 |
| C | Prefer public Known-Bug fixes, but richer roster kept selector gated | Same as B | Same failure as B |
| D | Route named incumbents to C's Beta selector | Complete c24, 2 titles | **FAIL** c19; 2 titles through c18 |
| E | Bank recovery quote only when selected Beta play crosses rent | Complete c24, 2 titles | **FAIL** c19; 1 title through c18 |
| F | Quote when selected Beta play has cash below rent | **FAIL** c19; 1 title through c18 | **FAIL** c19; 0 titles through c18 |
| G | Add `bank_borrow` to the private RivalWorld action whitelist | Complete c24, 2 titles | Complete c24, 2 titles; cold repeat identical |
| H | G plus receipt-only probe instrumentation | Not run, per plan | Complete c24, 2 titles; same releases/Reviews as G |

Every arm started at identical c0 cash, phase, Scope, player clock and rival RNG digests **within each seed**. Seed4417 Arcade/Wayfinder RNG prefixes were `c8c3cab52bdb`/`c20790e34994`; seed4423 `8958acaf498e`/`329fe3d51ff9`. Different seeds are not asserted to have equal starts. All new variant smoke runs passed one legal player title in 18 commands, c7. G and F cold Studio replay each accepted all 18 commands. G seed4423 cold world repeat had the same result SHA-256 `c812b0a1a2b27505e85a56078ad079198e93066f9a01a8c44f53ba5663939e36` and log SHA-256 `100de9e759d18e09864e11173b247ad0b3402fe8412998de6af0949a24ddc749`.

## Reviews shown by actual rival releases

Numbers are `review_tenths/10` from each release's authoritative metadata. `c` is shared world cycle. A seed4423 completed; B–F seed4423 observations before the marked failure are **partial**, not completed 24-cycle outcomes.

| Arm | Seed | Wayfinder Works, Adventure | Arcade Foundry, Action | Other releases by c24 |
| --- | ---: | --- | --- | --- |
| A, 3 Beta hands | 4417 | **4.1** c11 | **6.2** c12 | Arcade **5.9** c24 |
| A, 3 Beta hands | 4423 | **4.6** c12 | **6.6** c13 | Wayfinder **5.7** c23; Arcade **5.0** c24 |
| B/C/D, 7 Beta hands | 4417 | **5.7** c16 | **6.4** c17 | None |
| B/C/D, 7 Beta hands | 4423 | **5.9** c17 | **7.6** c18 | **Partial: world fails c19** |
| E, rent-boundary Bank probe | 4417 | **5.7** c16 | **6.4** c17 | None |
| E, rent-boundary Bank probe | 4423 | **5.9** c17 | No launch | **Partial: world fails c19** |
| F, unrouted Bank probe | 4417 | **5.7** c16 | No launch | **Partial: world fails c19** |
| F, unrouted Bank probe | 4423 | No launch | No launch | **Partial: world fails c19** |
| G, routed legal Bank | 4417 | **5.7** c16 | **6.4** c17 | None |
| G/H, routed legal Bank | 4423 | **5.9** c17 | **7.6** c18 | None; c24 complete |

All G first releases have **35 Scope**, required Scope **30**, and **0 remaining Bugs**. G seed4417 Wayfinder Cores `[31,20,29,28]` face Adventure standards `[33,26,20,53]` and review 5.7; Arcade Cores `[29,27,32,28]` face Action `[40,26,40,26]` and review 6.4. Seed4423 Wayfinder `[31,24,31,30]` faces the same Adventure standards and reviews 5.9; Arcade `[39,28,34,28]` faces Action standards and reviews 7.6. Thus QA and full Scope alone did not yield an 8.0 first game. Wayfinder's fourth Core remains 23–25 below its Genre standard. This points to Feature/Genre Core fit as the next quality bottleneck; two seeds do not identify an approved Store policy or prove an 8.0 ceiling.

Seven-hand Beta cleared A's remaining Bugs (A first Wayfinder 8/6; Arcade 1/4 across the two seeds), but first releases moved 4–5 cycles later and 24-cycle publication fell from A's 3/4 titles to G's 2/2. It improved first Reviews in both seeds, but did not solve the requested 8.0+ opening challenge or its release density. The public Known-Bug selector changed routed choice traces in D but changed no measured first Review. C was a no-op for this richer roster because `uses_synergy_trial` excludes it.

## Bank failure and receipt

F's `bank_borrow` choice was rejected by `rival_world.gd::_choice`, which did not list that action; the world reported `No legal policy choice`, then failed an idle calendar at c19. This is a **routing blocker**, not evidence that Bank2 denied the quote. G changed only that whitelist. H's receipt instrumentation confirms two accepted `bank_borrow_committed` actions at c16 in seed4423, one per rival. Each loan had $1,500 principal, 12-month term, first due c18, $1,597.50 total scheduled payment. By c24 each had repaid $500 principal and $52.50 interest, leaving $1,000 principal outstanding. Both studios completed the c24 world without blocked actions; the loan did not change their first Reviews, because their Cores, Scope, Bugs and launch sequence matched D. This is a narrow legal liquidity proof, not a payoff, later-project, or CPU proof.

## Provenance and reproduction

Godot console SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`. Standard isolated runner, distinct copied projects/import caches/profiles/output paths; no player saves. A frozen bundle: `sims/whole-supply-gates-20261026-B-v3-bundle01`. B→C→D→E→F→G→H are private `simulators/rival-world-*` children. Gameplay source identities: A `52522fdf`, B `ab271c0e`, C `f2411c92`, D `2dbcec35`, E `aa8d45cd`, F `2fbdfd85`, G/H `3c53e42f`. H has a distinct bundle manifest `34edea52...` because only diagnostic source changed. Full identities and hashes are in each `prestart-shadow-run.json` and bundle manifest.

Exact command form, invoked once per declared case with the listed unique bundle/output/seed values:

```powershell
$pnPython = 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$pnGodot = 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
& $pnPython tools/simulate.py run --variant docs/codex/threads/ai-competitors/simulators/rival-world-beta-qa-loan-routed-20261027-v1 --config docs/codex/threads/ai-competitors/six-hand-phase-study-20261023-v1/smoke.json --output docs/codex/threads/ai-competitors/sims/rival-qa-world-G-bundle-20261027-v1 --godot $pnGodot --timeout 240
& $pnPython docs/codex/threads/ai-competitors/run_low_review_cause_probe_v2.py --bundle docs/codex/threads/ai-competitors/sims/rival-qa-world-G-bundle-20261027-v1 --output docs/codex/threads/ai-competitors/sims/rival-qa-world-G-4423-20261027-v1 --seed 4423 --godot $pnGodot
& $pnPython docs/codex/threads/ai-competitors/run_low_review_cause_probe_v2.py --bundle docs/codex/threads/ai-competitors/sims/rival-qa-world-G-bundle-20261027-v1 --output docs/codex/threads/ai-competitors/sims/rival-qa-world-G-4423-repeat-20261027-v1 --seed 4423 --godot $pnGodot
& $pnPython tools/simulate.py replay --bundle docs/codex/threads/ai-competitors/sims/rival-qa-world-G-bundle-20261027-v1 --case foundation-legal-action-4417 --output docs/codex/threads/ai-competitors/sims/rival-qa-world-G-replay-20261027-v1 --godot $pnGodot --timeout 240
```

For A use the frozen A bundle. For B–H substitute each arm's `sims/rival-qa-world-<ARM>-bundle-20261027-v1`, distinct `sims/rival-qa-world-<ARM>-<SEED>-20261027-v1`, and seed `4417` or `4423`; H only used `4423`. Direct evidence: [A 4417](sims/rival-qa-world-A-4417-20261027-v1/prestart-shadow.json), [A 4423](sims/rival-qa-world-A-4423-20261027-v1/prestart-shadow.json), [G 4417](sims/rival-qa-world-G-4417-20261027-v1/prestart-shadow.json), [G 4423](sims/rival-qa-world-G-4423-20261027-v1/prestart-shadow.json), [H Bank receipts](sims/rival-qa-world-H-4423-20261027-v1/prestart-shadow.json), and [F failed log](sims/rival-qa-world-F-4423-20261027-v1/prestart-shadow.log). All B–F failed and partial outputs remain in their named directories.

## Recommendation and OPEN work

Keep the user-selected full-Feature/full-Scope and QA-before-Marketing direction. Do **not** adopt a seven-hand constant, an automatic loan threshold, a Review boost, or new market coefficients from these cases. A private Bank route is necessary for any legal rival borrowing; PN Implementation should own canonical adoption after a source-pinned handoff. Next bounded study should compare specialty-directed Feature acquisition and Core-target hand scoring with the same legal world, show Review and publication distribution, and include loan service/blocked cases. Whether the initial cohort is eight Genre specialists, whether first historical titles generate standards, exact Store growth, early 8.0+ market composition, entrant rules, CPU and longer-term debt remain **OPEN**. No 8.0+ newly simulated first release appeared here.
