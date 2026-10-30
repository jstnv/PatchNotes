from pathlib import Path
import json, hashlib, shutil, subprocess, difflib, sys
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[5]
PREV=HERE.parent/'crown-extra-hand-20261024-v1'
VAR=HERE.parents[1]/'simulators/crown-qa-core-v1'
RAW=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-qa-core-20261024-v1')
PY='C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
GODOT='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
PAIRS=['qa-simulation-4522','qa-simulation-4521','core-puzzle-4521','core-puzzle-4522']
write=lambda p,o:p.write_text(json.dumps(o,indent=2)+'\n',encoding='utf-8')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    assert (VAR/'variant.json').exists() and not (HERE/'policy.gd').exists()
    src=HERE.parents[1]/'simulators/crown-extra-hand-v1/project/scripts/debug/crown_access_legacy_v1.gd'
    target=VAR/'project/scripts/debug/crown_access_legacy_v1.gd'
    assert not target.exists();shutil.copyfile(src,target)
    old=(PREV/'policy.gd').read_text(encoding='utf-8')
    policy=old.replace('var extra_play := false','var extra_play := false\nvar qa_extra := false\nvar qa_extensions: Dictionary = {}\nvar core_done := false\nvar core_pending := ""\nvar core_basis: Dictionary = {}')
    policy=policy.replace('\textra_play = false\n','\textra_play = false\n\tqa_extra = false\n\tcore_basis = {}\n')
    policy=policy.replace('"EXTRA "','"FOLLOWUP "').replace('"extra_play":extra_play,','"extra_play":extra_play,"qa_extra":qa_extra,"core_basis":core_basis,')
    anchor='\tif (count >= target and extra_selected.is_empty())'
    assert anchor in policy
    policy=policy.replace(anchor,'\tif cfg.get("qa_extension",false) and d.phase == "beta" and (qa_extensions.has(key) or count >= target or (count >= 3 and int(d.known_bugs) == 0)):\n\t\treturn extend_qa(view,d,key,rent)\n'+anchor)
    policy=policy.replace('require_scope_feature: bool = false) -> Array[int]:','require_scope_feature: bool = false, qa_rule: int = 0) -> Array[int]:')
    anchor='\t\t\t\t\tif require_scope_feature and not contains_scope: continue'
    policy=policy.replace(anchor,anchor+'''\n\t\t\t\t\tif qa_rule > 0:
\t\t\t\t\t\tvar search := false
\t\t\t\t\t\tvar debug := false
\t\t\t\t\t\tfor i in indices:
\t\t\t\t\t\t\tsearch = search or cards[i].definition == "search_for_bugs"
\t\t\t\t\t\t\tdebug = debug or cards[i].definition == "debug"
\t\t\t\t\t\tif qa_rule in [1,3] and not search: continue
\t\t\t\t\t\tif qa_rule in [2,3] and not debug: continue''')
    anchor='\t\t\t\tacquired_windows[view.releases.size()] = true'
    policy=policy.replace(anchor,anchor+'\n\t\t\t\tif str(q.feature_id) == core_pending: core_done = true')
    policy=policy.replace('\tif supply >= 30: return {}','\tif supply >= 30: return core_acquire(view,rent) if cfg.get("core_target",false) and not core_done else {}')
    policy+='''

func extend_qa(view: Dictionary, d: Dictionary, key: String, rent: int) -> Dictionary:
\tvar used: int = qa_extensions.get(key,0)
\tqa_extensions[key] = used
\tif used >= 2 or int(view.cash_cents) < 4*rent: return Legacy._development(view,&"request_exit")
\tvar search := false
\tvar debug := false
\tfor card in d.candidates:
\t\tsearch = search or card.definition == "search_for_bugs"
\t\tdebug = debug or card.definition == "debug"
\tvar rule := 3 if search and debug else (1 if search else (2 if debug and int(d.known_bugs)>0 else 0))
\tif rule == 0: return Legacy._development(view,&"request_exit")
\tvar selected: Array[int] = best(d,int(view.cash_cents)-4*rent,false,rule)
\tif selected.is_empty(): return Legacy._development(view,&"request_exit")
\tvar tokens: Array[int] = []
\tfor i in selected: tokens.append(int(d.candidates[i].token))
\tqa_extensions[key] = used+1
\thands[key] = int(hands.get(key,0))+1
\tqa_extra = true
\treturn Legacy._development(view,&"play",{"candidate_ids":tokens})

func core_acquire(view: Dictionary, rent: int) -> Dictionary:
\tif view.releases.is_empty(): return {}
\tvar review: Dictionary = view.releases[-1].metadata.review
\tif float(review.final_review) >= 7.0: return {}
\tvar weakest := 0
\tvar low := INF
\tfor k in range(4):
\t\tvar ratio: float = float(review.cores[k])/float(review.standards[k])
\t\tif ratio < low:
\t\t\tweakest=k
\t\t\tlow=ratio
\tif low >= 1.0: return {}
\tvar gap: int = int(review.standards[weakest])-int(review.cores[weakest])
\tvar winner: Dictionary = {}
\tvar best_ratio := -1.0
\tvar best_expense := 9223372036854775807
\tfor q in view.research_quotes:
\t\tif not q.can_admit: continue
\t\tvar c: Dictionary = cards_by_id.get(str(q.feature_id),{})
\t\tif c.get("type","") != "feature" or c.get("phase","") not in ["design","alpha"] or int(c.get("scope",0))<=0: continue
\t\tvar expense: int = int(q.down_cents)+int(q.remaining_cents)+rent*int(q.remaining_actions)
\t\tif int(view.cash_cents) < expense+400000: continue
\t\tvar addition := 0
\t\tfor part in c.get("core_contributions",[{"stat":c.primary_stat,"value":c.primary_value},{"stat":c.secondary_stat,"value":c.secondary_value}]):
\t\t\tif STATS.find(str(part.stat)) == weakest: addition += int(part.value)
\t\tif addition <= 0: continue
\t\tvar ratio: float = float(mini(gap,addition))/float(maxi(1,expense))
\t\tif ratio > best_ratio or (ratio == best_ratio and (expense < best_expense or (expense == best_expense and str(q.feature_id)<str(winner.get("feature_id","~"))))):
\t\t\twinner=q
\t\t\tbest_ratio=ratio
\t\t\tbest_expense=expense
\tif winner.is_empty(): return {}
\tcore_pending=str(winner.feature_id)
\tcore_basis={"release":view.releases.size(),"review":review,"weakest":weakest,"gap":gap,"feature_id":core_pending,"ratio":best_ratio,"expense":best_expense}
\treturn {"type":&"admit_research","payload":{"quote":winner}}
'''
    (HERE/'policy.gd').write_text(policy,encoding='utf-8')
    (HERE/'policy.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True),policy.splitlines(True),fromfile='CA1b policy',tofile='QA Core v1 policy')),encoding='utf-8')
    cases=[]
    for pair in PAIRS:
        experiment,specialty,seed=pair.split('-')
        prior=json.loads((PREV/(specialty+'-'+seed+'.json')).read_text())
        config={'schema_version':'1','policy':{'script':'policy.gd','id':'crown-qa-core','version':'1'},'cases':[]}
        for arm in ['control','candidate']:
            c=json.loads(json.dumps(prior['cases'][0]));c['case_id']=arm+'-'+pair;c['max_commands']=320
            c['study']={'pair_id':pair,'arm':arm}
            c['policy']['config'].update({'label':c['case_id'],'extra_hand':experiment=='qa','qa_extension':experiment=='qa' and arm=='candidate','core_target':experiment=='core' and arm=='candidate'})
            config['cases'].append(c);cases.append({'pair':pair,'case':c['case_id'],'experiment':experiment,'arm':arm})
        write(HERE/(pair+'.json'),config)
    write(HERE/'declared-cases.json',cases)
    sys.path.insert(0,str(ROOT/'tools'));import simulator_variant as variants
    meta,base,current,integrity=variants.load_variant(VAR)
    priorbase=json.loads((HERE.parents[1]/'simulators/crown-extra-hand-v1/base-manifest.json').read_text())
    write(HERE/'source-pins.json',{'variant':meta,'candidate_identity':variants.identity(current),'delta':variants.delta(base,current),'from_ca1b_baseline':variants.delta(priorbase,base),'policy_sha256':sha(HERE/'policy.gd'),'plan_sha256':sha(HERE.parents[1]/'CROWN-QA-CORE-PLAN-2026-10-24-v1.md'),'runner_sha256':sha(ROOT/'tools/simulate.py'),'integrity':integrity})
    git=lambda args:subprocess.run(['git',*args],cwd=ROOT,capture_output=True,text=True).stdout
    write(HERE/'intake.json',{'branch':git(['branch','--show-current']).strip(),'head':git(['rev-parse','HEAD']).strip(),'status':git(['status','--short','--untracked-files=no']),'diff_stat':git(['diff','--stat'])})
    print(json.dumps({'cases':len(cases),'baseline':meta['base_identity'],'candidate':variants.identity(current),'delta':variants.delta(base,current)}))

if __name__=='__main__':main()
