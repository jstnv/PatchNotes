"""Read-only proposed Feature Store graph/source audit and isolated shadow fixtures.

Run with bundled Python: python -B analysis/feature_store_stage1_v1.py
Writes analysis artifacts only; never modifies live card or Store definitions.
"""
from __future__ import annotations
import collections
import copy
import hashlib
import json
import math
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from docx import Document

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'design-logs/feature-store-staged-v1'
DRAFT = Path('C:/Users/64jus/Downloads/Patch_Notes_Multi_Era_Feature_Store_Design_v1.md')
HANDOFF = Path('C:/Users/64jus/Downloads/Patch_Notes_Feature_Store_Test_Handoff_v1.md')
LEDGERS = Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Cards')
STAT = dict(G='graphics', S='sound', T='technology', D='design')
BANDS = {'A':[65000,95000,125000], 'B':[140000,170000,200000],
         'B+':[160000,190000,220000], 'C1':[180000,240000,300000], 'C2':[220000,280000,340000]}

def ident(name):
    return re.sub(r'[^a-z0-9]+', '_', name.lower().replace('&', 'and')).strip('_')

def effects(order):
    return [{'stat':STAT[s], 'value':int(v)} for s,v in re.findall(r'([GSTD])(\d+)',order)]

def parent_names(text):
    return [] if text in ('Root','New Root','') else [x.strip() for x in text.split(' + ')]

def docx_cards(path):
    paras = [p.text.strip() for p in Document(path).paragraphs]
    result = {}
    era, department = 'primitive', ''
    for i,text in enumerate(paras):
        if text.startswith('1981'): era='1981–83'
        if text in ('Story','Gameplay','World Design','Audio'): department=ident(text)
        if i+1 >= len(paras) or not paras[i+1].startswith(('Raw Score','Requirement')): continue
        block=[]
        for p in paras[i+1:]:
            if not p: break
            block.append(p)
        joined='\n'.join(block)
        scores=[{'stat':s.lower(),'value':int(v)} for v,s in re.findall(r'\+(\d+)\s+(Graphics|Sound|Technology|Design)',joined)]
        scope=re.search(r'Scope:\s*(\d+)',joined)
        req=re.search(r'Requirements?:\s*([^\n]+)',joined)
        if not scope or not scores: continue
        result[text]={'ordered_core':scores,'scope':int(scope[1]),'era':era,
                      'department':department if 'DEPARTMENT' in path.name else '',
                      'parents':parent_names(req[1]) if req and req[1]!='Own 3 Gameplay Features' else [],
                      'special_gate':3 if req and req[1]=='Own 3 Gameplay Features' else 0}
    return result

