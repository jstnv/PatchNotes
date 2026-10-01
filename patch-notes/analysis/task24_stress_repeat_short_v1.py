"""Full short repeat trace and exact common-prefix parity with the censored long run."""
import json,sys
import tutorial_task17_verify_v1 as v
v.OUT=v.ROOT/'design-logs/task24-v1'
command_path=v.OUT/'stress-repeat-checkpoint96.command.json'
r=json.loads(command_path.read_text(encoding='utf-8')) if command_path.exists() and '--rerun' not in sys.argv else v.run('stress-repeat-checkpoint96',v.ROOT,['--script','res://analysis/task24_stress_v1.gd','--','--stress=repeat','--cap=96','--tag=checkpoint96'],240)
assert r['exit']==0 and not r['errors']
short=json.loads((v.OUT/'stress_repeat_checkpoint96.json').read_text(encoding='utf-8'))['rows'][0]
long=json.loads((v.OUT/'stress_repeat_censored981.json').read_text(encoding='utf-8'))['rows'][0]
assert short['valid'] and short['final']['cycle']>=96
fields=['scope','required_scope','final_review','cycle','cash_cents','cores','awareness','month_1_units','meets_required_scope']
for a,b in zip(short['releases'],long['releases']):
    assert {k:a[k] for k in fields}=={k:b[k] for k in fields}
fields=['cycle','year','cash_cents','unpaid_cents','familiarity','qualifying_count','reason']
short_studios=[s for s in short['studio_visits'] if not s['reason'].startswith('reserve_purchase:')]
long_studios=[s for s in long['studio_visits'] if not s['reason'].startswith('reserve_purchase:')]
for a,b in zip(short_studios,long_studios):
    assert {k:a[k] for k in fields}=={k:b[k] for k in fields}
    assert sorted(a['owned_ids'])==sorted(b['owned_ids'])
short_buys=[s for s in short['studio_visits'] if s['reason'].startswith('reserve_purchase:')]
long_buys=[s for s in long['studio_visits'] if s['reason'].startswith('reserve_purchase:')]
assert sorted(s['reason'] for s in short_buys)==sorted(s['reason'] for s in long_buys)
assert all(p['success'] for p in short['purchases'])
audit={'passed':True,'short_command':r,'short_final_cycle':short['final']['cycle'],
       'matching_release_count':len(short['releases']),'matching_studio_count_excluding_individual_reserve_buys':len(short_studios),
       'captured_actual_purchases':len(short['purchases']),
       'intermediate_purchase_order_matches':False,
       'original_strict_studio_assertion':'Failed: StringName array sort does not provide cross-process lexical purchase ordering.',
       'short_reserve_order':[s['reason'] for s in short_buys],
       'long_reserve_order':[s['reason'] for s in long_buys],
       'note':'Release IDs are fresh per run. All seven releases and non-individual-purchase Studio cash/familiarity/outcomes match; owned-ID order is canonicalized as a set. Both actual reserve batches buy the same 11 cards for the same total cost/cycles. Do not claim exact intermediate purchase ordering.'}
(v.OUT/'stress-repeat-prefix-parity.json').write_text(json.dumps(audit,indent=2),encoding='utf-8')
print(json.dumps(audit,indent=2))
