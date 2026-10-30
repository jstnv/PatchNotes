from pathlib import Path
import json,sys,subprocess
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1]
sys.path.insert(0,str(R/'tools'));import simulate as sim
G='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
stage=sys.argv[1];kind=sys.argv[2];case={'first':'portfolio-commission','second':'second-commission','caps':'repeat-to-cap','recovery':'investment-cap','readiness':'investment-cap-readiness'}[stage]
B=T/f'sims/sidestreet-full-delivery-{stage}-20261023-v1'
out=H/f'{stage}-{kind}'
out.mkdir()
if kind.startswith('audit'):
    before=sim.source_hashes(B/'project')
    jobs=[('gate',H/('gate_audit_v5.gd' if stage=='readiness' else 'gate_audit_v4.gd' if stage in ['caps','recovery'] else 'gate_audit_v2.gd'),[str(B/'cases'/case/'studio_checkpoint.json'),str(out/'gate.json'),str({'first':1,'second':2,'caps':7,'recovery':8,'readiness':9}[stage])])]
    if stage=='caps':jobs.append(('p1-ledger','res://scripts/debug/verify_publisher_relationships.gd',[]))
    old=H.parent/'sidestreet-commission-p1-20261023-v1'
    if stage=='first' and kind=='audit':jobs+=[('strict-save',old/'audit.gd',[str(B/'cases'/case/'studio_checkpoint.json'),str(out/'strict-save.json')]),('observer',old/'observer.gd',[str(B/'cases'/case/'case.variant.json'),str(B/'cases'/case/'replay.tape.json'),str(out/'observer.json')])]
    results=[]
    for name,script,args in jobs:
        argv=[G,'--headless','--path',str(B/'project'),'--script',str(script),'--',*args]
        try:sim.run_process(name,argv,out,sim.isolated_environment(out/name/'profile'),600);ok=True
        except RuntimeError as e:print(e);ok=False
        results.append(dict(name=name,ok=ok));print(results[-1],flush=True)
    assert sim.source_hashes(B/'project')==before
    sim.write_json(out/'results.json',results)
    raise SystemExit(not all(x['ok'] for x in results))
elif kind=='replay':
    argv=[sys.executable,str(R/'tools/simulate.py'),'replay','--bundle',str(B),'--case',case,'--output',str(T/f'sims/sidestreet-full-delivery-{stage}-replay-20261023-v1'),'--godot',G,'--timeout','600']
    p=subprocess.run(argv,cwd=R,capture_output=True,text=True)
    sim.write_json(out/'command.json',dict(argv=argv,exit=p.returncode,stdout=p.stdout,stderr=p.stderr))
    if p.returncode==0:
        result=json.loads(p.stdout)
        print(json.dumps(dict(ok=result['ok'],stage=stage,steps=len(result['replay']['steps']),telemetry_verified=result['replay'].get('telemetry_verified'))))
    else:print(p.stdout);print(p.stderr)
    raise SystemExit(p.returncode)
else:raise ValueError(kind)
