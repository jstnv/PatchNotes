# Crown Brief CB2b: stronger two-hand planning

2026-10-25. **COMPLETE at bounded private research scope; Crown terms/activation remain OPEN.** User authorized stronger planning with rewards unchanged and redraws parked. [Fixed pre-run plan](studies/crown-twohand-20261025-v1/PLAN.md), [independent review](studies/crown-twohand-20261025-v1/REVIEW.md), [handoff](CROWN-TWOHAND-HANDOFF-2026-10-25-v1.md). Prior [CB2 findings](CROWN-BRIEF-PILOT-FINDINGS-2026-10-25-v1.md) remain valid for their source/cohort.

## Result and recommendation

Both planners earn **12.50R instead of10R** on each of two legal starts, a2.50R increase with no additional cycles or cash difference against greedy. Each still has one zero Brief; neither reaches proposedR20 within three opportunities. The mean and downside policies have identical command trajectories, checkpoints and outcomes per seed: these are **two distinct starting-state outcomes**, not four independent improvements.

Retain the simpler expected-final-grade planner as the private simulation comparator. No demonstrated benefit from the extra downside objective; do not call it safer. Keep rewards unchanged and redraw research parked. Planning helps this cohort but does not establish reliable three-opportunityR20, broader accessibility or human comprehension. Do not tune rewards or queue canonical activation from these results.

| Case | Per-Brief R | Total R | Full | Zero | Final cycle | Cash |
|---|---|---:|---:|---:|---:|---:|
| balanced-4521 | 0/7.5/2.5 | 10 | 0 | 1 | 110 | $22,134.20 |
| balanced-4522 | 2.5/7.5/0 | 10 | 0 | 1 | 95 | $27,839.17 |
| mean-4521 | 0/7.5/5 | 12.5 | 0 | 1 | 110 | $22,134.20 |
| downside-4521 | 0/7.5/5 | 12.5 | 0 | 1 | 110 | $22,134.20 |
| mean-4522 | 2.5/10/0 | 12.5 | 1 | 1 | 95 | $27,839.17 |
| downside-4522 | 2.5/10/0 | 12.5 | 1 | 1 | 95 | $27,839.17 |

All six cases:109 accepted commands each,654 total,18 Briefs,three additional releases; no rejected commands/timeouts. Final releases7 on4521 and6 on4522. Every Brief costs exactly two productive cycles and grants zero cash/Promotion/Investment; existing cash Contract rewards remain inherited unchanged. Minimum cash $8,515.44/$7,972.51 respectively, no observed overdue balance. Same six added Brief cycles as prior CB2. Equal-release cash and calendar match greedy exactly; comparison with skipping Briefs remains the separate prior CB2 result, not a new skip run.

## Setup, source and legal starts

- Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, shared dirty workspace preserved. This is a frozen historical comparison; concurrent canonical drift is explicitly retained in [intake](studies/crown-twohand-20261025-v1/intake.json) and [closeout](studies/crown-twohand-20261025-v1/closeout.json), including UI/font and rival checkpoint paths. Do not claim latest canonical behavior or copy old source over those edits.
- New owned child `simulators/crown-twohand-planning-20261025-v1`, parent `crown-brief-pilot-20261025-v1`. Original canonical baseline `0ac7ab3da4ac7499a56a5eb9bfd0690422157e73910516ebffc77b40e12c163b`. Child/parent candidate project identical `f3e470f5e7f2f22eb1af8e3fdabe5d72457421ae3115f4020395c5467abdb3ad`. Executed mechanics `4b817896b436bc0770640a0422cfc8757e76fdf33375adce26c96572a805f18a`. Original baseline/ancestry preserved. **Zero runtime delta versus CB2**; no new schema/reward/gameplay changes. External policy/experiment inputs have separate [hash pins](studies/crown-twohand-20261025-v1/policy-pins.json).
- Reuse exact CB2 earned Studio-only Action/no-Trait prefixes: seed4521 unlocked at Game4/cycle60, seed4522 at Game3/cycle43. No injected money/cards/scores, altered envelopes or RNG fence bypass. First run both greedy controls: final state/RNG, full telemetry, tape and checkpoint reproduce exactly. [Control proof](studies/crown-twohand-20261025-v1/controls-verification.json).
- Three policies per seed,180-command maximum, absolute release targets7/6, at mostthree Briefs orR20. Identical initial state/RNG and same visible first deal at every opportunity. Two host runners maximum,600seconds per import/experiment; immutable new output/profile directories. Ordinary inherited development redraws unchanged; Briefs use no redraw or priority commands. Beta tuning parked.

## Planner and model audit

On hand1 enumerate35 quartets; for each, use256 fixed eight-dimensional Halton refill scenarios and enumerate35 final quartets,313,600 modeled final evaluations. All seven visible finite Features are unavailable to refill whether played or retained; exclude exhausted/previously sampled finite Features, permit repeated renewable Passes, weight available categories by current priorities and choose sorted definitions uniformly. The model consumes no actual RNG and sees no actual future cards. On hand2 choose exact best visible grade, then completion/narrow spread/index order.

