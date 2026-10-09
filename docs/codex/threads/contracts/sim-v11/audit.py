from pathlib import Path
from collections import Counter
import gzip,json,hashlib,sys
H=Path(__file__).resolve().parent
sys.path.insert(0,str(H.parents[2]/'findings/queue-completion-v1'))
import finance_audit as audit
check=audit.check
m=json.loads((H/'source-manifest.json').read_text());copy=Path(m['analysis_copy'])
for name,digest in m['files'].items():check(hashlib.sha256((copy/name).read_bytes()).hexdigest()==digest,'pinned source '+name)
foundation=json.loads((H/'foundation-1104.json').read_text());chain=foundation['starwave_chain']
check(foundation['valid'] and not foundation['errors'] and not foundation['has_active'],'legal profile foundation')
check(chain['completed_contracts']==3 and 'starwave' in chain['unlocked'] and not chain['pending_offers'],'three Contracts/profile-only')
check(len(chain['after_neon']['sales'])==3 and list(chain['pending_promotion'].values())==[18],'three actual releases/Neon award')
cards=json.loads((H/'cards.json').read_text());check(cards['valid'] and cards['checks']==354 and not cards['failures'],'native parity gate')
defs={c['id']:c for c in json.loads((copy/'data/card_ledger.json').read_text())}
core_names=['graphics','sound','technology','design']
for arm in cards['results']:
 check(arm['pool']==foundation['frozen_eligible'] and not arm['blocked'],'frozen legal pool/feasibility')
 scope=0;cores=[0]*4;exhausted=[];prior=None
 for hand in arm['trace']:
  check(len(hand['draw'])==7 and len(hand['selected'])==4 and len(hand['retained'])==3,'7/4/3 hands')
  check(Counter(hand['draw'])==Counter(hand['selected'])+Counter(hand['retained']),'exact multiset retention')
  if prior is not None:check(hand['draw'][:3]==prior,'carry retained slots')
  picked=[defs[id] for id in hand['selected']];mult=3 if len({c['primary_stat'] for c in picked})==1 else 2
  for c in picked:
   if not c['renewable']:
    check(c['id'] in arm['pool'] and c['id'] not in exhausted,'finite owned Feature once');exhausted.append(c['id'])
   scope+=c['scope'];cores[core_names.index(c['primary_stat'])]+=mult*c['primary_value']
   if c['secondary_stat']:cores[core_names.index(c['secondary_stat'])]+=mult*c['secondary_value']
  check(scope==hand['scope'] and cores==hand['cores'],'independent half-unit scores')
  check(exhausted==hand['exhausted'] and hand['redraws']==0,'exhaustion/no redraw')
  prior=hand['retained']
 check(scope==arm['scope'] and cores==arm['cores'],'total scores')
 for target in [12,14,16]:
  expected=4*min(scope,target)+sum(min(c,target) for c in cores)
  check(arm['completions'][str(target)]==dict(numerator=expected,denominator=8*target),'completion arithmetic')
matrix=json.loads((H/'reward-matrix.json').read_text());check(len(matrix)==60,'predeclared matrix')
for x in matrix:
 check(x['cash_cents']==x['cap']*x['numerator']//x['denominator'],'earned exact-cent cash')
 check(x['promotion']==x['promotion_cap']*x['numerator']//x['denominator'],'whole Promotion floor')
arms={name:json.loads(gzip.decompress((H/(name+'.json.gz')).read_bytes())) for name in {'pending','delay_only',*(x['arm'] for x in matrix)}}
pending=arms['pending'];endpoints=['matched_L','cycle_plus_2','cycle_plus_4'];results=[]
def sig(a,g):return [(x.get('phase'),x.get('draw'),x.get('selected')) for x in a['actions'] if x.get('game')==g]
for name,a in arms.items():
 check(a['success'] and a['ledger_valid'] and not a['errors'] and not a['blockers'],'economic arm '+name)
 check(a['before']==pending['before'],'identical legal foundation')
 check(not a['sidestreet_eligible_at_foundation'] and not a['sidestreet_ids'],'SideStreet unavailable, not replaced')
 spec=a['spec'];check(len(a['placeholders'])==spec['cycles'],'three modeled productive cycles')
 for i,p in enumerate(a['placeholders']):
  check(p['analysis_only'] and p['success'] and p['after']['cycle']==p['before']['cycle']+1,'placeholder cycle')
  check(p['receipt_cents']==(spec['cash_cents'] if i==2 else 0),'third-hand-only receipt')
 check(sig(a,4)==sig(pending,4),'same Game4 actions')
 check(a['game4_launch']['cycle']==(72 if name=='pending' else 75),'native launch timing')
 check(a['game4_promotion']==18+spec['extra_promotion'],'Neon/Starwave stack')
 check(a['game4_launch']['awareness']==132+spec['extra_promotion'],'frozen launch Awareness')
 for i,ep in enumerate(endpoints):
  x=a[ep];base=pending[ep];check(x['cycle']==75+2*i,'matched calendar')
  audit.ledger(x['finance_snapshot'])
  check(x['cash_cents']==x['finance_snapshot']['cash_cents'],'endpoint cash')
  check(x['portfolio_settled_cents']==sum(s['settled_cents'] for s in x['sales'].values()),'all-title settled sales')
  check(not x['finance']['financially_blocked'] and x['finance']['total_overdue_cents']==0,'no arrears/block')
  # Same-calendar expense totals and ordinary direct actions cancel; audit
  # every residual against settlement plus all direct action differences.
  direct=lambda e:sum(t['direct_delta'] for t in e['finance_snapshot']['actions'])
  check(x['cash_cents']-base['cash_cents']==x['portfolio_settled_cents']-base['portfolio_settled_cents']+direct(x)-direct(base),'cash delta decomposition')
  receipt=sum(t['direct_delta'] for t in x['finance_snapshot']['actions'] if t['source_id']=='analysis_starwave_timing_v10')
  check(receipt==spec['cash_cents'],'once-only completion cash')
 check(not a['cycle_plus_4']['pending_promotion_awards'],'Promotion consumed once')
 results.append(dict(arm=name,cap_receipt=spec['cash_cents'],promotion=spec['extra_promotion'],launch=a['game4_launch']['cycle'],review=a['game4_launch']['final_review'],cash=a['cycle_plus_4']['cash_cents'],delta_pending=a['cycle_plus_4']['cash_cents']-pending['cycle_plus_4']['cash_cents'],settled=a['cycle_plus_4']['portfolio_settled_cents'],progress=a['cycle_plus_4']['state']['project_cycle']))
out=dict(checks=audit.checks,arms=sorted(results,key=lambda x:x['arm']),cards=12,candidates=60,head=m['head'],script_hashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in H.glob('*.gd')})
(H/'audit-summary.json').write_text(json.dumps(out,indent=2));print('PASS',audit.checks,'independent checks;',len(arms),'economic arms')
