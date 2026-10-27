from run_checks import *
import hashlib
baseline=sim.read_json(BASE/'baseline-source.json')
current=sim.source_hashes(ROOT/'patch-notes')
delta=[{'path':p,'before':baseline.get(p),'after':current.get(p)} for p in sorted(set(baseline)|set(current)) if baseline.get(p)!=current.get(p)]
sim.write_json(BASE/'final-source.json',current)
sim.write_json(BASE/'source-delta.json',delta)
rows=[]
packet=ROOT/'docs/codex/threads/feature-pools/handoffs/first-authored-alpha-shop-pack-v1/HANDOFF.md'
for name,pin in re.findall(r'`([^`]+\.(?:gd|json))` `([0-9a-f]+)`',packet.read_text(encoding='utf-8')):
 matches=[(p,h) for p,h in baseline.items() if Path(p).name==name]
 rows.append({'file':name,'handoff_pin':pin,'pin_length':len(pin),'baseline_matches':matches,'exact':len(matches)==1 and matches[0][1]==pin})
table=ROOT/'patch-notes/design-logs/feature-store-staged-v1/stage1_catalog_v1.json'
catalog=sim.read_json(table)
entries=catalog if isinstance(catalog,list) else next(v for v in catalog.values() if isinstance(v,list) and v and isinstance(v[0],dict) and 'id' in v[0])
original={r['id']:r for r in entries}
selected=sim.read_json(BASE/'alpha-pack-content.json')['added']
for row in selected:
 authored=original[row['id']]
 for key in ['name','phase','department','scope']:assert row[key]==authored[key],(row['id'],key)
 ordered=[{'stat':row['primary_stat'],'value':row['primary_value']}]
 if row['secondary_stat']:ordered.append({'stat':row['secondary_stat'],'value':row['secondary_value']})
 assert ordered==authored['ordered_core']
sim.write_json(BASE/'handoff-pin-audit.json',{'alpha_handoff_pins':rows,'authored_catalog_sha256':sim.sha(table),'exact_printed_rows_verified':[r['id'] for r in selected],'note':'Malformed abbreviated handoff hashes are retained as evidence, not treated as verified SHA-256 pins. Intake snapshot and exact candidate before-hashes are authoritative reconciliation evidence.'})
print(json.dumps({'changed_project_files':len(delta),'malformed_or_different_pins':[r['file'] for r in rows if not r['exact']],'authored_rows':len(selected)}))