def build_catalog():
    txt=DRAFT.read_text(encoding='utf-8')
    defs=json.loads((ROOT/'data/card_ledger.json').read_text(encoding='utf-8-sig'))
    offers=json.loads((ROOT/'data/feature_store_ledger.json').read_text(encoding='utf-8-sig'))
    current=[d for d in defs if d['type']=='feature']+offers
    lane_src=(ROOT/'scripts/ui/feature_store.gd').read_text(encoding='utf-8')
    lane_lookup={id_:lane for lane,ids in re.findall(r'&"([^"]+)": \[([^\]]+)\]',lane_src) for id_ in re.findall(r'&"([^"]+)"',ids)}
    nodes=[]
    for d in current:
        order=[{'stat':d[p+'_stat'],'value':d[p+'_value']} for p in ('primary','secondary') if d.get(p+'_stat')]
        nodes.append({'id':d['id'],'name':d['name'],'lane':lane_lookup[d['id']],
            'phase':d['phase'],'department':d['department'],'ordered_core':order,'scope':d['scope'],
            'parents':[d['purchase_parent']] if d.get('purchase_parent') else [],
            'era':'1981–83' if d in offers else 'primitive','era_start_year':1981 if d in offers else 1980,
            'status':'current','direct_tags':[], 'base_price_cents':d.get('base_price_cents'),
            'gameplay_features_required':d.get('gameplay_features_required',0), 'runtime_definition':d})
    name_lookup={n['name']:n['id'] for n in nodes}
    for line in txt.splitlines():
        if not line.startswith('|'): continue
        cells=[c.strip() for c in line.strip('|').split('|')]
        if len(cells)==7 and cells[1] in lane_lookup.values() and ' · ' in cells[2] and re.fullmatch(r'\d+/\d+/\d+/\d+',cells[4]):
            name,lane,deporder,parents,totals,scope,cls=cells
            dep,order=deporder.split(' · ')
            nodes.append({'id':ident(name),'name':name,'lane':lane,'phase':'alpha','department':ident(dep),
                'ordered_core':effects(order),'scope':int(scope),'parent_names':parent_names(parents),
                'era':'1981–83','era_start_year':1981,'status':'ledger_authored','direct_tags':[],
                'price_class':cls,'base_price_trial_cents':BANDS[cls], 'gameplay_features_required':0})
        elif len(cells)==7 and ' / ' in cells[1] and re.fullmatch(r'\d+/\d+/\d+/\d+',cells[3]):
            name,lanephase,parents,totals,scope,cls,_=cells
            lane,phase=lanephase.split(' / ')
            nodes.append({'id':ident(name),'name':name,'lane':lane,'phase':phase.lower(),
                'scope':int(scope),'parent_names':parent_names(parents),'status':'candidate',
                'table_core_totals':dict(zip(STAT.values(),map(int,totals.split('/')))),
                'price_class':cls,'base_price_trial_cents':BANDS[cls],'gameplay_features_required':0})
    name_lookup={n['name']:n['id'] for n in nodes}
    byname={n['name']:n for n in nodes}
    for line in txt.splitlines():
        if not line.startswith('|'): continue
        cells=[c.strip() for c in line.strip('|').split('|')]
        if len(cells)==5 and cells[1] in byname and byname[cells[1]]['status']=='candidate':
            era,name,order,dep,tag=cells
            byname[name].update(era=era,era_start_year=int(era[:4]),ordered_core=effects(order),
                department='' if dep=='—' else ident(dep),direct_tags=[] if tag=='—' else [tag])
    for n in nodes:
        if 'parent_names' in n: n['parents']=[name_lookup[p] for p in n['parent_names']]
        else: n['parent_names']=[next(x['name'] for x in nodes if x['id']==p) for p in n['parents']]
        n['core']={s:sum(e['value'] for e in n['ordered_core'] if e['stat']==s) for s in STAT.values()}
        n['printed_core_sum']=sum(n['core'].values())
        n['analogue_play_fee_cents']=1000*(n['printed_core_sum']+2*n['scope'])
        n['schema_supported']=len(n['ordered_core'])<=2
        n['gate_supported']=len(n['parents'])<=1
        n['platform_selector_supported']=not n['direct_tags']
        if 'table_core_totals' in n: assert n['table_core_totals']==n['core'],n
    return nodes

