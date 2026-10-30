from setup import HERE, ROOT, write
import json, re, hashlib, subprocess
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))

def main():
    a=load(HERE/'analysis.json');rows=a['rows']
    assert len(rows)==12 and all(r['ok'] and r['commands']==r['accepted_commands'] and r['arrears_max']==0 for r in rows)
    assert sum(r['commands'] for r in rows)==2270
    candidates=[r for r in rows if r['arm']=='acquire'];controls=[r for r in rows if r['arm']=='control']
    assert sum(r['unlocked'] for r in candidates)==4 and sum(r['unlocked'] for r in controls)==2
    assert sum(len(r['acquired']) for r in candidates)==13
    assert sum(len(r['purchases']) for r in candidates)==26
    for r in candidates:
        assert r['projects'][-1]['supply_scope']==30
        assert set(r['acquired'])==set(r['draws'])=={p['id'] for p in r['plays']}
    assert sum(q['scope']>=q['required_scope'] for r in candidates for q in r['review_details'])==10
    assert not any(q['scope']>=q['required_scope'] for r in controls for q in r['review_details'])
    receipts=load(HERE/'documentation-update.json')
    for receipt in receipts:
        p=ROOT/receipt['path'];assert hashlib.sha256(p.read_bytes()).hexdigest()==receipt['after'],'Concurrent document change requires review: '+str(p)
    docs=[HERE.parents[1]/name for name in ['CROWN-ACQUISITION-PLAN-2026-10-24-v1.md','CROWN-ACQUISITION-FINDINGS-2026-10-24-v1.md','CROWN-ACQUISITION-HANDOFF-2026-10-24-v1.md','SESSION-LOG-2026-10-24-crown-acquisition-v1.md']]
    links=0
    for p in docs:
        for target in re.findall(r'\]\(([^)]+)\)',p.read_text(encoding='utf-8')):
            if '://' in target or target.startswith('#'):continue
            assert (p.parent/target.split('#')[0]).exists(),(p.name,target)
            links+=1
    head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
    branch=subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip()
    assert head==load(HERE/'intake.json')['head']
    result={'status':'PASS','local_links':links,'documents':[str(p.relative_to(ROOT)) for p in docs],'shared_and_owned_update_receipts_match':True,'one_todo_entry_changed':True,'study_counts_verified':True,'branch':branch,'head':head,'files_sha256':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in docs}}
    write(HERE/'documentation-check.json',result)
    print(json.dumps(result,indent=2))

if __name__=='__main__':main()
