from run import *
a=load(HERE/'analysis.json');v=load(HERE/'closeout.json');paired=load(HERE/'paired.json')
assert a['status']==v['status']==paired['status']=='PASS'
stem='CROWN-TWOHAND';finding=stem+'-FINDINGS-2026-10-25-v1.md';handoff=stem+'-HANDOFF-2026-10-25-v1.md'
link='studies/'+HERE.name
rows=[]
for r in a['rows']:
    awards='/'.join(f"{x['award']/100:g}" for x in r['results'])
    rows.append(f"| {r['case']} | {awards} | {r['reputation_bp']/100:g} | {r['full']} | {r['zero']} | {r['final_cycle']} | ${r['cash']/100:,.2f} |")
text=f'''# Crown Brief CB2b: stronger two-hand planning

2026-10-25. **COMPLETE at bounded private research scope; Crown terms/activation remain OPEN.** User authorized stronger planning with rewards unchanged and redraws parked. [Fixed pre-run plan]({link}/PLAN.md), [independent review]({link}/REVIEW.md), [handoff]({handoff}). Prior [CB2 findings](CROWN-BRIEF-PILOT-FINDINGS-2026-10-25-v1.md) remain valid for their source/cohort.

## Result and recommendation

Both planners earn **12.50R instead of10R** on each of two legal starts, a2.50R increase with no additional cycles or cash difference against greedy. Each still has one zero Brief; neither reaches proposedR20 within three opportunities. The mean and downside policies have identical command trajectories, checkpoints and outcomes per seed: these are **two distinct starting-state outcomes**, not four independent improvements.

Retain the simpler expected-final-grade planner as the private simulation comparator. No demonstrated benefit from the extra downside objective; do not call it safer. Keep rewards unchanged and redraw research parked. Planning helps this cohort but does not establish reliable three-opportunityR20, broader accessibility or human comprehension. Do not tune rewards or queue canonical activation from these results.

| Case | Per-Brief R | Total R | Full | Zero | Final cycle | Cash |
|---|---|---:|---:|---:|---:|---:|
{chr(10).join(rows)}

All six cases:109 accepted commands each,654 total,18 Briefs,three additional releases; no rejected commands/timeouts. Final releases7 on4521 and6 on4522. Every Brief costs exactly two productive cycles and grants zero cash/Promotion/Investment; existing cash Contract rewards remain inherited unchanged. Minimum cash $8,515.44/$7,972.51 respectively, no observed overdue balance. Same six added Brief cycles as prior CB2. Equal-release cash and calendar match greedy exactly; comparison with skipping Briefs remains the separate prior CB2 result, not a new skip run.

## Setup, source and legal starts

- Branch `{v['branch']}`, HEAD `{v['head']}`, shared dirty workspace preserved. This is a frozen historical comparison; concurrent canonical drift is explicitly retained in [intake]({link}/intake.json) and [closeout]({link}/closeout.json), including UI/font and rival checkpoint paths. Do not claim latest canonical behavior or copy old source over those edits.
- New owned child `simulators/crown-twohand-planning-20261025-v1`, parent `crown-brief-pilot-20261025-v1`. Original canonical baseline `{v['base_identity']}`. Child/parent candidate project identical `{v['candidate_identity']}`. Executed mechanics `{v['source_identity']}`. Original baseline/ancestry preserved. **Zero runtime delta versus CB2**; no new schema/reward/gameplay changes. External policy/experiment inputs have separate [hash pins]({link}/policy-pins.json).
- Reuse exact CB2 earned Studio-only Action/no-Trait prefixes: seed4521 unlocked at Game4/cycle60, seed4522 at Game3/cycle43. No injected money/cards/scores, altered envelopes or RNG fence bypass. First run both greedy controls: final state/RNG, full telemetry, tape and checkpoint reproduce exactly. [Control proof]({link}/controls-verification.json).
- Three policies per seed,180-command maximum, absolute release targets7/6, at mostthree Briefs orR20. Identical initial state/RNG and same visible first deal at every opportunity. Two host runners maximum,600seconds per import/experiment; immutable new output/profile directories. Ordinary inherited development redraws unchanged; Briefs use no redraw or priority commands. Beta tuning parked.

## Planner and model audit

On hand1 enumerate35 quartets; for each, use256 fixed eight-dimensional Halton refill scenarios and enumerate35 final quartets,313,600 modeled final evaluations. All seven visible finite Features are unavailable to refill whether played or retained; exclude exhausted/previously sampled finite Features, permit repeated renewable Passes, weight available categories by current priorities and choose sorted definitions uniformly. The model consumes no actual RNG and sees no actual future cards. On hand2 choose exact best visible grade, then completion/narrow spread/index order.

Mean ranks sum of final grade/full count/positive count/narrow first spread/index; downside first ranks mean plus bottom-quarter mean, then mean and remaining ties. Unchanged formula in Core half-units: completion=floor(10000*(2min(S,9)+sum min(H_i,8)+2min(minH,8))/66); balance=max(0,10000-1250max(0,maxH-minH-4)); standing basis points=floor(min(completion,balance)/10).100bp=1R. Both arms use the identical existing reward evaluator.

Python reconstructs all12 modeled first-hand records, all35 rankings and256 grades per ranking (3,763,200 modeled final evaluations total), sampled definition IDs, policy choices, actual played cards, synergy, saved scores, once-only standing and no-currency/two-cycle accounting. **{a['checks']:,} audit assertions pass**, plus{paired['checks']} paired trajectory assertions. These counts are not independent experiments. All six distinct first-hand choices differ from greedy. Mean/downside choose identically;128-prefix diagnostic choices also agree at all six situations, which is not a convergence proof. Calculation time484–713ms per first hand on this host, not a UI performance target.

Five of six distinct chosen situations have modeled bottom-quarter grade0. Their modeled zero fractions range68/256 to145/256; the remaining favorable4522 second Brief has1/256 modeled zeros and149/256 full grades. These are model frequencies, not measured population probabilities. Observed zero outcomes remain4521 first Brief and4522 third Brief. Full result4522 second Brief earns10R with Scope9 and Core half-units[14,16,16,18]. Retain both the full witness and failures; do not infer perfect play or guaranteed progression.

## Verification, failures and limits

- PASS: exact controls; public-information sampler/source review; independent model/actual settlement audit; identical-policy pair audit. [Analysis]({link}/analysis.json), [paired proof]({link}/paired.json).
- PASS: fresh-process exact replays of mean4521 and downside4521,109 commands/110 samples each. Best/worst totals tie within each planner, so predeclared tie rule selects4521; no new4522 replay is claimed. Retained zero result is part of each replay.
- PASS: cold Studio-only Continue from `{v['cold']['source_case']}`, exact initial state/RNG, {v['cold']['commands']} accepted commands, one more release to Game{v['cold']['releases']}/cycle{v['cold']['cycle']}; Briefs skipped.
- Reused unchanged CB2 runtime suite evidence: contract challenge runtime, challenge matrix and publisher relationships. Source equality verified; **no fresh suite run** claimed.
- One **analysis-tool failure** retained: first Python audit assumed enum-keyed Core/priorities dictionaries were arrays. Fixed only decoder after inspecting raw data; frozen policy/config/source/cases unchanged. [Original audit and repair]({link}/AUDIT-REPAIR.md). No simulation case discarded or rerun to improve results. Failure reduction not applicable: no rejected command prefix.
- Retained warning summary: `{json.dumps(v['warnings'])}`. No hidden-error suppression; see raw logs/manifest. These warnings do not establish release readiness.
- NOT RUN here: fresh/poor/other-specialty starts, populated active rivals, extended progression beyond three Briefs, human comprehension, UI/export/migration/cap-clipping/atomic rejection acceptance. The modeled pool is public to the simulation; equivalent player-facing planning clarity is not demonstrated. Private prototype numeric rules, R20 and activation remain OPEN. SideStreet ACTIVE/TRIAL and existing approved Contracts rules unchanged.

## Exact reproduction and evidence

Bundled Python `{PY}`; Godot `{GODOT}`. From repository root, `setup.py`, `prepare_policy.py`, `run.py controls`, `check_controls.py`, then `run.py planning-4521` and `run.py planning-4522`; corrected `audit.py`, `paired.py`, `verify_runs.py`, `closeout.py` in [{HERE.name}]({link}/PLAN.md). The helpers contain exact `tools/simulate.py run --variant ... --config ... --output ... --timeout 600 --godot ...` and replay arguments. Each `*-command.json` and `*-exit.json` records full absolute paths, timeout and return status; [closeout]({link}/closeout.json) collects them. Raw output folders are immutable: rerunning requires a newly named study/output and explicit provenance, not overwriting these receipts.

Raw evidence root `{RAW}`. [Manifest]({link}/evidence-manifest.json) hashes compact receipts, configs, cases, tapes, telemetry, logs and profiles; complete frozen runner projects remain outside OneDrive in those bundles. Variant creation command: `tools/simulator_variant.py create --id crown-twohand-planning-20261025-v1 --owner contracts --from-variant docs/codex/threads/contracts/simulators/crown-brief-pilot-20261025-v1 --output docs/codex/threads/contracts/simulators/crown-twohand-planning-20261025-v1`.

No canonical gameplay/test/asset/config edits, player-save access, computer control, commit or push by this study. Concurrent source edits belong to their owners. Shared TODO receives a minimal DESIGN review update only.
'''
(THREAD/finding).write_text(text,encoding='utf-8')
(THREAD/handoff).write_text(f'''# Crown CB2b — versioned design review handoff

2026-10-25. **DESIGN review; no canonical adoption approved.** [Findings]({finding}), [fixed plan]({link}/PLAN.md), [source/verification]({link}/closeout.json). User approved this private planning experiment with unchanged rewards and parked redraws. Crown numerical/activation terms remain OPEN; existing rules and SideStreet ACTIVE/TRIAL unchanged.

| Item | Status | Task / acceptance / dependency |
|---|---|---|
| CB2b experiment | **implemented and verified — private research only** | Six matched cases654 accepted commands; stronger two-hand choices earn12.50R vs10R per start. Full/zero outcomes, exact controls,2135 model/actual assertions, paired checks, two replays and cold Studio Continue retained. NoR20 or reduced zero rate. |
| Retain expected-grade comparator | **proposed** | Use the pinned `policy.gd` mean arm for subsequent authorized Crown studies. Accept exact public-pool source law/no hidden RNG, fixed bounds, legal fresh prefixes for different mechanics, no reward/redraw changes. Do not install as canonical/default AI or player assistance. Downside adds no observed benefit. |
| Crown player-facing planning specification | **proposed** | Define understandable preview of current Cores/Scope, completion versus balance penalty, retained cards and final reward. Clearly distinguish present guarantees from hypothetical future cards; no hidden optimality claim. Depends on review of Crown terms; no UI implementation queued by this entry. Human understanding remains untested despite stronger computer planning. |
| CB3 structural adoption acceptance | **proposed; gated** | Keep prior lifecycle/source/terms snapshots, requested-versus-credited cap, atomic rejection/duplicate restoration, separate cash counts, owner/publisher isolation, named prospective predecessor migration, populated active-rival handling, UI/projections and Studio-only Continue requirements. Explicitly rebase against current source before new tests. Existing research does not close these gates. |
| CB4 activation / later commissions/support | **proposed; held** | Requires explicit numerical/activation approval and CB3; later deals require separate approval/evidence. Do not promiseR20 after three Briefs. No reward or redraw changes authorized here. |
| Internal review routing | **handed off through minimal DESIGN TODO entry when publication receipt passes** | Preserve every unrelated entry; no QUEUED implementation, chat dispatch, commit or push. |

## Exact delta and ancestry

Child `simulators/crown-twohand-planning-20261025-v1` is byte-identical in project content to CB2 parent; **zero new runtime/schema/reward delta**. External supplied policy adds only first-hand mean/downside model plus diagnostic logs, preserving final-hand greedy and inherited development policy. [Policy/input hashes]({link}/policy-pins.json), [independent review]({link}/REVIEW.md).

Canonical baseline `{v['base_identity']}`, unchanged parent/child candidate `{v['candidate_identity']}`, executed mechanics `{v['source_identity']}`, captured Git HEAD `{v['head']}` on dirty `{v['branch']}`. Current canonical drift retained; no silent current-source claim. Original thirteen-path CB2 runtime prototype remains in the [prior sealed review packet](handoffs/crown-brief-pilot-20261025-v3/HANDOFF.md), which is not an adoption-ready migration or approval. Do not create a second runtime patch for this policy-only experiment or adopt the failed prior partial packet.

Recommendation: keep rewards and park redraws; retain modest planning improvement as evidence, then review planning presentation and the existing Crown adoption specification. Broad accessibility, required reputation pacing, numerical approval and human clarity are genuine unresolved design gates.
''',encoding='utf-8')
(THREAD/'SESSION-LOG-2026-10-25-crown-twohand-v1.md').write_text(f'''# Contracts session — Crown CB2b,2026-10-25

Branch `{v['branch']}`, HEAD `{v['head']}`, dirty shared worktree preserved; intake status/diff/branch/HEAD under `{link}`. No canonical source edits, player saves, computer control, commit or push. Preserve `.codex-godot-temp`.

Created private child simulator and thread-owned study scripts/configs/plan/pins/audit/results/review/manifest, [{finding}]({finding}), [{handoff}]({handoff}), this log. Updated thread README/HANDOFF summaries and only Crown DESIGN paragraph in shared TODO; byte-preservation receipts in study. Source ancestry, current canonical drift and exact commands/exits: [closeout]({link}/closeout.json).

PASS: two exact greedy controls; four candidate cases;654 accepted commands/18 Briefs;2135 audit assertions and{paired['checks']} paired checks; two exact109-command/110-sample replays; cold Continue{v['cold']['commands']} commands, exact state/RNG. Reused3 unchanged CB2 suite receipts; no fresh suites. One retained Python decoder failure repaired without policy/case changes; no rejected campaign/timeouts. Warnings in manifest.

Result: both planners12.50R vs10R on both starts, same cash/calendar, one zero each/noR20. Mean/downside identical; retain mean as proposed private comparator. Rewards unchanged; Brief/Beta redraw work parked. User approval of Crown values/activation, broader accessibility/pacing, migration/active-rival/atomic rejection/UI/export and human understanding remain OPEN. Follow-up: planning presentation/specification review and existing adoption gates, not reward tuning.
''',encoding='utf-8')
print('Dated findings, review handoff and session log written.')