class ShadowStore:
    """Only proposed AND/familiarity/compatibility boundary; no gameplay assertion."""
    MAX=2**63-1
    def __init__(self,catalog,cash=10**7):
        self.nodes={n['id']:n for n in catalog}; self.owned=set(); self.credits=collections.defaultdict(set)
        self.cash=cash; self.cycle=0; self.redraw=2; self.settled=0; self.exhausted=collections.defaultdict(set)
    def quote(self,id_,base=None):
        n=self.nodes[id_]; gate=n['gameplay_features_required']
        unlocked=all(p in self.owned for p in n['parents']) and sum(self.nodes[p]['department']=='gameplay' for p in self.owned)>=gate
        credit=sum(len(self.credits[p]) for p in n['parents']) if not gate else 0
        base=base or n.get('base_price_cents') or n['base_price_trial_cents'][1]
        return {'unlocked':unlocked,'discount_percent':min(credit,5)*10,'price_cents':base*(10-min(credit,5))//10}
    def buy(self,id_,settlement=0,fail=False):
        q=self.quote(id_)
        if not q['unlocked'] or id_ in self.owned or self.cash<q['price_cents'] or self.cycle>=self.MAX: return False
        after=self.cash-q['price_cents']+settlement
        if not 0<=after<=self.MAX or fail: return False
        self.owned.add(id_); self.cash=after; self.cycle+=1; self.redraw=min(self.redraw+1,4); self.settled+=settlement
        return True
    def resolve(self,id_,project,phase,successful=True):
        if not successful or id_ not in self.owned or phase not in ('design','alpha') or self.nodes[id_]['phase']!=phase: return False
        if id_ in self.exhausted[project]: return False
        self.credits[id_].add(project); self.exhausted[project].add(id_); return True
    def eligible(self,phase,project,tags):
        return [id_ for id_ in self.owned if self.nodes[id_]['phase']==phase and id_ not in self.exhausted[project]
                and set(self.nodes[id_]['direct_tags'])<=set(tags)]

def shadow_fixtures(nodes):
    checks=[]
    def ck(value,name):
        checks.append({'case':name,'passed':bool(value),'kind':'analysis_only_shadow'})
        assert value,name
    s=ShadowStore(nodes); s.owned={'general_combat'}
    ck(not s.quote('character_classes')['unlocked'],'AND rejects missing Save Files')
    before=copy.deepcopy(s.__dict__); ck(not s.buy('character_classes') and before==s.__dict__,'locked purchase atomic')
    s.owned.add('save_files'); ck(s.quote('character_classes')['unlocked'],'AND accepts both parents')
    ck(s.quote('character_classes')['discount_percent']==0,'ownership grants no credit')
    s.eligible('design','draw_only',[]); ck(s.quote('character_classes')['discount_percent']==0,'drawing grants no credit')
    ck(not s.resolve('general_combat','P0','contract') and s.quote('character_classes')['discount_percent']==0,'Contract gives no credit in milestone fixture')
    ck(s.resolve('general_combat','P1','alpha') and s.resolve('save_files','P1','design') and s.quote('character_classes')['discount_percent']==20,'two distinct parents same project give two credits')
    ck(not s.resolve('general_combat','P1','alpha') and s.quote('character_classes')['discount_percent']==20,'same parent same project only once')
    grid=[]
    for credit in range(9):
        t=ShadowStore(nodes); t.owned={'general_combat','save_files'}
        t.credits['general_combat']=set(range(credit))
        quote=t.quote('character_classes'); grid.append({'credits':credit,**quote})
        ck(quote['discount_percent']==min(credit,5)*10 and quote['price_cents']==170000*(10-min(credit,5))//10,f'exact quote {credit} credits')
    for cash,fail,settlement in [(135999,False,0),(500000,True,0),(ShadowStore.MAX,False,200000)]:
        s.cash=cash; before=copy.deepcopy(s.__dict__)
        ck(not s.buy('character_classes',settlement,fail) and before==s.__dict__,f'cash/failure/overflow rollback {cash}/{fail}/{settlement}')
    s.cash=136001; ck(s.buy('character_classes') and s.cash==1 and s.cycle==1 and s.redraw==3,'exact-cent one-cycle purchase with one overall discount')
    before=copy.deepcopy(s.__dict__); ck(not s.buy('character_classes') and before==s.__dict__,'duplicate purchase atomic')
    d=ShadowStore(nodes); d.owned={'controls','enemies'}; ck(not d.quote('difficulty_levels')['unlocked'],'Difficulty two Gameplay locked')
    d.owned.add('power_ups'); d.credits['enemies']=set(range(20))
    ck(d.quote('difficulty_levels')['unlocked'] and d.quote('difficulty_levels')['discount_percent']==0,'Difficulty three Gameplay and no discount')
    p=ShadowStore(nodes); p.owned={'text','tile_based_backgrounds','isometric_room_view'}
    ck('tile_based_backgrounds' not in p.eligible('design','incompatible',[]),'incompatible filtered before draw')
    no_platform=ShadowStore(nodes); no_platform.owned={'tile_based_backgrounds'}
    eligible=no_platform.eligible('design','unusable',[])
    synthetic_pool=eligible+['graphics_pass']*7 if not eligible else eligible
    ck(len(synthetic_pool)==7 and set(synthetic_pool)=={'graphics_pass'},'synthetic no-compatible Feature retains seven Pass fallback slots; filtered Feature consumes none')
    ck('isometric_room_view' in p.eligible('design','incompatible',[]),'no inherited character-tile graphics tag')
    ck('tile_based_backgrounds' in p.eligible('design','compatible',['character-tile graphics']),'owned Feature persists into compatible project')
    ck(p.resolve('text','earlier_compatible','design') and p.quote('tile_based_backgrounds')['discount_percent']==10,'earlier project parent familiarity persists across platforms')
    ck(p.resolve('tile_based_backgrounds','compatible','design') and 'tile_based_backgrounds' not in p.eligible('design','compatible',['character-tile graphics']) and 'tile_based_backgrounds' in p.eligible('design','later',['character-tile graphics']),'finite per project independent supply')
    for n in nodes:
        if len(n['ordered_core'])!=3: continue
        ordered=n['ordered_core']
        priorities={'graphics':10,'sound':20,'technology':30,'design':40}
        weighted=sum(e['value']*priorities[e['stat']] for e in ordered)
        pressure=sum(e['value'] for e in ordered)*n['scope']/18
        # One feature plus3 matching primary Core Passes; round half away fromzero like Godot.
        raw=n['core'].copy(); raw[ordered[0]['stat']]+=3
        resolved={stat:math.floor(value*1.5+0.5) for stat,value in raw.items()}
        ck(weighted>sum(e['value']*priorities[e['stat']] for e in ordered[:2]) and pressure>0
           and resolved[ordered[2]['stat']]>0 and n['scope'] in (2,3),
           n['name']+' explicitly shadow tertiary retained in orderedweight specialization BugPressure; Scope unchanged')
    return checks,grid

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    nodes=build_catalog(); byid={n['id']:n for n in nodes}
    assert len(nodes)==len(byid)==len({n['name'] for n in nodes})==97
    ledger={}
    for path in LEDGERS.glob('*LEDGER.docx'): ledger.update(docx_cards(path))
    mismatches=[]
    for n in nodes:
        if n['status']=='candidate': continue
        row=ledger[n['name']]
        for key in ('ordered_core','scope','department','era'):
            if n[key]!=row[key]: mismatches.append({'card':n['name'],'field':key,'catalog':n[key],'docx':row[key]})
        if n['parent_names']!=row['parents']: mismatches.append({'card':n['name'],'field':'parents','catalog':n['parent_names'],'docx':row['parents']})
    visiting=set(); visited=set(); depths={}
    def visit(id_):
        assert id_ not in visiting, f'cycle {id_}'
        if id_ in visited:return depths[id_]
        visiting.add(id_); n=byid[id_]; depth=0
        for p in n['parents']:
            assert p in byid,(id_,p)
            assert byid[p]['era_start_year']<=n['era_start_year'],(id_,p)
            depth=max(depth,visit(p)+1)
        visiting.remove(id_); visited.add(id_); depths[id_]=depth; return depth
    for n in nodes: visit(n['id'])
    for n in nodes:
        n['depth']=depths[n['id']]
        n['cross_lane_parents']=[p for p in n['parents'] if byid[p]['lane']!=n['lane']]
    catalog={'schema_version':1,'mode':'proposal_catalog_not_live_gameplay','source_head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
        'price_classes_cents':BANDS,'nodes':nodes}
    (OUT/'stage1_catalog_v1.json').write_text(json.dumps(catalog,indent=2,ensure_ascii=False),encoding='utf-8')
    checks,grid=shadow_fixtures(nodes)
    primitive=[n for n in nodes if n['era']=='primitive']
    authored=[n for n in nodes if n['status']=='ledger_authored']
    sources=[DRAFT,HANDOFF,*LEDGERS.glob('*LEDGER.docx'),ROOT/'data/card_ledger.json',ROOT/'data/feature_store_ledger.json',OUT/'sources/authority_current.txt',OUT/'sources/queue_current.txt']
    report={'source_head':catalog['source_head'],'source_sha256':{str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in sources},
        'nodes':len(nodes),'status_counts':dict(collections.Counter(n['status'] for n in nodes)),
        'lane_counts':dict(collections.Counter(n['lane'] for n in nodes)), 'era_counts':dict(collections.Counter(n['era'] for n in nodes)),
        'authored_docx_compared':51,'authored_docx_mismatches':mismatches,
        'primitive_scope':sum(n['scope'] for n in primitive),'primitive_count':len(primitive),
        'primitive_core':{s:sum(n['core'][s] for n in primitive) for s in STAT.values()},
        'department_1981_scope':sum(n['scope'] for n in authored),
        'department_1981_core':{s:sum(n['core'][s] for n in authored) for s in STAT.values()},
        'department_1981_two_parent':[n['name'] for n in authored if len(n['parents'])==2],
        'edges':sum(len(n['parents']) for n in nodes),'cross_lane_edges':sum(len(n['cross_lane_parents']) for n in nodes),
        'two_parent_nodes':sum(len(n['parents'])==2 for n in nodes),'max_depth':max(depths.values()),'cycles':[],
        'unsupported_three_core':[n['name'] for n in nodes if not n['schema_supported']],
        'direct_conditional_count':sum(bool(n['direct_tags']) for n in nodes),
        'capability_boundaries':['Live CardData stores only two ordered effects.','Live RunState quote reads one purchase_parent and only that parent familiarity.','No live platform selector/direct-tag eligibility filter.','Store UI only current38nodes/single-parent connector; AND badges/era bands not implemented.'],
        'direct_tag_audit_open':['3D Camera Controls declares no direct tag despite needing a3D path; cannot infer tag from Polygon Models automatically.','Physics-Based Objects declares no direct physics capability; engine threshold not defined.','Untagged cards retain empty tags for literal proposal fixture; not asserted universally platform-supported.'],
        'shadow_fixture_checks':checks,'combined_discount_grid':grid}
    (OUT/'stage1_static_and_shadow_v1.json').write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding='utf-8')
    print(json.dumps({k:report[k] for k in ['nodes','status_counts','lane_counts','era_counts','authored_docx_mismatches','primitive_scope','edges','cross_lane_edges','two_parent_nodes','unsupported_three_core','direct_conditional_count']}))
    print(f'{len(checks)} isolated shadow fixtures passed; catalog written {OUT / "stage1_catalog_v1.json"}')
    if '--godot' in sys.argv:
        profile=Path(tempfile.mkdtemp(prefix='patchnotes-feature-stage1-'))
        env=os.environ.copy()
        for key,sub in [('APPDATA','roaming'),('LOCALAPPDATA','local')]:
            env[key]=str(profile/sub); Path(env[key]).mkdir()
        cmd=['C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe','--headless','--path',str(ROOT),'--script','res://analysis/feature_store_stage1_v1.gd']
        result=subprocess.run(cmd,env=env,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=120)
        output=result.stdout+'\n'+result.stderr
        (OUT/'stage1_live_probe_isolated_v1.log').write_text(output,encoding='utf-8')
        (OUT/'stage1_live_command_v1.json').write_text(json.dumps({'command':cmd,'profile':str(profile),'exit':result.returncode},indent=2))
        print(output[-4000:]); raise SystemExit(result.returncode)

if __name__=='__main__': main()
