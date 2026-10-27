"""Bounded canonical regeneration; original private experiments are read-only."""
from pathlib import Path
import argparse,importlib.util,json,shutil,subprocess,types,sys
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
HOME=Path('C:/Users/64jus/AppData/Local/Temp/pn-sidestreet-canonical-20261023-v5')
GODOT=Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
OLD=ROOT/'docs/codex/threads/contracts/studies'

def main():
    p=argparse.ArgumentParser();p.add_argument('stage',choices=['prefix','first','second','caps','recovery','readiness','zero']);a=p.parse_args()
    spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
    HOME.mkdir(exist_ok=True)
    out=HOME/a.stage;out.mkdir(exist_ok=False)
    inputs=out/'declaration';inputs.mkdir()
    prefix=a.stage=='prefix'
    policy=OLD/('sidestreet-commission-p1-20261023-v1/prefix_policy.gd' if prefix else 'sidestreet-full-delivery-20261023-v1/policy.gd')
    shutil.copy2(policy,inputs/'policy.gd')
    if prefix:
        config=json.loads((OLD/'sidestreet-commission-p1-20261023-v1/prefix-v3.json').read_text(encoding='utf8'))
        config['cases']=config['cases'][:1];config['policy']['script']='policy.gd'
    else:
        def checkpoint(stage,case):return json.loads((HOME/stage/'cases'/case/'studio_checkpoint.json').read_text(encoding='utf8'))
        def case(name,initial,research,commission,target,budget,hands=None):
            return dict(schema_version='1',case_id=name,initial=dict(checkpoint=initial),max_commands=budget,target_release_count=target,telemetry=True,policy=dict(config=dict(label=name,research=research,commission=commission,development=dict(genre='sports',theme='fantasy',name_prefix='Scope Gate',selection='features_first',hands=hands or dict(design=5,alpha=7,beta=6)))))
        if a.stage=='first':
            initial=checkpoint('prefix','sports-1112')
            cases=[case('maps-control',initial,['maps'],True,5,180),case('portfolio-commission',initial,['maps','sprites','general_combat'],True,5,180),case('portfolio-owned',initial,['maps','sprites','general_combat'],False,5,180)]
        elif a.stage=='zero':
            cases=[case('zero-fee',checkpoint('prefix','sports-1112'),[],True,5,120,dict(design=1,alpha=1,beta=1))]
            cases[0]['policy']['config']['development'].update(genre='action',selection='visible_order',name_prefix='Zero Gate')
        elif a.stage=='second':cases=[case('second-commission',checkpoint('first','portfolio-commission'),[],True,6,180)]
        elif a.stage=='caps':cases=[case('repeat-to-cap',checkpoint('second','second-commission'),[],True,11,400)]
        elif a.stage=='recovery':cases=[case('investment-cap',checkpoint('caps','repeat-to-cap'),[],True,12,180)]
        else:cases=[case('investment-cap-readiness',checkpoint('recovery','investment-cap'),[],True,13,180,dict(design=10,alpha=10,beta=10))]
        config=dict(schema_version='1',policy=dict(script='policy.gd',id='sidestreet-full-delivery',version='1'),cases=cases)
    sim.write_json(inputs/'config.json',config)
    assert shutil.disk_usage(ROOT).free>10*1024**3,'10GiB floor'
    def provenance(repo):
        result={'scope':'Tracked status/diff plus full runtime inventory including untracked; avoids slow all-untracked enumeration.'}
        for name,args in [('branch',['branch','--show-current']),('head',['rev-parse','HEAD']),('status',['status','--porcelain=v1','--untracked-files=no']),('diff',['diff','--stat'])]:
            r=subprocess.run(['git',*args],cwd=repo,capture_output=True,timeout=30,check=True);result[name]=r.stdout.decode('utf8',errors='replace')
        result['dirty']=bool(result['status']);return result
    sim.git_provenance=provenance
    report={'stage':a.stage,'pass':False,'declaration':str(HERE/'LEGAL-PLAN.md')}
    try:
        sim.execute_run(types.SimpleNamespace(repo=ROOT,variant=None,config=inputs/'config.json',timeout=600),out,GODOT,sim.isolated_environment(out/'profile'),report)
        report['pass']=True
    except Exception as error:report['error']=str(error)
    finally:sim.write_json(out/'result-summary.json',report)
    print(json.dumps({k:report[k] for k in ['stage','pass','error','results'] if k in report}),flush=True)
    return 0 if report['pass'] else 1
if __name__=='__main__':sys.exit(main())
