"""Normalize supplied proposal for Task 24; never alter the runtime catalog.

Run: python -B analysis/task24_catalog_v1.py
"""
from pathlib import Path
import collections
import hashlib
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'design-logs/task24-v1'
DRAFT = Path('C:/Users/64jus/Downloads/Patch_Notes_Multi_Era_Feature_Store_Design_v1.md')
STAT = {'G':'graphics','S':'sound','T':'technology','D':'design'}
BANDS = {'A':[65000,95000,125000], 'B':[140000,170000,200000],
         'B+':[160000,190000,220000], 'C1':[180000,240000,300000],
         'C2':[220000,280000,340000]}
LATER = [1984,1990,2000,2010,2020]

def ident(s):
    return re.sub('[^a-z0-9]+','_',s.lower().replace('&','and')).strip('_')

def ordered(s):
    return [{'stat':STAT[a],'value':int(b)} for a,b in re.findall(r'([GSTD])(\d+)',s)]

def build():
    txt = DRAFT.read_text(encoding='utf-8')
    lanes = (ROOT/'scripts/ui/feature_store.gd').read_text(encoding='utf-8')
    lane_of = {id_:lane for lane,ids in re.findall(r'&"([^"]+)": \[([^\]]+)\]',lanes)
               for id_ in re.findall(r'&"([^"]+)"',ids)}
    primitive = [c for c in json.loads((ROOT/'data/card_ledger.json').read_text(encoding='utf-8-sig')) if c['type']=='feature']
    store = json.loads((ROOT/'data/feature_store_ledger.json').read_text(encoding='utf-8-sig'))
    nodes = []
    for card in primitive + store:
        live_store = card in store
        parents = [card['purchase_parent']] if card.get('purchase_parent') else []
        price = card['base_price_cents'] if live_store else {1:30000,2:45000,3:60000}[card['scope']]
        nodes.append(dict(id=card['id'],live_id=card['id'],name=card['name'],lane=lane_of[card['id']],
            source_status='live_store' if live_store else 'live_primitive',era_year=1981 if live_store else 1980,
            phase=card['phase'],department=card['department'],scope=card['scope'],parents=parents,
            ordered_core=[dict(stat=card[p+'_stat'],value=card[p+'_value']) for p in ['primary','secondary'] if card.get(p+'_stat')],
            direct_tags=[],prices_cents=[price]*3,price_status='live_base' if live_store else 'live_reserve',
            gameplay_features_required=card.get('gameplay_features_required',0)))
    for line in txt.splitlines():
        if not line.startswith('|'): continue
        cells = [c.strip() for c in line.strip('|').split('|')]
        if len(cells)==7 and cells[1] in lane_of.values() and ' · ' in cells[2] and re.fullmatch(r'\d+/\d+/\d+/\d+',cells[4]):
            name,lane,dep_order,parent,totals,scope,cls = cells
            dep,order = dep_order.split(' · ')
            nodes.append(dict(id=ident(name),live_id=None,name=name,lane=lane,source_status='authored_alpha_unimplemented',
                era_year=1981,phase='alpha',department=ident(dep),scope=int(scope),parent_names=parent.split(' + '),
                ordered_core=ordered(order),direct_tags=[],prices_cents=BANDS[cls],price_status='unapproved_trial_class',
                price_class=cls,gameplay_features_required=0))
        elif len(cells)==7 and ' / ' in cells[1] and re.fullmatch(r'\d+/\d+/\d+/\d+',cells[3]):
            name,lane_phase,parent,totals,scope,cls,_ = cells
            lane,phase = lane_phase.split(' / ')
            nodes.append(dict(id=ident(name),live_id=None,name=name,lane=lane,source_status='invented_candidate',
                phase=phase.lower(),scope=int(scope),parent_names=[] if parent=='Root' else parent.split(' + '),
                table_totals=list(map(int,totals.split('/'))),prices_cents=BANDS[cls],price_status='unapproved_trial_class',
                price_class=cls,gameplay_features_required=0))
    byname = {c['name']:c for c in nodes}
    for line in txt.splitlines():
        if not line.startswith('|'): continue
        cells = [c.strip() for c in line.strip('|').split('|')]
        if len(cells)==5 and cells[1] in byname and byname[cells[1]]['source_status']=='invented_candidate':
            era,name,order,dep,tags = cells
            byname[name].update(era_year=int(era[:4]),ordered_core=ordered(order),
                department='' if dep=='—' else ident(dep),direct_tags=[] if tags=='—' else [tags])
    byid = {c['id']:c for c in nodes}
    assert len(nodes)==len(byname)==len(byid)==97
    for c in nodes:
        if 'parent_names' in c: c['parents']=[byname[p]['id'] for p in c['parent_names']]
        c['parent_names']=[byid[p]['name'] for p in c['parents']]
        c['core']={s:sum(e['value'] for e in c['ordered_core'] if e['stat']==s) for s in STAT.values()}
        if 'table_totals' in c: assert list(c['core'].values())==c.pop('table_totals')
        c['printed_core_sum']=sum(c['core'].values())
        c['play_fee_analogue_cents']=1000*(c['printed_core_sum']+2*c['scope'])
        c['runtime_effect_schema_supported']=len(c['ordered_core'])<=2
        c['runtime_and_gate_supported']=len(c['parents'])<=1
        c['literal_cycle']=(c['era_year']-1980)*24 if c['era_year'] in LATER else None
        c['actual_playable_definition']=bool(c['live_id'])
    visiting=set(); seen=set()
    def walk(id_):
        assert id_ not in visiting, id_
        if id_ in seen:return
        visiting.add(id_)
        for p in byid[id_]['parents']:
            assert byid[p]['era_year']<=byid[id_]['era_year'], (id_,p)
            walk(p)
        visiting.remove(id_); seen.add(id_)
    for c in nodes: walk(c['id'])
    prior=json.loads((ROOT/'design-logs/feature-store-staged-v1/stage1_catalog_v1.json').read_text(encoding='utf-8'))
    older={c['id']:c for c in prior['nodes']}
    assert set(older)==set(byid)
    for c in nodes:
        for key in ['name','phase','department','scope','parents','ordered_core','direct_tags']:
            assert c[key]==older[c['id']][key], (c['id'],key)
    assert [sum(c['era_year']==y for c in nodes) for y in LATER]==[10,12,6,4,6]
    result=dict(schema_version=1,mode='shadow_catalog_not_runtime',source_head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
        draft_path=str(DRAFT),draft_sha256=hashlib.sha256(DRAFT.read_bytes()).hexdigest(),
        calendar_origin=1980,cycles_per_year=24,later_eras=[dict(year=y,cycle=(y-1980)*24,node_count=sum(c['era_year']==y for c in nodes)) for y in LATER],
        observation_horizon=dict(year=2026,cycle=1104,new_band=False),
        counts=dict(total=97,live=38,authored_alpha_unimplemented=13,invented_candidate=46,later=38),
        checks=['unique IDs and names','all AND parents present','acyclic','no future-era parent','prior Stage1 definition parity'],
        price_warning='Absent nodes use unapproved low/center/high classes. No inflation or player-cash scaling. Live Primitive price is reserve purchase price; six guaranteed owned starters are never charged again.',
        platform_warning='Direct capability tags only; never inherit ancestor tags. No live target platform selector or matrix. Conditional candidate purchases excluded from normal no-fixture analysis.',nodes=nodes)
    return result

if __name__=='__main__':
    OUT.mkdir(parents=True,exist_ok=True)
    result=build()
    (OUT/'catalog.json').write_text(json.dumps(result,indent=2,ensure_ascii=False),encoding='utf-8')
    print(json.dumps(dict(counts=result['counts'],eras=result['later_eras'],checks=result['checks'])))
