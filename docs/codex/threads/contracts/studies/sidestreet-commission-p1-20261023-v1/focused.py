from pathlib import Path
import sys,json
from paths import bundle as selected_bundle
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1]
sys.path.insert(0,str(R/'tools'));import simulate as sim
mode=sys.argv[1];tag=sys.argv[2]
out=H/f'{mode}-{tag}';out.mkdir()
bundle=T/f'sims/sidestreet-commission-p1-prefix-20261023-{tag}'
g='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
jobs=[]
if mode=='callback':
    jobs=[('callback',H/'callback.gd',[str(bundle/'cases/sports-1112/studio_checkpoint.json')])]
    if tag!='v1': jobs.append(('quote-boundary',H/'quote_boundary.gd',[str(bundle/'cases/sports-1112/studio_checkpoint.json'),str(out/'quote-boundary.json')]))
elif mode=='renamed-red': jobs=[('renamed',H/'renamed_receipt.gd',[])]
elif mode=='preflight':
    jobs=[('arithmetic',H/'arithmetic.gd',[]),('orphan',H/'orphan_red.gd',[]),('renamed',H/'renamed_receipt.gd',[]),('challenge-matrix','res://scripts/debug/verify_contract_challenge_matrix.gd',[]),('p1-ledger','res://scripts/debug/verify_publisher_relationships.gd',[])]
elif mode=='focused':
    bundle=selected_bundle('delivery',tag)
    for case in ['long-commission','short-commission','medium-commission']:
        jobs.append((case+'-audit',H/'audit.gd',[str(bundle/'cases'/case/'studio_checkpoint.json'),str(out/(case+'-audit.json'))]))
    jobs.append(('observer',H/'observer.gd',[str(bundle/'cases/long-commission/case.variant.json'),str(bundle/'cases/long-commission/replay.tape.json'),str(out/'observer.json')]))
elif mode=='continued-audit':
    bundle=T/f'sims/sidestreet-commission-p1-continue-20261023-{tag}'
    jobs=[('rights-after-sales',H/'audit.gd',[str(bundle/'cases/long-commission/studio_checkpoint.json'),str(out/'rights-after-sales.json')])]
else:raise ValueError(mode)
manifest=sim.source_hashes(bundle/'project')
sim.write_json(out/'source-manifest.json',manifest)
results=[]
for name,script,args in jobs:
    env=sim.isolated_environment(out/name/'profile')
    env['PN_CARD_FRAME_OUTPUT']=str(out/(name+'-evidence.json'))
    argv=[g,'--headless','--path',str(bundle/'project'),'--script',str(script),'--',*args]
    try:sim.run_process(name,argv,out,env,600);ok=True
    except RuntimeError as e:print(e,flush=True);ok=False
    results.append(dict(name=name,ok=ok));print(results[-1],flush=True)
assert sim.source_hashes(bundle/'project')==manifest
sim.write_json(out/'results.json',results)
if tag=='v1' and mode=='callback':
    assert not results[0]['ok'] and 'CALLBACK_QUOTE_FROZEN=false' in (out/'callback.log').read_text()
    print('Expected callback mutation RED confirmed')
elif mode=='renamed-red':
    assert not results[0]['ok'] and 'RENAMED_RECEIPT_REJECTED=false' in (out/'renamed.log').read_text()
    print('Expected renamed receipt RED confirmed')
else:sys.exit(0 if all(x['ok'] for x in results) else 1)
