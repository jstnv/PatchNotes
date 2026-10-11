"""Independent integer/brute-force 1/1 oracle for the private G2 study.

Uses the frozen raw ledgers, not the candidate's generated hand catalog or DP.
This is deliberately restricted to no-trait current-catalog 1/1 fixtures.
"""
from __future__ import annotations
from functools import lru_cache
from itertools import combinations_with_replacement
import hashlib
import json
import math
from pathlib import Path
import time
import sys

BASE=Path(__file__).resolve().parent
PROJECT=BASE/'sims/g2-legal-mix-v2-prefix/project'
STUDY=BASE/'sims/g2-legal-mix-v2-study'
CARD_ROWS=json.loads((PROJECT/'data/card_ledger.json').read_text())
STORE_ROWS=json.loads((PROJECT/'data/feature_store_ledger.json').read_text())
CARDS={item['id']:item for item in CARD_ROWS+STORE_ROWS}
LATER={item['id'] for item in STORE_ROWS}
CORES=['graphics','sound','technology','design']
REUSED={}

def hands(owned,phase):
    sources=[CARDS[item] for item in owned if CARDS[item]['phase']==phase]
    sources += [item for item in CARD_ROWS if item['type']=='pass' and item['phase']=='design']
    out=[]
    for selected in combinations_with_replacement(range(len(sources)),4):
        cards=[sources[i] for i in selected]
        finite=[card['id'] for card in cards if not card['renewable']]
        if len(set(finite))!=len(finite): continue
        vector=[0]*4
        cost=0
        for card in cards:
            vector[CORES.index(card['primary_stat'])]+=card['primary_value']
            if card['secondary_stat']:
                vector[CORES.index(card['secondary_stat'])]+=card['secondary_value']
            if card['type']=='feature' and card['id'] not in LATER:
                cost+=(card['primary_value']+card['secondary_value']+2*card['scope'])*1000
        if len({card['primary_stat'] for card in cards})==1:
            vector=[(value*3+1)//2 for value in vector]
        elif finite and sum(vector)>0 and all(85*sum(vector)<=400*value<=115*sum(vector) for value in vector):
            total=sum(vector)
            vector=[total//4+int(i<total%4) for i in range(4)]
        out.append((tuple(vector),cost,bool(finite)))
    return out

@lru_cache(None)
def brute(owned,targets,cash):
    if (owned,targets,cash) in REUSED: return REUSED[(owned,targets,cash)]
    started=time.monotonic()
    scale=math.lcm(*targets)
    factors=tuple(scale//target for target in targets)
    best=None
    targeted=[None]*4
    attempted=legal=0
    design=hands(owned,'design')
    alpha=hands(owned,'alpha')
    for left,lc,lw in design:
        for right,rc,rw in alpha:
            attempted+=1
            if lc+rc>cash or not (lw or rw): continue
            legal+=1
            core=tuple(a+b for a,b in zip(left,right))
            gaps=tuple(max(0,t-c)*f for t,c,f in zip(targets,core,factors))
            key=(sum(gaps),max(gaps),*gaps)
            if best is None or key<best: best=key
            for index in range(4):
                key=(sum(gaps),gaps[index],max(gaps),*gaps)
                if targeted[index] is None or key<targeted[index]: targeted[index]=key
    return {'baseline':best,'targeted':targeted,'scale':scale,'attempted':attempted,'legal':legal,
            'hands':[len(design),len(alpha)],'elapsed_seconds':time.monotonic()-started}

def check(godot,oracle):
    if not godot['baseline']:
        return oracle['baseline'] is None
    gap=godot['baseline']['gap']
    if (gap['sum'],gap['maximum'],*gap['gaps'])!=tuple(oracle['baseline']): return False
    for i,row in enumerate(godot['targeted']):
        gap=row['gap']
        if (gap['sum'],gap['gaps'][i],gap['maximum'],*gap['gaps'])!=tuple(oracle['targeted'][i]): return False
    return True

def main():
    partial=STUDY/'independent-brute-force-partial-01.json'
    if partial.exists():
        prior=json.loads(partial.read_text())
        assert prior['ok'] and all(hashlib.sha256((PROJECT/path).read_bytes()).hexdigest()==digest for path,digest in prior['inputs'].items())
        for row in prior['rows']:
            item=json.loads(Path(row['result']).read_text())
            owned=tuple(sorted(item['owned_before']))
            targets=tuple(item['targets'])
            cash=item['allowance_cents']
            REUSED[(owned,targets,cash)]=row['before']
            if row['after']:
                REUSED[(tuple(sorted((*owned,item['candidate']))),targets,cash)]=row['after']
    rows=[]
    for path in sorted(STUDY.glob('*/result.json')):
        result=json.loads(path.read_text())
        if result.get('hands')!=[1,1] or not result.get('baseline',{}).get('complete'): continue
        owned=tuple(sorted(result['owned_before']))
        targets=tuple(result['targets'])
        cash=result['allowance_cents']
        before=brute(owned,targets,cash)
        ok=check(result['baseline'],before)
        after=None
        if result.get('after',{}).get('complete'):
            after=brute(tuple(sorted((*owned,result['candidate']))),targets,cash)
            ok=ok and check(result['after'],after)
        rows.append({'result':str(path),'ok':ok,'before':before,'after':after})
    output={'ok':bool(rows) and all(row['ok'] for row in rows),'rows':rows,
            'reused_exact_input_oracles':len(REUSED),'reused_audit_sha256':hashlib.sha256(partial.read_bytes()).hexdigest() if partial.exists() else '',
            'scope':'Independent full 1/1 raw-ledger enumeration only; no 2/2 or3/3 completeness claim',
            'inputs':{str(path.relative_to(PROJECT)):hashlib.sha256(path.read_bytes()).hexdigest() for path in [PROJECT/'data/card_ledger.json',PROJECT/'data/feature_store_ledger.json']}}
    destination=STUDY/(sys.argv[1] if len(sys.argv)>1 else 'independent-brute-force-audit.json')
    if destination.exists(): raise RuntimeError('Audit destination already exists')
    destination.write_text(json.dumps(output,indent=2))
    print(json.dumps({'ok':output['ok'],'comparisons':len(rows),'distinct_brute_cases':brute.cache_info().currsize}))
    return 0 if output['ok'] else 1

if __name__=='__main__': raise SystemExit(main())
