"""Exact fixed-share trial; reuse immutable historical hands and native current routes."""
from fractions import Fraction as F
from pathlib import Path
import ast,json,random,itertools,statistics,hashlib
import remaining_publisher_contracts_rebaseline_v1 as rules
from task22_prepare_v1 import events
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'design-logs/task23-v1';C=rules.CORES;L=rules.LEDGER
def fixed(name,scope,half,focus,required,core_increase=0):
 if name=='crown':
  capped=[8*min(F(half[c],8+core_increase),1) for c in C]
  return min(F(1),max(F(0),(18*min(F(scope,required),1)+sum(capped)+2*min(capped))/66))
 return min(F(1),max(F(0),(20*min(F(scope,required),1)+54*min(F(half[focus],18+core_increase),1)+sum(4*min(F(half[c],4+core_increase),1) for c in C if c!=focus))/86))
def old(name,scope,half,focus,required):
 if name=='crown':
  capped=[min(half[c],8) for c in C];return F(2*min(scope,required)+sum(capped)+2*min(capped),2*required+48)
 return F(2*min(scope,required)+3*min(half[focus],18)+sum(min(half[c],4) for c in C if c!=focus),2*required+66)
def award(name,f):
 cash,promo=rules.CAPS[name];return [cash*f.numerator//f.denominator,promo*f.numerator//f.denominator]
def summarize(rows):
 out={}
 for key in sorted({(r['name'],r['policy'],r['timing'],r['target'],r.get('first_eligible_game','all')) for r in rows}):
  group=[r for r in rows if (r['name'],r['policy'],r['timing'],r['target'],r.get('first_eligible_game','all'))==key]
  def pct(field,p):return sorted(r[field] for r in group)[int((len(group)-1)*p)]
  out[str(key)]=dict(count=len(group),full=sum(r['full'] for r in group),cash_p10=pct('cash',.1),cash_median=statistics.median(r['cash'] for r in group),promo_p10=pct('promotion',.1),promo_median=statistics.median(r['promotion'] for r in group))
 return out
def simulator():
 # Load only the existing policy functions, not its old top-level capture analysis.
 src=(ROOT/'analysis/task20_compare_v1.py').read_text(encoding='utf-8');tree=ast.parse(src)
 subset=ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in ['score','simulate']],type_ignores=[])
 ns=dict(random=random,itertools=itertools,rules=rules,L=L,C=C);exec(compile(subset,'task20_compare_v1 policy reuse','exec'),ns)
 return ns['simulate']
def main():
 historical=json.loads((ROOT/'design-logs/task20-v1/contract_traces.json').read_text(encoding='utf-8'))
 eligibility=json.loads((ROOT/'design-logs/task20-v1/eligibility.json').read_text(encoding='utf-8'))
 hist=[];counter=[];ties=0
 for i,t in enumerate(historical):
  name=t['name'];low=9 if name=='crown' else 10
  a=fixed(name,t['scope'],t['half'],t['focus'],low);b=fixed(name,t['scope'],t['half'],t['focus'],low+1)
  assert b<=a and all(y<=x for x,y in zip(award(name,a),award(name,b)))
  assert fixed(name,t['scope'],t['half'],t['focus'],low,2)<=a
  ties+=a==b
  oa=old(name,t['scope'],t['half'],t['focus'],low);ob=old(name,t['scope'],t['half'],t['focus'],low+1)
  if ob>oa:counter.append(dict(trace=i,name=name,scope=t['scope'],half=t['half'],old=[award(name,oa),award(name,ob)],fixed=[award(name,a),award(name,b)]))
  for target,f in [(low,a),(low+1,b)]:
   first=next(e['first_game'] for e in eligibility if e['name']==name and e['route']==t['route'])
   cash,promo=award(name,f);hist.append(dict(trace=i,name=name,policy=t['policy'],timing=t['timing'],target=target,first_eligible_game=first,cash=cash,promotion=promo,full=f==1,numerator=f.numerator,denominator=f.denominator))
 for name in ['crown','neon']:
  target=9 if name=='crown' else 10;assert award(name,fixed(name,100,{c:100 for c in C},'graphics',target))==list(rules.CAPS[name])
  assert fixed(name,0,{c:0 for c in C},'graphics',target)==0
 (OUT/'historical-rescore.json').write_text(json.dumps(dict(source_sha256=hashlib.sha256((ROOT/'design-logs/task20-v1/contract_traces.json').read_bytes()).hexdigest(),traces=len(historical),ties=ties,old_increases=len(counter),counterexamples=counter,summary=summarize(hist),rows=hist),indent=2),encoding='utf-8')
 simulate=simulator();newtraces=[];routes=[];inputs=[]
 for name in ['crown','neon']:
  r=json.loads((OUT/f'route_{name}.json').read_text(encoding='utf-8'))
  assert r['valid'] and not r['discrepancies'] and len(r['releases'])==5
  # Event accounting includes one committed Neon marketing-priority change.
  for a in r['actions']:
   if a['phase']=='neon_marketing_priorities':a['phase']='beta priorities'
  ev=events(r);rels=r['releases'];first=next(i for i,x in enumerate(rels) if x['final_review']>=7) if name=='crown' else next(i for i,x in enumerate(rels) if x['awareness']>=125)
  frozen={x['ledger']['release_id']:x['ledger'] for x in r['captures'][0]['titles']}
  assert all(not x['campaign_months'] for x in frozen.values()),'Timing cohort excludes campaigns to preserve eligibility after inserted cycles'
  release_visits=[s for s in r['studio_visits'] if s['reason']=='committed release']
  horizon=int(rels[4]['cycle'])+3+24
  for timing,index in [('early',first),('after_game4',3)]:
   owned=set(release_visits[index]['owned_ids'])&rules.PRIMITIVE
   focus=max(C,key=lambda c:sum(L[id]['primary_value'] for id in owned if L[id]['primary_stat']==c))
   for policy in ['ordinary','synergy']:
    for seed in range(200929000,200929020):
     trace=simulate(owned,name,focus,seed,policy);f=fixed(name,trace['scope'],trace['half'],focus,9 if name=='crown' else 10)
     cash,promo=award(name,f);trace.update(name=name,timing=timing,focus=focus,trigger_index=index,payout=cash,promotion=promo,full=f==1)
     newtraces.append(trace)
  # Native neutral, delay-only and every whole Promotion0..cap ledger, deduped.
  for timing,index in [('neutral',-1),('early',first),('after_game4',3)]:
   for i,rel in enumerate(rels):
    launch=int(rel['cycle'])+(3 if index>=0 and i>index else 0)
    for promo in range(rules.CAPS[name][1]+1 if i==index+1 and index>=0 else 1):
     aw=int(rel['awareness'])+promo;f=frozen[rel['release_id']]
     inputs.append(dict(id=f'{name}:{timing}:{i}:{promo}',release_id=rel['release_id'],release_cycle=launch,awareness=aw,frozen=f,horizon=horizon))
  routes.append(dict(name=name,route=r,events=ev,first=first,horizon=horizon))
 (OUT/'contract_traces.json').write_text(json.dumps(newtraces),encoding='utf-8');(OUT/'prepared.json').write_text(json.dumps(routes),encoding='utf-8');(OUT/'inputs.json').write_text(json.dumps(inputs),encoding='utf-8')
 print('Historical',len(historical),'old increases',len(counter),'ties',ties,'current',len(newtraces),'ledgers',len(inputs))
if __name__=='__main__':main()
