from pathlib import Path
import sys,json
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1]
sys.path.insert(0,str(R/'tools'));import simulate as sim
G='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
stage=sys.argv[1];case=sys.argv[2];count=sys.argv[3];label=sys.argv[4] if len(sys.argv)>4 else 'audit'
B=T/f'sims/publisher-renewal-{stage}-20261023-v1';out=H/f'{stage}-{label}';out.mkdir()
before=sim.source_hashes(B/'project')
argv=[G,'--headless','--path',str(B/'project'),'--script',str(H/'audit.gd'),'--',str(B/'cases'/case/'studio_checkpoint.json'),str(out/'checks.json'),count]
if stage=='third':
    pairs=[]
    links=[('prefix2','sports-1112-two-full-briefs-r20','commission2','sports-1112-maps-commission'),('commission2','sports-1112-maps-commission','support','sports-1112-support'),('support','sports-1112-support','repeat','second-support'),('repeat','second-support','cold','second-assessment'),('cold','second-assessment','recovery','recovery-commission'),('recovery','recovery-commission','third','third-support')]
    for a,ac,b,bc in links:
        prior=T/f'sims/publisher-renewal-{a}-20261023-v1/cases'/ac
        following=T/f'sims/publisher-renewal-{b}-20261023-v1/cases'/bc
        pairs.append({'stage':b,'before':str(prior/'final_state.variant.json'),'after':str(following/'case.variant.json'),'checkpoint':str(prior/'studio_checkpoint.json')})
    sim.write_json(out/'cold-pairs.json',pairs)
    argv.append(str(out/'cold-pairs.json'))
try:sim.run_process('audit',argv,out,sim.isolated_environment(out/'profile'),180);ok=True
except RuntimeError as e:print(str(e));ok=False
assert sim.source_hashes(B/'project')==before
sim.write_json(out/'result.json',{'ok':ok,'source_unchanged':True})
if (out/'checks.json').exists():
    result=json.loads((out/'checks.json').read_text());print(json.dumps({'checks':len(result['checks']),'failures':result['failures']}))
raise SystemExit(not ok)
