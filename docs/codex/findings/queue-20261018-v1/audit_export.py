from pathlib import Path
import json,hashlib
OUT=Path(__file__).resolve().parent
checks=0
rows=[]
def check(v,msg):
 global checks
 checks+=1
 if not v:raise AssertionError(msg)
def kv(rows):return {x['key']:x['value'] for x in rows}
def payload(f):
 e=json.loads(f.read_text());check(hashlib.sha256(e['payload_utf8'].encode()).hexdigest()==e['payload_sha256'],'envelope integrity');return json.loads(e['payload_utf8'])
for name,publishers in [('starwave-1152',['starwave']),('neon_circuit-1152',['neon_circuit','crown_quill']),('sidestreet-1280',['sidestreet'])]:
 stage=OUT/'export-ui-v1'/name;s=stage/'profile/APPDATA/Godot/app_userdata/Patch Notes Demo/saves/studio'
 files=sorted(s.glob('checkpoint.*.json'),key=lambda f:int(f.stem.split('.')[1]));d=payload(files[-1]);r=d['run'];finance=r['studio_finance'];cash=0
 check(int(finance['transactions'][0]['amount_cents'])==int(finance['initial_cash_cents']),'initial funding')
 for t in finance['transactions']:
  check(int(t['cash_before_cents'])==cash,'journal continuity');cash+=int(t['cash_delta_cents']);check(int(t['cash_after_cents'])==cash,'journal delta')
 check(cash==int(r['cash_cents'])==int(finance['cash_cents']),'cash reconciliation')
 states={x['value']['publisher_id']:x['value']['state'] for x in r['publisher_offers']}
 for pub in publishers:
  state=next(x['value']['state'] for x in r['sidestreet_entitlements'] if x['value']['state'] is not None) if pub=='sidestreet' else states[pub]
  result=state['result'];grade=int(result['challenge_grade_bp']);bonus=int(result['bonus_cash_cents']);promotion=int(result['bonus_promotion']);check(bonus==10000*grade//10000 and promotion==4*grade//10000,'independent bonus flooring')
  check(state['paid'] and int(state['hands'])==(3 if pub=='starwave' else 2),'final hand completed once')
  receipt=[t for t in finance['transactions'] if t['source_id']==state['offer_id'] and t['kind'] in ['publisher_receipt','contract_payout','contract_receipt']]
  # Acceptance and completion may share a receipt kind; exact sums and completion amount remain explicit.
  check(sum(int(t['cash_delta_cents']) for t in receipt)==int(result['payout']),'direct receipt sum')
  rows.append({'profile':name,'publisher':pub,'generation':files[-1].name,'cycle':r['completed_run_cycles'],'cash_cents':r['cash_cents'],'result':result,'receipts':receipt})
for stage in (OUT/'export-ui-v1').iterdir():
 for f in stage.glob('*.engine.log'):
  errors=[l for l in f.read_text(errors='replace').splitlines() if 'SCRIPT ERROR' in l or l.startswith('ERROR:')]
  check(not errors,str(f)+str(errors))
report={'pass':True,'checks':checks,'rows':rows};(OUT/'export-ui-audit.json').write_text(json.dumps(report,indent=2));print('EXPORTED RECEIPT AUDIT',checks,'PASS')