Mean ranks sum of final grade/full count/positive count/narrow first spread/index; downside first ranks mean plus bottom-quarter mean, then mean and remaining ties. Unchanged formula in Core half-units: completion=floor(10000*(2min(S,9)+sum min(H_i,8)+2min(minH,8))/66); balance=max(0,10000-1250max(0,maxH-minH-4)); standing basis points=floor(min(completion,balance)/10).100bp=1R. Both arms use the identical existing reward evaluator.

Python reconstructs all12 modeled first-hand records, all35 rankings and256 grades per ranking (3,763,200 modeled final evaluations total), sampled definition IDs, policy choices, actual played cards, synergy, saved scores, once-only standing and no-currency/two-cycle accounting. **2,135 audit assertions pass**, plus52 paired trajectory assertions. These counts are not independent experiments. All six distinct first-hand choices differ from greedy. Mean/downside choose identically;128-prefix diagnostic choices also agree at all six situations, which is not a convergence proof. Calculation time484–713ms per first hand on this host, not a UI performance target.

Five of six distinct chosen situations have modeled bottom-quarter grade0. Their modeled zero fractions range68/256 to145/256; the remaining favorable4522 second Brief has1/256 modeled zeros and149/256 full grades. These are model frequencies, not measured population probabilities. Observed zero outcomes remain4521 first Brief and4522 third Brief. Full result4522 second Brief earns10R with Scope9 and Core half-units[14,16,16,18]. Retain both the full witness and failures; do not infer perfect play or guaranteed progression.

## Verification, failures and limits

- PASS: exact controls; public-information sampler/source review; independent model/actual settlement audit; identical-policy pair audit. [Analysis](studies/crown-twohand-20261025-v1/analysis.json), [paired proof](studies/crown-twohand-20261025-v1/paired.json).
- PASS: fresh-process exact replays of mean4521 and downside4521,109 commands/110 samples each. Best/worst totals tie within each planner, so predeclared tie rule selects4521; no new4522 replay is claimed. Retained zero result is part of each replay.
- PASS: cold Studio-only Continue from `mean-4521`, exact initial state/RNG, 29 accepted commands, one more release to Game8/cycle124; Briefs skipped.
- Reused unchanged CB2 runtime suite evidence: contract challenge runtime, challenge matrix and publisher relationships. Source equality verified; **no fresh suite run** claimed.
- One **analysis-tool failure** retained: first Python audit assumed enum-keyed Core/priorities dictionaries were arrays. Fixed only decoder after inspecting raw data; frozen policy/config/source/cases unchanged. [Original audit and repair](studies/crown-twohand-20261025-v1/AUDIT-REPAIR.md). No simulation case discarded or rerun to improve results. Failure reduction not applicable: no rejected command prefix.
- Five retained logs report six ObjectDB instances leaked at exit. See raw logs and the manifest; these warnings do not establish release readiness.
- NOT RUN here: fresh/poor/other-specialty starts, populated active rivals, extended progression beyond three Briefs, human comprehension, UI/export/migration/cap-clipping/atomic rejection acceptance. The modeled pool is public to the simulation; equivalent player-facing planning clarity is not demonstrated. Private prototype numeric rules, R20 and activation remain OPEN. SideStreet ACTIVE/TRIAL and existing approved Contracts rules unchanged.

## Exact reproduction and evidence

Bundled Python `C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`; Godot `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`. From repository root, `setup.py`, `prepare_policy.py`, `run.py controls`, `check_controls.py`, then `run.py planning-4521` and `run.py planning-4522`; corrected `audit.py`, `paired.py`, `verify_runs.py`, `closeout.py` in [crown-twohand-20261025-v1](studies/crown-twohand-20261025-v1/PLAN.md). The helpers contain exact `tools/simulate.py run --variant ... --config ... --output ... --timeout 600 --godot ...` and replay arguments. Each `*-command.json` and `*-exit.json` records full absolute paths, timeout and return status; [closeout](studies/crown-twohand-20261025-v1/closeout.json) collects them. Raw output folders are immutable: rerunning requires a newly named study/output and explicit provenance, not overwriting these receipts.

Raw evidence root `C:\Users\64jus\Downloads\Patch Notes Design Folder\Simulator Evidence\Contracts\crown-twohand-20261025-v1`. [Manifest](studies/crown-twohand-20261025-v1/evidence-manifest.json) hashes compact receipts, configs, cases, tapes, telemetry, logs and profiles; complete frozen runner projects remain outside OneDrive in those bundles. Variant creation command: `tools/simulator_variant.py create --id crown-twohand-planning-20261025-v1 --owner contracts --from-variant docs/codex/threads/contracts/simulators/crown-brief-pilot-20261025-v1 --output docs/codex/threads/contracts/simulators/crown-twohand-planning-20261025-v1`.

No canonical gameplay/test/asset/config edits, player-save access, computer control, commit or push by this study. Concurrent source edits belong to their owners. Shared TODO receives a minimal DESIGN review update only.
