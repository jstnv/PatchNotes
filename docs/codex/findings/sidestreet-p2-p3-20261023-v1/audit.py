from pathlib import Path
import argparse,importlib.util,json,types
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
HOME=Path('C:/Users/64jus/AppData/Local/Temp/pn-sidestreet-canonical-20261023-v5')
GODOT=Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
def main():
    p=argparse.ArgumentParser();p.add_argument('--replays',action='store_true');a=p.parse_args()
    spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
    out=HOME/('replays' if a.replays else 'audits');out.mkdir(exist_ok=False)
    report=[]
    if a.replays:
        for stage,case in [('prefix','sports-1112'),('first','portfolio-commission'),('second','second-commission'),('caps','repeat-to-cap'),('recovery','investment-cap'),('readiness','investment-cap-readiness')]:
            job=out/stage;job.mkdir()
            result={}
            try:sim.execute_replay(types.SimpleNamespace(bundle=HOME/stage,case=case,timeout=600),job,GODOT,sim.isolated_environment(job/'profile'),result);result['pass']=True
            except Exception as error:result.update({'pass':False,'error':str(error)})
            sim.write_json(job/'result.json',result);report.append({'name':stage,'pass':result['pass']});print(json.dumps(report[-1]),flush=True)
            if not result['pass']:break
    else:
        old=ROOT/'docs/codex/threads/contracts/studies'
        project=HOME/'prefix/project';manifest=sim.source_hashes(project)
        script=old/'sidestreet-commission-p1-20261023-v1'
        jobs=[('arithmetic',script/'arithmetic.gd',[])]
        for stage,case in [('first','maps-control'),('first','portfolio-commission'),('second','second-commission'),('zero','zero-fee')]:jobs.append((case,script/'audit.gd',[HOME/stage/'cases'/case/'studio_checkpoint.json',out/(case+'.json')]))
        jobs.extend([('quote-boundary',script/'quote_boundary.gd',[HOME/'prefix/cases/sports-1112/studio_checkpoint.json',out/'quote-boundary.json']),('callback',script/'callback.gd',[HOME/'prefix/cases/sports-1112/studio_checkpoint.json'])])
        for stage,case,count in [('caps','repeat-to-cap',7),('recovery','investment-cap',8),('readiness','investment-cap-readiness',9)]:jobs.append((stage,old/'sidestreet-full-delivery-20261023-v1/gate_audit_v5.gd',[HOME/stage/'cases'/case/'studio_checkpoint.json',out/(stage+'.json'),count]))
        for name,source,args in jobs:
            env=sim.isolated_environment(out/(name+'-profile'))
            try:sim.run_process(name,[str(GODOT),'--headless','--path',str(project),'--script',str(source),'--',*map(str,args)],out,env,600);ok=True
            except Exception as error:print(str(error),flush=True);ok=False
            report.append({'name':name,'pass':ok,'script_sha256':sim.sha(source)});print(json.dumps(report[-1]),flush=True)
        sim.check_snapshot(project,manifest)
    sim.write_json(out/'summary.json',report)
    return 0 if all(r['pass'] for r in report) else 1
if __name__=='__main__':raise SystemExit(main())
