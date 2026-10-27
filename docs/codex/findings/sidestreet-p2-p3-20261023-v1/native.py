from pathlib import Path
import argparse,importlib.util,json,shutil
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
HOME=Path('C:/Users/64jus/AppData/Local/Temp/pn-sidestreet-canonical-20261023-v5')
def main():
    p=argparse.ArgumentParser();p.add_argument('--width',type=int,required=True);p.add_argument('--tag',required=True);p.add_argument('--project',type=Path);p.add_argument('--exe',type=Path);a=p.parse_args()
    spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
    from stream_process import bind
    bind(sim)
    out=HOME/a.tag;out.mkdir(exist_ok=False)
    project=a.project or HOME/'prefix/project'
    source=sim.source_hashes(project)
    policies=ROOT/'docs/codex/threads/contracts/studies'
    args=[str(out),str(a.width),str(policies/'sidestreet-commission-p1-20261023-v1/prefix_policy.gd'),str(policies/'sidestreet-full-delivery-20261023-v1/policy.gd')]
    script=(HERE/'native.gd').read_text(encoding='utf8')
    if a.exe:
        # Debug harness stays external; execute production scripts from the
        # audited release PCK. Replace only its historical bootstrap adapter.
        parent=(ROOT/'patch-notes/scripts/debug/verify_campaign_live_parity.gd').read_text(encoding='utf8')
        parent=parent.replace('res://scripts/debug/campaign_replay_cli.gd','res://scripts/simulation/run_factory.gd')
        parent=parent.replace('recipe,root.get_node("CardDatabase")','recipe,root.get_node("CardDatabase").get_development_catalog()')
        (out/'native-base.gd').write_text(parent,encoding='utf8')
        script=script.replace('res://scripts/debug/verify_campaign_live_parity.gd',(out/'native-base.gd').as_posix())
        sim.write_json(out/'build-artifacts.json',{p.name:sim.sha(p) for p in [a.exe,a.exe.with_suffix('.pck')]})
    (out/'native-script.gd').write_text(script,encoding='utf8')
    env=sim.isolated_environment(out/'profile');env['PN_CARD_FRAME_OUTPUT']=str(out/'frame.json')
    engine='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
    argv=[engine,'--max-fps','60',*(['--main-pack',str(a.exe.with_suffix('.pck'))] if a.exe else ['--path',str(project)]),'--script',str(out/'native-script.gd'),'--',*args]
    sim.write_json(out/'source.json',source)
    try:sim.run_process('native',argv,out,env,600)
    finally:sim.check_snapshot(project,source)
    print(json.dumps({'output':str(out),'result':json.loads((out/'result.json').read_text(encoding='utf8')).get('failures')}))
if __name__=='__main__':main()
