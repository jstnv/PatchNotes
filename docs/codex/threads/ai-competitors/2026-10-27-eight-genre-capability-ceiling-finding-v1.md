# Eight specialist capability ceiling and Genre attribution — finding, 2026-10-27

**Status: DESIGN diagnostic; no roster, balance or implementation adoption.** The [pre-run capability plan](2026-10-27-eight-genre-capability-ceiling-plan-v1.md) asked what the six untested specialists could produce with abundant equal Primitive supply. The [receipt addendum](2026-10-27-eight-genre-receipt-addendum-v1.md) checked whether high Reviews were actually in each studio's specialty. This closes the narrow diagnostic question, not the eight-rival 1977 opening design.

## Source and limits

- Current canonical `RivalTrial.create_world` still creates only Arcade/Action and Wayfinder/Adventure. The eight rivals here exist **only** in the [private E variant](simulators/rival-eight-primitive-ceiling-20261027-v1), a child of the earlier Z candidate. Each starts as its distinct specialty with the same **27 owned Primitive Feature IDs**, $5,850 cash, trial traits and equal initial RNG state within a seed. The private snapshot grants the entire Primitive set and removes matching Store offers **without payments or legal 1977 acquisition history**. It is a synthetic capability upper bound, not a viable opening cohort. Ordinary subsequent development, Research, Bank and release actions use the game rules. All eight sessions are neutral solo careers; no shared Market, frozen historical archive, player sales or save/Continue is tested.
- [E isolated bundle](sims/rival-eight-ceiling-E-bundle-20261027-v1) manifest SHA-256 `c3d775ddf36979ba120720ab31a47c92aafb1b23c3d10f9934c220070bb92098`; gameplay source identity `6e6eea5b0bbf3bdebb1cdac8fef0a8870907cbcd08ab506ada8766159cfe2928`. [F receipt-only child](simulators/rival-eight-genre-receipts-20261027-v1) adds `begin_development`/released Genre fields to the private probe without changing gameplay; [bundle](sims/rival-eight-ceiling-F-bundle-20261027-v1) manifest SHA-256 `04fc2cfd47c38cd3685ebb5b954437d4d444e53517cfd7e10cb1c2c8765ae98c` and the same gameplay source identity. Recorded original canonical baseline/ancestry remain intact. Checkout `main` HEAD `f3e0f2b5d35270c879327bc297b389748571feb4`; concurrent canonical Store/checkpoint/TODO edits were preserved. The private project is not a rebase onto those changing files.
- Seeds `4417`,`4423`,`4431`, eight independent studios per seed, cycle72/max300 decisions per studio, 240-second Godot process limit. Source calendar has 24 cycles/year: this is a 1980→1983 **duration proxy**, not a played 1977→1980 history. Current 1980 ACTIVE/TRIAL Genre target table applies; the proposed 1977 bootstrap and generated first-release standards are **not** implemented here. Godot `4.7.1.stable.official.a13da4feb`, executable SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`.
- One 50-command smoke per variant completed 18 commands. E's fresh 18-step replay passed; seed4417 cold repeat matched result SHA-256 `3fbce22c6e1c3af583fdce63925af40d84d41fad89552bfcf76be8c68e6bf04a`. F's three seed runs matched E's initial studio state/RNG, every release cycle/Review/Core/Scope/Bugs, final owned Features/cash and zero failures; F's recorded Begin Genre matched release metadata Genre in all 80 records. The E seed processes took 22.14, 24.41 and 26.45 seconds respectively; those debug-process timings do **not** establish an acceptable new-save CPU budget. Seed4417 recorded 16 legal Store-wait idles; the other seeds recorded none. No run had an illegal action, timeout or missing cycle72 boundary.

Exact command pattern (each run had a unique output; each output's `*.command.json`/`*-run.json` gives the expanded invocation and receipt):

```powershell
$pnPython='C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$pnGodot='C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
& $pnPython tools/simulate.py run --variant docs/codex/threads/ai-competitors/simulators/rival-eight-primitive-ceiling-20261027-v1 --config docs/codex/threads/ai-competitors/six-hand-phase-study-20261023-v1/smoke.json --output docs/codex/threads/ai-competitors/sims/rival-eight-ceiling-E-bundle-20261027-v1 --godot $pnGodot --timeout 240
& $pnPython docs/codex/threads/ai-competitors/run_low_review_cause_probe_v2.py --bundle docs/codex/threads/ai-competitors/sims/rival-eight-ceiling-E-bundle-20261027-v1 --output docs/codex/threads/ai-competitors/sims/rival-eight-ceiling-E-4417-20261027-v1 --seed 4417 --godot $pnGodot
& $pnPython tools/simulate.py replay --bundle docs/codex/threads/ai-competitors/sims/rival-eight-ceiling-E-bundle-20261027-v1 --case foundation-legal-action-4417 --output docs/codex/threads/ai-competitors/sims/rival-eight-ceiling-E-replay-20261027-v1 --godot $pnGodot --timeout 240
```

The same `run`/probe commands with F's version and successful bundle produced the receipt arm. Substitute `4423` and `4431` for the other declared seeds. [E 4417](sims/rival-eight-ceiling-E-4417-20261027-v1) · [E 4423](sims/rival-eight-ceiling-E-4423-20261027-v1) · [E 4431](sims/rival-eight-ceiling-E-4431-20261027-v1) · [F 4417](sims/rival-eight-ceiling-F-4417-20261027-v1) · [F 4423](sims/rival-eight-ceiling-F-4423-20261027-v1) · [F 4431](sims/rival-eight-ceiling-F-4431-20261027-v1).

## Results

Every studio had the same sorted 27-ID owned set, cash and RNG digest within each seed. All **24 first games** played Scope **39/30** and launched with **zero Bugs**, so the first-Review spread primarily exposes Core/Genre fit and ordinary variance under this policy. Their first Reviews ranged **6.5–8.4**; only **6/24** fell in the intended 6.0–7.0 founding band, and **2/24** already reached 8.0. A universal maximum Primitive grant overshoots the desired first-game progression and is not a candidate starter roster.

Across 72 cycles, the three seeds published **24/24/32 = 80** games; **6/8, 8/8 and 8/8** studios respectively made at least one 8.0+ game, with **28** such games overall. That proves this synthetic supply can produce high *studio* Reviews through actual project actions. It does **not** prove eight high-scoring specialty Genres. F's chosen-Genre receipts show only **11/28** high Reviews used their studio's permanent specialty; the 28 high titles covered only **Adventure, Role-Playing, Simulation and Sports** as played Genres.

| Studio specialty | First Review mean (3 seeds) | Seeds with any 8.0+ studio game | 8.0+ games in own Genre | Best own-Genre Review |
| --- | ---: | ---: | ---: | ---: |
| Action | 7.30 | 2/3 | **0** | 7.8 |
| Adventure | 7.27 | 3/3 | 1 | 8.1 |
| Puzzle | 7.30 | 3/3 | **0** | 7.7 |
| Racing | 6.87 | 2/3 | **0** | 7.2 |
| Role-Playing | 7.83 | 3/3 | 5 | 9.1 |
| Simulation | 7.67 | 3/3 | 3 | 8.1 |
| Sports | 7.47 | 3/3 | 2 | 8.4 |
| Strategy | 7.33 | 3/3 | **0** | 7.7 |

The weakest specialty fits are concrete even with full Scope and zero Bugs. Racing's best own-Genre title had Core `29/47/35/29` against target `40/33/46/13`: Graphics and Technology were each **11** short, Review **7.2**. Puzzle's best had Design `45` versus target `59` (Review **7.7**). Strategy's best had Technology `42` versus `53` and Design `43` versus `46` (Review **7.7**). Action's best was **7.8** with Graphics `38/40` and Technology `37/40`, a narrower gap that may still depend on variance. These are observed title deficits, **not** approved card grants or a guaranteed path to 8.0. [Full first/Core/Scope/Bug records](sims/rival-eight-ceiling-F-4417-20261027-v1/prestart-shadow.json) and the other two seed files retain each case.

## Recommendation

Treat **Racing, Puzzle, Strategy and Action** as the first four capability-planning cases. A shared broad pool and a generic highest-fit Genre selector naturally route their later games into Role-Playing, Simulation or Sports; requiring them to publish their specialty anyway would knowingly mismatch the current Core vector. Build distinct legally acquired, specialty-directed Feature pools and the LOCKED jointly attainable funded Core/Store planner, then test whether each can earn a specialty 8.0+ through legal hands while its first historical game stays near 6.0–7.0. Preserve the user-directed one-per-Genre population and 1977 first-release-generated standard sequence; neither exists in this diagnostic.

The next private comparison should vary only authored/paid specialty Feature progression and a genuine full-project cash/hand plan, keeping Review arithmetic and frozen standards fixed at first. Measure own-Genre Core, Review, Scope, Bugs, purchase receipts and release timing for all eight; retain a no-fit Studio outcome when an affordable specialty plan does not exist. Then evaluate proposed 1977 bootstrap/standard generation, shared population Market pressure, player challenge, save/Continue and CPU separately. The number of starting Features, 35-Scope composition, Store paths, affordability envelope, suitability threshold and attainment frequency remain **OPEN**. No TODO implementation handoff follows from this ceiling screen.
