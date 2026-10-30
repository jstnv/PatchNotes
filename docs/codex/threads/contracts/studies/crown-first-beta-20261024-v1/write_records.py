from setup import HERE,RAW,write
import json
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
def fresh(path,text):
    with path.open('x',encoding='utf-8') as f:f.write(text)

def main():
    a=load(HERE/'analysis.json');s=load(HERE/'summary.json');audit=load(HERE/'policy-audit.json');v=load(HERE/'verification.json');pins=load(HERE/'source-pins.json');manifest=load(HERE/'evidence-manifest.json');rec=load(HERE/'recommendation.json');continuity=load(HERE/'control-continuity.json')
    assert a['complete'] and s['complete'] and all(r['ok'] and r['commands']==r['accepted_commands'] for r in a['rows'])
    commands=sum(r['commands'] for r in a['rows']);releases=sum(r['releases'] for r in a['rows']);thread=HERE.parents[1]
    rowtable='\n'.join(f"| {r['pair'].split('-')[-1]} / {r['arm']} | {', '.join(f'{q:.1f}' for q in r['reviews'])} | {r['cycle']} | ${r['cash_cents']/100:,.2f} | {r['commands']} | {'yes' if r['unlocked'] else 'no'} |" for r in a['rows'])
    armstable='\n'.join(f"| {arm} | {x['crown_access']}/{x['cases']} | {x['mean_review']:.3f} | {x['mean_bugs']:.3f} | {x['qa_extension_hands']} | {x['beta_redraws']} | {x['no_effect_all_debug_openers']} |" for arm,x in s['arms'].items())
    events=[e for e in audit['reserved_redraws'] if e['case'].startswith('candidate-')]
    eventtable='\n'.join(f"| {e['case'].split('-')[-1]} / G{e['release']} | {e['timing']} | {e['cycle']} | {e['discarded']} → {e['replacement']} | {'hit' if e['search_hit'] else 'miss'} | {e['next_action']} |" for e in events)
    diffs=[];links=[]
    for pair in ['qa-simulation-4522','qa-simulation-4521']:
        candidate=next(r for r in a['rows'] if r['case']=='candidate-'+pair)
        for arm,suffix in [('control','comparison'),('reserved','reserved-comparison')]:
            base=next(r for r in a['rows'] if r['case']==arm+'-'+pair)
            c=load(HERE/(pair+'-'+suffix+'.json'));delta=c['matched_release_milestones'][-1]['delta_right_minus_left'];last=c['matched_calendar'][-1]
            diffs.append(f"| {pair.split('-')[-1]} vs {arm} | {int(delta['run_cycle']):+d} | ${int(delta['cash_cents'])/100:+,.2f} | ${ (candidate['costs']['rent_paid_cents']-base['costs']['rent_paid_cents'])/100:+,.2f} | {last['run_cycle']}: {last['left']['release_count']} vs {last['right']['release_count']} releases; ${int(last['delta_right_minus_left']['cash_cents'])/100:+,.2f} |")
            links.append(f"[{pair.split('-')[-1]} {arm}](studies/crown-first-beta-20261024-v1/{pair}-{suffix}.md)")
    body=f'''# Crown CA1f — first-hand Beta redraw findings v1

2026-10-24. **COMPLETE bounded private experiment; candidate policy OPEN. Rewards unchanged.**

## Result and recommendation

{rec['conclusion']}

{rec['recommendation']}

## Setup, authority and exact scope

User: “Go ahead and cook for the first-hand Beta redraw test. Keep rewards unchanged.” [Pre-run plan](CROWN-FIRST-BETA-PLAN-2026-10-24-v1.md) specifies six legal Simulation cases: seeds4522 then4521, each generic early control, CA1e late-reserved control and new first-hand candidate. Six releases/320commands per case, no Traits/employees/loans or invented starting awards. Each triple has identical full Studio recipes and verified initial state/RNG; equal seeds alone were not relied upon.

The candidate checks before the first productive Beta hand: Search absent, unused one-card policy allowance, runtime redraw available, cash at least four monthly rents. Preserve the unchanged best-scored four cards with Debug required if visible; discard the last index outside that set. If Search is present or this guard is unavailable, retain the allowance for the unchanged late Search-starved exit guard. A miss consumes the allowance. Normal hand scoring/selection remains unchanged, so this experiment does not force a particular post-redraw hand.

Both controls and candidate retain CA1d's optional Design/Alpha extra hand, two QA extension hands maximum, ordinary Scope acquisition and no targeted Core purchase. Total policy limit remains one redrawn card per phase; actual usage can differ. No rewards, gate, card scores, player hand limits, priorities, purchases or reserve changes. Candidate decisions use detached visible candidates/known Bugs; hidden Bugs, future RNG and post-release diagnostics are not inputs. Runtime source delta contains only the existing private legacy helper; [external policy diff](studies/crown-first-beta-20261024-v1/policy.diff) is the treatment.

## Source identities

`main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, shared dirty checkout. Fresh variant `crown-first-beta-v1`, protected baseline/ancestry. [Source pins](studies/crown-first-beta-20261024-v1/source-pins.json) list the two verifier-only differences from CA1e. No old checkpoints were transplanted or identity-edited.

| Identity | SHA-256 |
|---|---|
| Protected canonical baseline | `{pins['variant']['base_identity']}` |
| Helper-added private project | `{pins['candidate_identity']}` |
| Executed mechanics | `{a['identities'][0]['source']}` |
| External policy | `{pins['policy_sha256']}` |
| Pre-run plan | `{pins['plan_sha256']}` |
| Runner | `{pins['runner_sha256']}` |
| Godot | `{pins['godot_sha256']}` |

Both seed bundles have matching mechanics, policy, runner and runtime identities. All four freshly rerun control cases match CA1e in initial/final state, RNG, commands, final cycle and entire outcome: [control continuity](studies/crown-first-beta-20261024-v1/control-continuity.json). This is a checked continuity result, not substitution of old evidence for fresh runs. [Evidence manifest](studies/crown-first-beta-20261024-v1/evidence-manifest.json) also retains any canonical drift after capture.

## All six cases

| Seed / arm | Reviews G1–G6 | Final cycle | Final cash | Commands | Crown unlocked |
|---|---|---:|---:|---:|---|
{rowtable}

**{releases} releases / {commands} accepted commands**, no runtime rejections, incomplete or timed-out cases and no observed arrears. Each route legally acquires Music, General Combat and Maps; quotes/ownership/use remain audited. Publisher reward rules and private-project reward source are unchanged. Detailed actual finance totals, lows and purchases are retained in [analysis](studies/crown-first-beta-20261024-v1/analysis.json).

| Policy | Crown access | Mean Review | Mean Bugs | Extra QA hands | Beta redraws | No-effect all-Debug openers |
|---|---:|---:|---:|---:|---:|---:|
{armstable}

Counts cover12 releases per policy; a no-effect opener means its selected four cards are Debug and the hand discovers/fixes zero Bugs. Full per-game discovery/fixing, first-hand selections, components and final exits are retained in [summary](studies/crown-first-beta-20261024-v1/summary.json). Neither equal ceilings nor a Search hit implies equal downstream card draws or a net improvement.

### Every candidate targeted redraw

| Seed / release | Timing | Cycle | Discard → replacement | Search | Next action |
|---|---|---:|---|---|---|
{eventtable}

All attempts and misses remain in the [policy audit](studies/crown-first-beta-20261024-v1/policy-audit.json). Its inherited `reserved_redraws` array contains targeted events from both reserved and candidate arms; each explicitly labels `timing: first/late`. No second redraw is granted after a first-hand miss.

### Interpretation

{rec['diagnostic']}

### Calendar and cash tradeoffs

All deltas below are candidate minus comparator. Same-release cash and same-calendar cash are distinct; the latter can compare different release counts.

| Seed / comparator | Game6 cycle delta | Game6 cash delta | Rent paid delta | Last common calendar: comparator vs candidate |
|---|---:|---:|---:|---|
{chr(10).join(diffs)}

Full paired reports: {', '.join(links)}. No extrapolation beyond shared observed cycles or claim of a general income-rate improvement.

## Exact execution and validation

Raw evidence root: `{RAW.as_posix()}`. Keep source snapshots, caches/profiles, logs, results and tapes. Exact argv: [create](studies/crown-first-beta-20261024-v1/create-command.json), [4522 triple](studies/crown-first-beta-20261024-v1/qa-simulation-4522-command.json), [4521 triple](studies/crown-first-beta-20261024-v1/qa-simulation-4521-command.json), [replay](studies/crown-first-beta-20261024-v1/replay-command.json), [prepare cold](studies/crown-first-beta-20261024-v1/prepare-cold-command.json), [cold](studies/crown-first-beta-20261024-v1/cold-command.json).

Sequence: create, setup, prepare checks, first triple, first audit, second triple alongside representative verification, final analyze/audit/summarize/control continuity/verify, write records and publish. Each runner uses `--timeout 600` separately for import/execution, new output/cache/profile and no more than two concurrent processes. Policy/plan/seed/budget remain frozen after first execution.

- **PASS:** {s['study_checks']} study assertions and{s['policy_checks']} independent policy assertions; four maintained pair comparisons validate input/source/telemetry/state/RNG. Guards include both trigger timing and absence of unjustified triggers, exact discard/tie rule, one redraw consumption, no redraw cash/time/score grant, Debug retention, same phase/QA/purchase ceilings and legal quotes/cards.
- **PASS:** representative candidate4522 fresh-process replay: {v['replays'][0]['commands']} commands/{v['replays'][0]['samples']} exact telemetry samples.
- **PASS:** Studio-only cold Continue preserves exact initial state/RNG from the original final state, then{v['cold']['commands']} commands to total release7/cycle{v['cold']['cycle']}, within80-command bound. Verification is excluded from the six-case comparison; no arbitrary active-phase policy-state persistence claim.
- **PASS:** protected baseline/ancestry, unchanged plan/policy hashes, helper-only project delta; {len(manifest['files'])} raw evidence hashes. [Verification](studies/crown-first-beta-20261024-v1/verification.json).
- **RETAINED diagnostics:** {json.dumps(manifest['warnings'])}. No warning fix claimed. No gameplay rejection needed failure reduction. A progress display initially mistook the runner's initial `ok:false` placeholder for final status; it now waits for the driver completion receipt. An early inspection of the still-unwritten driver log failed harmlessly. A premature verifier invocation rejected still-partial analysis; after the pipeline finished, the unchanged verifier passed. [Tooling check record](studies/crown-first-beta-20261024-v1/tooling-checks.json). No simulation retry, policy, input or assertion change resulted.

## Limits and next work

This is two Simulation seeds and one six-release purchasing/priority/scoring route. All{releases} releases are neutral-market/zero-recent-competitor observations, so active-rival pressure and relationship producers were not covered. Review variance and downstream RNG/card-path changes remain visible; post-run component diagnostics are not additional interventions. No graphical/native/export/human/device acceptance or broad balance claim.

{rec['next']}

No execution blocker remains. Candidate simulation evidence does not approve gameplay, default AI, Crown terms or balance. SideStreet P2/P3/P4 approved ACTIVE/TRIAL scope remains unchanged; Crown relationship terms/activation/migration OPEN, CP2 rewards held. Canonical gameplay, player saves, `.codex-godot-temp`, commits and pushes were untouched by this work. [Versioned handoff](CROWN-FIRST-BETA-HANDOFF-2026-10-24-v1.md).
'''
    assert continuity['complete'] and continuity['same_mechanics'] and all(all(r['fields_equal'].values()) for r in continuity['rows'])
    fresh(thread/'CROWN-FIRST-BETA-FINDINGS-2026-10-24-v1.md',body)
    handoff=f'''# Crown CA1f — first-hand Beta redraw handoff v1

2026-10-24. **DESIGN review; no canonical implementation queued.** User approved the bounded test with unchanged rewards; policy remains OPEN. [Plan](CROWN-FIRST-BETA-PLAN-2026-10-24-v1.md), [findings](CROWN-FIRST-BETA-FINDINGS-2026-10-24-v1.md), [source pins](studies/crown-first-beta-20261024-v1/source-pins.json), [exact policy delta](studies/crown-first-beta-20261024-v1/policy.diff), [audit](studies/crown-first-beta-20261024-v1/policy-audit.json), [verification](studies/crown-first-beta-20261024-v1/verification.json), [manifest](studies/crown-first-beta-20261024-v1/evidence-manifest.json).

## Matching source and exact change

Fresh `crown-first-beta-v1`, baseline `{pins['variant']['base_identity']}`, helper-added project `{pins['candidate_identity']}`, policy `{pins['policy_sha256']}`. HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty `main`; reconcile future canonical drift before any adoption. Only private project addition is existing legacy helper; do not transplant it into production as gameplay.

Candidate adds `first_search_redraw` ahead of ordinary Beta play: first productive hand pending, no visible Search, unused one-card allowance/runtime availability and four-rent reserve. Keep unchanged scored four with a Debug if visible, discard last unkept index; otherwise preserve the CA1e late guard. Shared allowance, two QA extension hands, purchases, scoring, gates and rewards remain unchanged. Both original policies are rerun unchanged through flags in the same external policy.

## Tasks and disposition

| Item | Status | Action / acceptance | Dependencies |
|---|---|---|---|
| CA1f experiment | **implemented and verified — private policy/evidence only** | Retain all six cases/{releases} releases/{commands} accepted commands, both controls, every redraw miss, source/guard audits, exact replay/Studio Continue and shutdown warnings. | Source/plan/policy/evidence hashes match; no canonical implementation claim. |
| Policy disposition | **proposed** | {rec['recommendation']} | Complete findings; future gameplay/default-AI adoption requires a separate design ruling. |
| Next Contracts design work | **proposed** | {rec['next_acceptance']} | Preserve existing Crown access witnesses and CA1c/CA1e tradeoffs. Distinguish proposed terms from approved rules; fresh source and explicit migration authority before implementation. |

{rec['next']}

Shared TODO receives one minimal Crown DESIGN update preserving prior evidence links. SideStreet ACTIVE/TRIAL authority unchanged; Crown activation/terms/migration remain OPEN, CP2 rewards held. No auto-merge, chat dispatch, commit/push or release-readiness inference.
'''
    fresh(thread/'CROWN-FIRST-BETA-HANDOFF-2026-10-24-v1.md',handoff)
    write(HERE/'record-facts.json',{'cases':len(a['rows']),'commands':commands,'releases':releases,'study_checks':s['study_checks'],'policy_checks':s['policy_checks'],'evidence_hashes':len(manifest['files'])})
    print(json.dumps({'written':['findings','handoff'],'commands':commands,'releases':releases}))
if __name__=='__main__':main()
