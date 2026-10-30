from pathlib import Path
import json,hashlib,shutil,subprocess,difflib,sys
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[5]
PREV=HERE.parent/'crown-qa-core-20261024-v1'
VAR=HERE.parents[1]/'simulators/crown-beta-redraw-v2'
RAW=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-beta-redraw-20261024-v1')
PY='C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
GODOT='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
PAIRS=['qa-simulation-4522','qa-simulation-4521']
write=lambda p,o:p.write_text(json.dumps(o,indent=2)+'\n',encoding='utf-8')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    assert (VAR/'variant.json').exists() and not (HERE/'policy.gd').exists()
    src=HERE.parents[1]/'simulators/crown-qa-core-v1/project/scripts/debug/crown_access_legacy_v1.gd'
    target=VAR/'project/scripts/debug/crown_access_legacy_v1.gd'
    assert not target.exists();shutil.copyfile(src,target)
    old=(PREV/'policy.gd').read_text(encoding='utf-8')
    policy=old.replace('var qa_extra := false','var qa_extra := false\nvar reserved_redraw := false')
    policy=policy.replace('\tqa_extra = false\n','\tqa_extra = false\n\treserved_redraw = false\n')
    policy=policy.replace('"qa_extra":qa_extra,','"qa_extra":qa_extra,"reserved_redraw":reserved_redraw,')
    anchor='\tif not redrawn.has(key) and int(d.redraws) > 0:'
    assert policy.count(anchor)==1
    policy=policy.replace(anchor,'\tif not (d.phase == "beta" and cfg.get("reserve_beta_redraw",false)) and not redrawn.has(key) and int(d.redraws) > 0:')
    anchor='\tvar rule := 3 if search and debug else (1 if search else (2 if debug and int(d.known_bugs)>0 else 0))'
    assert policy.count(anchor)==1
    policy=policy.replace(anchor,'''\tif cfg.get("reserve_beta_redraw",false) and not search and not redrawn.has(key) and int(d.redraws)>0:
\t\tvar keep: Array[int] = best(d,int(view.cash_cents)-4*rent,false,2 if debug else 0)
\t\tif not keep.is_empty():
\t\t\tfor i in range(d.candidates.size()-1,-1,-1):
\t\t\t\tif i not in keep:
\t\t\t\t\tredrawn[key] = true
\t\t\t\t\treserved_redraw = true
\t\t\t\t\treturn Legacy._development(view,&"redraw",{"candidate_ids":[int(d.candidates[i].token)]})
'''+anchor)
    (HERE/'policy.gd').write_text(policy,encoding='utf-8')
    (HERE/'policy.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True),policy.splitlines(True),fromfile='CA1d policy',tofile='CA1e reserved redraw policy')),encoding='utf-8')
    cases=[]
    for pair in PAIRS:
        config=json.loads((PREV/(pair+'.json')).read_text(encoding='utf-8'))
        config['policy'].update(id='crown-beta-redraw',version='1')
        for c in config['cases']:
            arm=c['study']['arm']
            c['policy']['config'].update(qa_extension=True,core_target=False,reserve_beta_redraw=arm=='candidate')
            cases.append({'pair':pair,'case':c['case_id'],'arm':arm})
        write(HERE/(pair+'.json'),config)
    write(HERE/'declared-cases.json',cases)
    for name in ['run.py','analyze.py']:
        shutil.copyfile(PREV/name,HERE/name)
    sys.path.insert(0,str(ROOT/'tools'));import simulator_variant as variants
    meta,base,current,integrity=variants.load_variant(VAR)
    priorbase=json.loads((HERE.parents[1]/'simulators/crown-qa-core-v1/base-manifest.json').read_text())
    write(HERE/'source-pins.json',{'variant':meta,'candidate_identity':variants.identity(current),'delta':variants.delta(base,current),'from_ca1d_baseline':variants.delta(priorbase,base),'policy_sha256':sha(HERE/'policy.gd'),'plan_sha256':sha(HERE.parents[1]/'CROWN-BETA-REDRAW-PLAN-2026-10-24-v1.md'),'runner_sha256':sha(ROOT/'tools/simulate.py'),'godot_sha256':sha(Path(GODOT)),'integrity':integrity})
    git=lambda args:subprocess.run(['git',*args],cwd=ROOT,capture_output=True,text=True).stdout
    write(HERE/'intake.json',{'branch':git(['branch','--show-current']).strip(),'head':git(['rev-parse','HEAD']).strip(),'status':git(['status','--short']),'diff_stat':git(['diff','--stat'])})
    print(json.dumps({'cases':len(cases),'baseline':meta['base_identity'],'candidate':variants.identity(current),'delta':variants.delta(base,current)}))

if __name__=='__main__':main()
