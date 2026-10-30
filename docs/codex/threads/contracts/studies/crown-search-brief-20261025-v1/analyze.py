from run import *
from collections import Counter
rows=[];pairs={};events={};manifest={}
for line in (RAW/'branches/experiment.log').read_text(encoding='utf-8').splitlines():
 if line.startswith('PN_CB_RESULT '):
  x=json.loads(line.split(' ',1)[1]);events.setdefault(x['case'],[]).append(x)
for c in load(HERE/'branches.json')['cases']:
 folder=RAW/'branches/cases'/c['case_id'];r=load(folder/'result.json');tel=load(folder/'telemetry.json');ss=tel['samples']
 initial=[r['source_identity'],r['initial_state'],r['initial_rng']];pair=c['study']['pair_id']
 if pair in pairs:assert pairs[pair]==initial
 else:pairs[pair]=initial
 prefix=load(RAW/'prefix/cases'/pair/'result.json')
 assert r['initial_state']==prefix['final_state'] and r['initial_rng']==prefix['final_rng']
 assert len(ss)==r['commands']+1
 lows=[int(s['cash_cents']) for s in ss]+[int(s['transaction_cash_low_cents']) for s in ss if s.get('transaction_cash_low_cents') is not None]
 ev=events.get(c['case_id'],[])
 searches=[s for s in ss if s['command_type']=='search_contracts' and s['accepted']]
 brief_commands=[s for s in ss if s['command_type']=='contract' and s['accepted']]
 row=dict(case=c['case_id'],pair=pair,arm=c['study']['arm'],status=r['status'],error=r['error'],accepted=r['accepted_commands'],commands=r['commands'],initial_cycle=ss[0]['run_cycle'],final_cycle=ss[-1]['run_cycle'],initial_cash_cents=int(ss[0]['cash_cents']),final_cash_cents=int(ss[-1]['cash_cents']),min_cash_cents=min(lows),max_overdue_cents=max(int(s['overdue_cents']) for s in ss if s['overdue_cents'] is not None),releases=r['final_release_count'],reviews=[x['review'] for x in ss[-1]['releases']],searches=len(searches),briefs=ev,reputation_bp=sum(e['award'] for e in ev))
 if row['arm']=='mean' and row['status']=='completed':
  assert len(ev)==3 and len(searches)==3
  assert all(ev[i]['cycle']==searches[i]['run_cycle']+2 for i in range(3))
 rows.append(row)
 for name in ['result.json','telemetry.json','replay.tape.json','case.variant.json','studio_checkpoint.json']:
  p=folder/name
  if p.exists():manifest[str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
write(HERE/'analysis.json',dict(rows=rows,matched_pairs=len(pairs),statuses=dict(Counter(r['status'] for r in rows))));write(HERE/'evidence-manifest.json',manifest)
for row in rows:print(json.dumps({k:v for k,v in row.items() if k!='briefs'}))
for pair in pairs:
 arms={r['arm']:r for r in rows if r['pair']==pair}
 if len(arms)==2:print(pair,'cash delta',arms['mean']['final_cash_cents']-arms['skip']['final_cash_cents'],'cycle delta',arms['mean']['final_cycle']-arms['skip']['final_cycle'])
