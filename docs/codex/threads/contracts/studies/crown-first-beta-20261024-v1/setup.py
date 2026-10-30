from pathlib import Path
import json,hashlib,shutil,subprocess,difflib,sys
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[5]
PREV=HERE.parent/'crown-beta-redraw-20261024-v1'
VAR=HERE.parents[1]/'simulators/crown-first-beta-v1'
RAW=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-first-beta-20261024-v1')
PY='C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
GODOT='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
PAIRS=['qa-simulation-4522','qa-simulation-4521']
ARMS=['control','reserved','candidate']
write=lambda p,o:p.write_text(json.dumps(o,indent=2)+'\n',encoding='utf-8')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def replace_once(text,old,new):
    assert text.count(old)==1,old
    return text.replace(old,new)

def main():
    assert (VAR/'variant.json').exists() and not (HERE/'policy.gd').exists()
    src=HERE.parents[1]/'simulators/crown-beta-redraw-v2/project/scripts/debug/crown_access_legacy_v1.gd'
    target=VAR/'project/scripts/debug/crown_access_legacy_v1.gd'
    assert not target.exists();shutil.copyfile(src,target)
    old=(PREV/'policy.gd').read_text(encoding='utf-8')
    policy=replace_once(old,'var reserved_redraw := false','var reserved_redraw := false\nvar first_redraw := false')
    policy=replace_once(policy,'\treserved_redraw = false\n','\treserved_redraw = false\n\tfirst_redraw = false\n')
    policy=replace_once(policy,'"reserved_redraw":reserved_redraw,','"reserved_redraw":reserved_redraw,"first_redraw":first_redraw,')
    anchor='\tvar extra_selected: Array[int] = []'
    policy=replace_once(policy,anchor,'''\tif cfg.get("first_search_redraw",false) and d.phase == "beta" and count == 0 and not redrawn.has(key) and int(d.redraws)>0 and int(view.cash_cents)>=4*rent:
\t\tvar search := false
\t\tvar debug := false
\t\tfor card in d.candidates:
\t\t\tsearch = search or card.definition == "search_for_bugs"
\t\t\tdebug = debug or card.definition == "debug"
\t\tif not search:
\t\t\tvar keep: Array[int] = best(d,int(view.cash_cents)-4*rent,false,2 if debug else 0)
\t\t\tif not keep.is_empty():
\t\t\t\tfor i in range(d.candidates.size()-1,-1,-1):
\t\t\t\t\tif i not in keep:
\t\t\t\t\t\tredrawn[key] = true
\t\t\t\t\t\tfirst_redraw = true
\t\t\t\t\t\treturn Legacy._development(view,&"redraw",{"candidate_ids":[int(d.candidates[i].token)]})
'''+anchor)
    (HERE/'policy.gd').write_text(policy,encoding='utf-8')
    (HERE/'policy.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True),policy.splitlines(True),fromfile='CA1e policy',tofile='CA1f first-hand policy')),encoding='utf-8')
    cases=[]
    for pair in PAIRS:
        prior=json.loads((PREV/(pair+'.json')).read_text(encoding='utf-8'))
        config={'schema_version':'1','policy':{'script':'policy.gd','id':'crown-first-beta','version':'1'},'cases':[]}
        for arm in ARMS:
            c=json.loads(json.dumps(prior['cases'][0]));c['case_id']=arm+'-'+pair;c['study']['arm']=arm
            c['policy']['config'].update(label=c['case_id'],reserve_beta_redraw=arm!='control',first_search_redraw=arm=='candidate')
            config['cases'].append(c);cases.append({'pair':pair,'case':c['case_id'],'arm':arm})
        write(HERE/(pair+'.json'),config)
    write(HERE/'declared-cases.json',cases)
    shutil.copyfile(PREV/'run.py',HERE/'run.py')
    sys.path.insert(0,str(ROOT/'tools'));import simulator_variant as variants
    meta,base,current,integrity=variants.load_variant(VAR)
    priorbase=json.loads((HERE.parents[1]/'simulators/crown-beta-redraw-v2/base-manifest.json').read_text())
    write(HERE/'source-pins.json',{'variant':meta,'candidate_identity':variants.identity(current),'delta':variants.delta(base,current),'from_ca1e_baseline':variants.delta(priorbase,base),'policy_sha256':sha(HERE/'policy.gd'),'plan_sha256':sha(HERE.parents[1]/'CROWN-FIRST-BETA-PLAN-2026-10-24-v1.md'),'runner_sha256':sha(ROOT/'tools/simulate.py'),'godot_sha256':sha(Path(GODOT)),'integrity':integrity})
    git=lambda args:subprocess.run(['git',*args],cwd=ROOT,capture_output=True,text=True).stdout
    write(HERE/'intake.json',{'branch':git(['branch','--show-current']).strip(),'head':git(['rev-parse','HEAD']).strip(),'status':git(['status','--short']),'diff_stat':git(['diff','--stat'])})
    print(json.dumps({'cases':len(cases),'baseline':meta['base_identity'],'candidate':variants.identity(current),'delta':variants.delta(base,current)}))
if __name__=='__main__':main()
