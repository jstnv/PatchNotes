from setup import HERE, ROOT, RAW, write
import json
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
money=lambda n:('-' if int(n)<0 else '')+f'${abs(int(n))/100:,.2f}'

def main():
    a=load(HERE/'analysis.json');v=load(HERE/'verification.json');e=load(HERE/'evidence-manifest.json');s=load(HERE/'supply-diagnostic.json')
    assert a['complete'] and len(a['rows'])==12 and v['cold_state_match'] and v['cold_rng_match']
    thread=HERE.parents[1];ref='studies/crown-acquisition-20261024-v1/'
    lines=['# Crown affordable acquisition — findings v1','',
        '2026-10-24. **COMPLETE bounded design evidence; no gameplay or balance adoption.**',
        '', '## Recommendation','',
        'Keep Crown’s existing Review7 gate and publisher rewards. Existing affordable Primitive reserve purchases improve access in this small cohort, but a mandatory buy-to-30 policy is not justified: it delays the already viable Action seed4522 route by15 cycles and reduces cash. First investigate using already-owned Features before buying more; then separately test selective Core-aware acquisition, especially Puzzle Sound. Keep Crown relationship activation/migration OPEN.',
        '', '## Authority, design and exact sources','',
        f'[Predeclared plan](CROWN-ACQUISITION-PLAN-2026-10-24-v1.md) · [proposed handoff](CROWN-ACQUISITION-HANDOFF-2026-10-24-v1.md) · [intake]({ref}intake.json) · [source drift from CP1c]({ref}baseline-drift.json). User authorized this follow-up with “Go ahead and cook.” No policy thresholds became approved gameplay.',
        '', '- Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared checkout;158 tracked changed files at intake. Existing edits and `.codex-godot-temp` preserved.',
        f'- Variant `crown-acquisition-v1`, owner Contracts; baseline `{v["variant_base"]}`; candidate `{v["variant_candidate"]}`.',
        f'- Actual common mechanics identity: `{a["identities"][0]["source"]}`.',
        f'- Policy SHA256: `{a["identities"][0]["policy"]}`. Runner: `{a["identities"][0]["runner"]}`. Godot: `{a["identities"][0]["godot"]}`.',
        '- Only private project delta: copied historical debug helper `scripts/debug/crown_access_legacy_v1.gd`, hash `1ee14d9a22b0cbfc58a80a16e2f68db06e20aad33ddf1cab5e60124b99936b55`. No mechanics delta. External policy changes decisions only. Protected baseline/ancestry hashes pass; canonical source is byte-identical to this study’s baseline at closeout.',
        '- Newer tutorial/UI and rival checkpoint source differ from CP1c. All starts were regenerated legally; no old checkpoint identity was patched or reused across revisions. Six within-study pairs have exact equal initial state/RNG, shared mechanics, runtime, runner, policy and all non-import source.',
        '', '## Setup and assumptions','',
        'Seeds4521/4522 × Action/Puzzle/Simulation × control/acquire, no Traits or employees:12 declared independent campaigns. Six-release/280-command limits; six two-case batches, at most two isolated runners concurrently,600-second execution limit per invocation. Control executes first in each pair; the first pair passed before remaining batches started. No failures required the predeclared timeout recovery. No seed/budget/policy changes occurred after execution began.',
        '', 'Both arms retain CP1c specialty/Fantasy, genre-normalized production scoring, priorities, phase ceilings3/2/3 then6/4/6, one visible-card redraw per phase, Beta QA/stopping and cash-Contract decisions. Both correct the play-cost estimate to existing mechanics: later Store cards cost zero to play, Primitive Feature fees retain the printed formula. No later Store card was actually bought here, so the correction has no measured treatment exposure.',
        '', 'Candidate reconsiders exact legal quotes after each release, at most one completion per release window and five overall, stopping at owned finite Scope30. It ranks useful missing Scope per completion-payment-plus-Research-rent expense; ties prefer minimum normalized printed owned Core coverage, then ID. Admission requires quoted down/remaining payments, Research rent and a $4,000 reserve. This reserve is an admission screen, not an invariant cash floor. No loans, employees, hidden bugs/RNG, fabricated money, custom cards, or publisher relationship deals. Pending FIFO work uses a fresh exact quote. The current engine remains the legality authority.',
        '', '## Results','',
        '| Start | No-purchase Crown access | Purchase Crown access | Best Review control → purchase | End cycles control → purchase | End cash control → purchase |',
        '|---|---|---|---|---|---|']
    for pair in a['pairs']:
        left=next(r for r in a['rows'] if r['pair']==pair['pair'] and r['arm']=='control');right=next(r for r in a['rows'] if r['pair']==pair['pair'] and r['arm']=='acquire')
        access=lambda r:'none by Game6' if r['first_qualifying_release'] is None else f'Game{r["first_qualifying_release"]}, cycle{r["first_qualifying_cycle"]}'
        lines.append(f'| {pair["pair"]} | {access(left)} | {access(right)} | {max(left["reviews"]):.1f} → {max(right["reviews"]):.1f} | {left["cycle"]} → {right["cycle"]} | {money(left["cash_cents"])} → {money(right["cash_cents"])} |')
    lines += ['', '**12/12 complete;2,270 commands all accepted; no observed arrears.** Crown access rises2/6→4/6; each policy completes36 releases. Full30-Scope releases rise0/36→10/36. This is a two-seed observation, not an estimated population success rate. Mean Review5.006→5.464 across these releases is descriptive, not a balance approval.',
        '', '### Actual acquisition and exposure','',
        '| Start | Acquisition sequence (after release) | Total purchase payments | Final owned Scope | Actual released Scope by game |','|---|---|---:|---:|---|']
    for r in a['rows']:
        if r['arm']!='acquire':continue
        buys=[p for p in r['purchases'] if p['type']=='admit_research']
        sequence=', '.join(f'{p["quote"]["feature_id"]} (G{p["release_count"]})' for p in buys)
        lines.append(f'| {r["pair"]} | {sequence} | {money(r["costs"]["store_cents"])} | {r["projects"][-1]["supply_scope"]} | '+', '.join(str(d['scope']) for d in r['diagnostics'])+' |')
    lines += ['', 'All13 acquisitions are existing Primitive reserve Features; all26 admission/Research commands use exact eligible observed quotes. Actual discounts are0%. Each new Feature is drawn and played in at least one subsequent project. Later Store upgrades and their familiarity discounts are not tested. Acquired inventory does not guarantee every Feature appears or gets played in each game; for example, Secrets is played only in Games2/4/6 for Action4522.',
        '', 'All six candidates eventually own potential Scope30. Nevertheless Simulation4522 ends Game6 at Scope28: existing `4_color_palette` (Design) and `sound_effects` (Alpha), each Scope1, remain visible at those exits. The new Music, General Combat and Maps all were played. This is a policy utilization gap, not proof that another purchase is necessary or that a new gameplay rule is broken. A visible Feature alone does not certify another full legal affordable hand or a better final Review. [72-check finite-supply/played-Scope audit]('+ref+'supply-diagnostic.json).',
        '', '### Quality and pace limits','',
        '- Puzzle4521 reaches full Scope on Games4/5 but never Review7. Game4 Cores21/9/36/51 against20/13/40/59 yield production6.505, one remaining Bug and final6.8. Sound is the weakest normalized Core. Existing unowned Music is a candidate for a separate legal purchase experiment; this finding does not approve or simulate that alternate route.',
        '- Simulation4522 has multiple misses: initial limited supply, later unplayed existing Features and residual Bugs. Its Game6 production6.749/Scope28/5Bugs yields final5.7. Even the diagnostic removal of all Bugs gives6.3 at actual Scope; QA alone is not demonstrated as the solution.',
        '- Action4521 and Simulation4521 first qualify only with favorable Review variance: both are6.9 in the zero-variance diagnostic. Action4522’s qualifying purchase release is7.2 without variance; Puzzle4522’s is7.0. These are post-run arithmetic diagnostics, never alternate gates or hidden information supplied to policy.',
        '- Action4522 is an important adverse result: purchase delays first access from Game3/cycle39 to Game4/cycle54, while ending cash falls$2,896.22. No automatic purchase recommendation follows from the cohort’s additional unlocks.',
        '', '### Matched calendar accounting','',
        'Endpoint cash above covers different calendars. Each paired report separately retains every shared calendar boundary and first release milestone. At the last shared observed cycle, purchase minus control is:',
        '', '| Pair | Shared cycle | Cash delta | Release-count delta |','|---|---:|---:|---:|']
    for pair in a['pairs']:
        last=pair['calendar'][-1];d=last['delta_right_minus_left'];lines.append(f'| {pair["pair"]} | {last["run_cycle"]} | {money(d["cash_cents"])} | {d["release_count"]} |')
    lines += ['', 'These are last observed command boundaries at the same calendar cycle, not necessarily the same phase or title age; no interpolation or assumed equal sales exposure. Research changes calendar, sales receipts, deck/RNG paths, later cash decisions and release timing. All of that belongs to the measured policy effect. No pure card-stat causal effect or universal payback is inferred.',
        '', '## Verification, failures and exact commands','',
        f'- **PASS:** all12 declared outcomes retained;{a["checks"]:,} explicit study assertions plus the maintained paired source/input/telemetry checks;72 additional finite-supply assertions. Source manifests, input/policy hashes and all six exact initial state/RNG pairs match.',
        f'- **PASS:** acquired Simulation4521 replay, fresh process,193 commands/194 telemetry samples. **PASS:** Studio-only cold continuation restores exact final state and RNG, then completes36 commands to release7/cycle102. Cold mechanics match the experiment. [Verification]({ref}verification.json).',
        f'- **PASS:** protected variant/base integrity and only the named helper project delta. [Manifest]({ref}evidence-manifest.json) retains278 artifact hashes; frozen projects remain available under `{RAW.as_posix()}`.',
        '- **NONE observed:** rejected commands, incomplete cases, timeouts, policy repairs or recovery reruns. Failure reduction is NOT APPLICABLE because no command rejected. Four retained log occurrences warn that6 ObjectDB instances leaked at exit; this study does not claim the warning is fixed.',
        '- **NOT RUN / not established:** GUI/native/export/human/device acceptance, long-run balance, other Traits/employees, alternative reserves, rival/default-AI behavior, support/commission economics, Crown relationship migration/adoption. Every observed release uses `market-0-neutral` with zero recent competitor releases; active-competitor market pressure is not covered.',
        '', 'Variant creation: `python tools/simulator_variant.py create --id crown-acquisition-v1 --owner contracts --output docs/codex/threads/contracts/simulators/crown-acquisition-v1` (the full explicit Python executable is recorded in each run command). Preparation: `setup.py`; execution: `run.py first`, then `run.py remaining`; checks: `analyze.py`, `run_verification.py`, `verify.py`, `supply_diagnostic.py` in the linked study directory. Exact executable/argv/config/output/Godot/timeout records:', '']
    for pair in a['pairs']:lines.append(f'- [{pair["pair"]} command]({ref}{pair["pair"]}-command.json) · [config]({ref}{pair["pair"]}.json) · [paired report]({ref}{pair["pair"]}-comparison.md).')
    lines += [f'- [Replay]({ref}replay-command.json), [prepare cold]({ref}prepare-cold-command.json), [cold]({ref}cold-command.json); driver logs are retained beside these commands and runner reports remain in the raw bundles.',
        '', '## Next decision and queue boundary','',
        'Recommend the narrow CA1b experiment: preserve this acquisition policy and test at most one extra legal affordable Feature-bearing hand per Design/Alpha when completion is still short. Keep QA, redraws, gate and rewards fixed so extra Bugs/rent are measured honestly. Then separately compare Core-targeted purchases if needed. Both are **proposed DESIGN investigations**, not approved canonical rules. Do not make shopping mandatory for the already faster Action witness.',
        '', 'Crown relationships still need separate term/activation authority and a supported predecessor migration. The study needs no new user ruling to conclude; those remain genuine blockers to canonical Crown relationship adoption. SideStreet P2/P3/P4 remain accepted at their existing trial scope. No canonical gameplay, shared design authority, player save, commit, push or release readiness is claimed.']
    (thread/'CROWN-ACQUISITION-FINDINGS-2026-10-24-v1.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('Wrote final finding from12 audited cases')

if __name__=='__main__':main()
