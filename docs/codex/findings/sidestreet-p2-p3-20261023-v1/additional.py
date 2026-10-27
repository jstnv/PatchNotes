from pathlib import Path
import argparse,importlib.util,json,shutil
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
TASK=Path('C:/Users/64jus/AppData/Local/Temp/pn-sidestreet-canonical-20261023-v5')
def main():
    p=argparse.ArgumentParser();p.add_argument('mode',choices=['boundaries','world','p1_matrix','transactions']);p.add_argument('--tag',required=True);p.add_argument('--exe',type=Path);a=p.parse_args()
    spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
    from stream_process import bind
    bind(sim)
    out=TASK/a.tag;out.mkdir(exist_ok=False);project=TASK/'prefix/project';source=sim.source_hashes(project)
    if a.mode=='boundaries':args=[str(TASK),str(out/'result.json')]
    elif a.mode=='p1_matrix':args=[str(ROOT/'docs/codex/findings/publisher-p1-20261023-v1'),str(out/'result.json')]
    elif a.mode=='transactions':args=[str(out/'result.json')]
    else:
        old=ROOT/'docs/codex/threads/contracts/studies'
        args=[str(old/'sidestreet-commission-p1-20261023-v1/prefix_policy.gd'),str(old/'sidestreet-full-delivery-20261023-v1/policy.gd'),str(out/'result.json')]
    env=sim.isolated_environment(out/'profile')
    sim.write_json(out/'source.json',source)
    script=HERE/(a.mode+'.gd')
    shutil.copy2(script,out/'test-source.gd')
    sim.write_json(out/'test.json',{'script_sha256':sim.sha(script),'scope':'Isolated focused checks; explicit world policy adapter is a test fixture, not activated AI behavior.'})
    engine='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
    if a.exe:sim.write_json(out/'artifacts.json',{p.name:sim.sha(p) for p in [a.exe,a.exe.with_suffix('.pck')]})
    try:sim.run_process(a.mode,[engine,'--headless',*(['--main-pack',str(a.exe.with_suffix('.pck'))] if a.exe else ['--path',str(project)]),'--script',str(script),'--',*args],out,env,600)
    finally:sim.check_snapshot(project,source)
    print(json.dumps({'mode':a.mode,'failures':json.loads((out/'result.json').read_text(encoding='utf8'))['failures']}))
if __name__=='__main__':main()
