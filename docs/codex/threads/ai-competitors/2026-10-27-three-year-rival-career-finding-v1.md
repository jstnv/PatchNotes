# Three-year rival career and Genre-fit screen — finding, 2026-10-27

**Status: DESIGN evidence, no adoption.** This follows the [predeclared 72-cycle plan](2026-10-27-three-year-rival-career-plan-v1.md) and [Genre-fit addendum](2026-10-27-three-year-genre-followup-plan-v1.md). The question was whether the best bounded legal controller from the earlier [Store/Beta study](2026-10-27-core-store-beta-timing-finding-v1.md), or the later [funded two-purchase and Genre screen](2026-10-27-funded-core-and-genre-study-finding-v1.md), could produce *several* 8.0+ games over a full three-year career. **Neither did in the three declared seeds.**

## Source, legality and reproduction

- The source calendar is 24 cycles/year and rent settles every two cycles. A January 1977 to January 1980 prelude is **72 cycles**. These private old-cohort sessions start in source year **1980** and run 72 *relative* cycles; they are a career-duration proxy, not an actual 1977 opening or generated January 1980 Market. Earlier c36/c48 labels as a January-equivalent were corrected; c36 is 18 months and c48 is 24 months.
- U: [private variant](simulators/rival-three-year-career-20261027-v1), child of the prior P one-Store/Search-receipt controller; gameplay source identity `76407b2d02801d219e08286964b3df1d6cf94c2efee891cdb8141ae1bad86398`. Only its private probe changed to cycle72/max300 decisions/studio. [Successful bundle](sims/rival-three-year-U-bundle-20261027-v1), manifest SHA-256 `69cd4daa6be1e32e3beb8a57c27f2db72aa9ec3bbb0390d2e0822b10ec9f5c88`.
- V: [private variant](simulators/rival-three-year-genre-20261027-v1), child of the prior S two-purchase/diagnostic Genre-fit controller; gameplay source identity `c037a1dba91fe3a9619309e6c46301a97c1dc6c980677720d65d78007f4e29ae`. Only its private probe changed to the same cycle72/max300 horizon. [Successful bundle](sims/rival-three-year-V-bundle-20261027-v2), manifest SHA-256 `cd891e89e19e0458cb2b3ae67e950705e15241ac361dd1ceee22ca1e892ab166`. Both variants retain their original canonical baseline and ancestry.
- Checkout at measurement: `main`, HEAD `f3e0f2b5d35270c879327bc297b389748571feb4`; other Store/checkpoint/TODO edits were concurrent and preserved. Both variants use the old 35-Scope two-rival cohort, 1980 trial Genre targets, neutral solo Market, real legal Store/Bank/hands/QA/Review, actual sales/cash and RNG. They do not model the current 12-Scope new-Studio cohort, one rival per Genre, eight-rival CPU, shared saturation, frozen pre-1980 games, migrations or player response. Godot `4.7.1.stable.official.a13da4feb`, executable SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`.
- Seeds `4417`, `4423`, `4431`, two rival careers per seed; one 50-command smoke per variant, 240-second process bound, no artificial release target, cycle72 stop. Cycle-zero state/RNG and first actual release records were byte-identical for each paired U/V studio. U's first two releases matched its P prefix. Reviews and Core below are actual accepted releases, not forecast Review substitutions.

Exact command pattern (each seed and arm used a unique output; the output `*.command.json` and `*-run.json` give the fully expanded command and receipt):

```powershell
$pnPython='C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$pnGodot='C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
& $pnPython tools/simulate.py run --variant docs/codex/threads/ai-competitors/simulators/rival-three-year-genre-20261027-v1 --config docs/codex/threads/ai-competitors/six-hand-phase-study-20261023-v1/smoke.json --output docs/codex/threads/ai-competitors/sims/rival-three-year-V-bundle-20261027-v2 --godot $pnGodot --timeout 240
& $pnPython docs/codex/threads/ai-competitors/run_low_review_cause_probe_v2.py --bundle docs/codex/threads/ai-competitors/sims/rival-three-year-V-bundle-20261027-v2 --output docs/codex/threads/ai-competitors/sims/rival-three-year-V-4417-20261027-v1 --seed 4417 --godot $pnGodot
& $pnPython tools/simulate.py replay --bundle docs/codex/threads/ai-competitors/sims/rival-three-year-V-bundle-20261027-v2 --case foundation-legal-action-4417 --output docs/codex/threads/ai-competitors/sims/rival-three-year-V-replay-20261027-v1 --godot $pnGodot --timeout 240
```

The same commands with U's paths ran the U arm; the same probe command with `4423` and `4431` ran the other declared seeds. The U and V smoke runs each completed 18 legal commands, and their fresh 18-command replays passed. U seed4417 fresh repeat matched result SHA-256 `aceee59781f2ae1941bbff13287d223e5b79e7bc2cd46bc1f14bc9bf76007278`; V seed4431 fresh repeat matched `1c3f633e752b55f0a6a7c61b10b8daf49fc47a8728eed24973cd38f319f01343`. No career had an illegal action, failure, timeout or early stop. V's first smoke output [v1](sims/rival-three-year-V-bundle-20261027-v1) was rejected by the canonical-source drift fence during concurrent edits and was retained; it supplies no behavior evidence. The successful V run used a new v2 output.

## Actual career results

Each cell is Review at release cycle, in project order. Full review/Core/Scope/Bug records, actions, finances and final active project appear in the linked outputs.

| Seed | Studio | U: one-Store controller | V: two-purchase plus predicted Genre fit |
| --- | --- | --- | --- |
| 4417 | Arcade | 5.9 c14, **8.0 c34**, 6.3 c50, **8.7 c69** | 5.9 c14, 7.8 c35, 6.7 c52, **8.0 c70** |
| 4417 | Wayfinder | 6.4 c13, 7.1 c34, 6.3 c48, 7.5 c65 | 6.4 c13, 7.5 c33, 7.2 c48, 7.2 c65 |
| 4423 | Arcade | 7.7 c16, 7.4 c38, 7.2 c56; game4 in Beta at c72 | 7.7 c16, 6.8 c39, 6.9 c57; game4 in Beta at c72 |
| 4423 | Wayfinder | 5.6 c15, 6.9 c34, 7.2 c50, 6.7 c67 | 5.6 c15, 6.7 c35, 7.0 c51, 6.3 c68 |
| 4431 | Arcade | 6.2 c17, 6.5 c33, 6.6 c48, 7.6 c66 | 6.2 c17, 6.1 c31, 6.7 c47, 7.9 c66 |
| 4431 | Wayfinder | 7.0 c16, 7.0 c35, 7.2 c50, 7.4 c70 | 7.0 c16, **8.1 c39**, 7.4 c54; game4 in Beta at c72 |

U published **23** games, mean Review **6.97**, with two 8.0+ games; both came from Arcade seed4417. V published **22**, mean **6.96**, with two 8.0+ games; Arcade seed4417 and Wayfinder seed4431 each made one. No tested seed produced two 8.0+ games from *distinct* studios by c72; seed4423 produced none in either arm. By c48 U had one high Review in seed4417, while V had one in seed4431. The second release of V Wayfinder seed4431 was 8.1 at c39 with actual Core `29/28/39/44`, Scope `37/30`, zero Bugs. V Arcade seed4417's 8.0 at c70 had Core `40/30/35/32`, Scope `37/30`, zero Bugs. Those are earned through legal actions, but they are sparse outcomes.

**Capital versus capability:** Every U studio began with 24 owned Features and ended with exactly 25; V's ended with 26 in five careers and 24 in the one Bank-liability case. Final cash across the twelve careers was **$16,648.64–$22,058.23**. The tested policies stopped at one or two acquisitions despite later sale proceeds, so they did not turn profitable careers into a widening Core/Feature pool. This is a policy limitation of these versions, not evidence that a larger real Store plan is affordable at every earlier decision boundary. U had two careers with a loan; V had three. Each output retains the due/loan and purchase receipts for a full cash-flow check.

[U 4417](sims/rival-three-year-U-4417-20261027-v1) · [U 4423](sims/rival-three-year-U-4423-20261027-v1) · [U 4431](sims/rival-three-year-U-4431-20261027-v1) · [V 4417](sims/rival-three-year-V-4417-20261027-v1) · [V 4423](sims/rival-three-year-V-4423-20261027-v1) · [V 4431](sims/rival-three-year-V-4431-20261027-v1).

## Design consequence

The extra career time permits three or four releases per studio, but **time, one or two Store acquisitions and a one-project printed-Core Genre guess do not reliably create several 8.0+ incumbents in one opening save**. V improved some Wayfinder Reviews and widened which studio can reach 8, yet it also delayed or lowered other titles. Later profit remained largely uninvested. V is not an approved AI policy. Neither result warrants fabricated starting Reviews, a Core bonus or reduced market standards.

The next private candidate should implement the already **LOCKED qualitative F1–F6 shopping screen** as a genuinely *jointly legal* finite-project four-Core estimator: exact Design/Alpha hand and finite-use feasibility, completed conditional Store quote, known dues/full-project cash allocation, and actual Genre fit from the same attainable plan. Compare legal completed purchases to P before scaling. The finite horizon, Project budget, quote/CPU implementation, purchase count, fallback and numerical success criterion are **OPEN**. Then test a fresh eight-specialist 1977→1980 shared-world prelude and validate frozen historical archive accounting, current trial Market standards and new-save Continue. This study supplies a negative gate for the existing candidates; it does not supply a January 1980 adoption handoff or a TODO implementation entry.

The [same-day later Store/Genre screen](2026-10-27-reinvestment-and-later-genre-finding-v1.md) corrected an initially unreachable reinvestment route and tested ten additional legal acquisitions across the six careers. It raised mean Review slightly but still yielded only two 8.0+ releases, so this recommendation remains.
