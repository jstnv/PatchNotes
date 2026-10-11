from pathlib import Path
import hashlib,json,re
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf8'))
record=read(HERE/'full-v2.command.json')
assert record['exit']==0 and not record['errors'] and record['source_unchanged']
assert sha(HERE/'full-v2.log')==record['log_sha256']
assert sha(HERE/'full-v2.traces.json')==record['trace_sha256']
old=(HERE/'verify_card_motion.before.gd').read_text(encoding='utf8')
new=(ROOT/'patch-notes/scripts/debug/verify_card_motion.gd').read_text(encoding='utf8')
assert old.split('func _store(')[0]==new.split('func _store(')[0]
assert old.split('func _paid_hand(')[1]==new.split('func _paid_hand(')[1]
original_pin=read(HERE.parent/'education-implementation-v1/source-edges-v3.json')
changed=[row['path'] for row in original_pin['records'] if sha(ROOT/row['path'])!=row['sha256']]
assert changed==['patch-notes/scripts/debug/verify_card_motion.gd'],changed
traces=read(HERE/'full-v2.traces.json')
stores=[r for r in traces if r['phase']=='Store']
assert [r['width'] for r in stores]==[1152,900]
for row in stores:
 assert all(a<b for a,b in zip(row['camera_zoom'],row['camera_zoom'][1:]))
 assert all(a<b for a,b in zip(row['menu_x'],row['menu_x'][1:]))
 assert abs(row['menu_alpha_at_010']-.75)<1e-6
production=[r for r in traces if r['phase']=='Design']
timing=[]
for row in production:
 rise=[e['msec'] for e in row['order'] if e['event']=='rise']
 intervals=[(b-a)/1000 for a,b in zip(rise,rise[1:])]
 assert all(abs(gap-60/140)<.10 for gap in intervals)
 bonus=[e['msec'] for e in row['order'] if e['event']=='bonus_rise']
 end=[e['msec'] for e in row['order'] if e['event']=='specialization_complete']
 assert len(bonus)==4 and len(end)==1 and abs((end[0]-bonus[0])/1000-4*60/140)<.15
 timing.append({'width':row['width'],'real_card_beat_intervals_seconds':intervals,'real_specialization_cycle_seconds':(end[0]-bonus[0])/1000})
result={'passed':True,'full_suite_assertions':len(re.findall(r'^PASS:',(HERE/'full-v2.log').read_text(encoding='utf8'),re.M)),'duration_seconds':record['elapsed_seconds'],'only_source_drift_since_education_pin':changed,'runtime_and_data_unchanged':True,'card_and_contract_sections_unchanged':True,'stores':stores,'real_motion':timing,'source_sha256':sha(ROOT/'patch-notes/scripts/debug/verify_card_motion.gd'),'auditor_sha256':sha(Path(__file__))}
(HERE/'audit.json').write_text(json.dumps(result,indent=2),encoding='utf8')
print(json.dumps(result,indent=2))
