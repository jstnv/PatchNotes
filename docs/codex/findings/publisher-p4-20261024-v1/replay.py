"""Independent OS process/profile replay of a recorded exact campaign tape."""
from pathlib import Path
import argparse,importlib.util,json,shutil
ROOT=Path(__file__).resolve().parents[4]
HOME=Path('C:/Users/64jus/AppData/Local/Temp/pn-p4-execution-20261024-v1')
GODOT='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
def main():
    p=argparse.ArgumentParser();p.add_argument('route',type=Path);p.add_argument('--compiled',action='store_true');p.add_argument('--output-leaf',default='fresh-process');a=p.parse_args()
    sim=module('sim',ROOT/'tools/simulate.py');module('stream',ROOT/'docs/codex/findings/sidestreet-p2-p3-20261023-v1/stream_process.py').bind(sim)
    route=a.route.resolve();out=route/a.output_leaf;out.mkdir(exist_ok=False)
    if a.compiled:
        manifest=sim.read_json(HOME/'p4-build-v1/p2-p3-export/build-manifest.json');pack=Path(manifest['workspace'])/'demo/Patch Notes Demo.pck';launch=['--main-pack',str(pack)]
    else:launch=['--path',str(route/'project')]
    command=[GODOT,'--headless',*launch,'--script','res://scripts/debug/campaign_replay_cli.gd','--','--recipe='+str(route/'recipe.json'),'--tape='+str(route/'route.tape.json'),'--output='+str(out/'replay-result.json')]
    if a.compiled:
        bootstrap=out/'bootstrap.gd';shutil.copy2(Path(__file__).with_name('fresh_replay.gd'),bootstrap)
        command=[GODOT,'--headless',*launch,'--script',str(bootstrap),'--',str(route/'recipe.json'),str(route/'route.tape.json'),str(out/'replay-result.json')]
    sim.write_json(out/'inputs.json',{str(path):sim.sha(path) for path in [route/'recipe.json',route/'route.tape.json']})
    sim.run_process('replay',command,out,sim.isolated_environment(out/'profile'),600)
    result=sim.read_json(out/'replay-result.json');assert result['ok'],result
    print(json.dumps({'ok':result['ok'],'steps':len(result.get('steps',[])),'final_state':result.get('final_state')}),flush=True)
if __name__=='__main__':main()
