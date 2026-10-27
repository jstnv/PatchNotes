from pathlib import Path
import argparse,importlib.util,json
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
HOME=Path('C:/Users/64jus/AppData/Local/Temp/pn-sidestreet-canonical-20261023-v5')
def main():
    p=argparse.ArgumentParser();p.add_argument('--tag',required=True);p.add_argument('--fixture',required=True,type=Path);p.add_argument('--exe',type=Path);a=p.parse_args()
    spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
    from stream_process import bind
    bind(sim)
    out=HOME/a.tag;out.mkdir(exist_ok=False)
    project=HOME/'prefix/project';source=sim.source_hashes(project)
    engine='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
    sim.write_json(out/'fixture.json',{'path':str(a.fixture),'sha256':sim.sha(a.fixture)})
    sim.run_process('disk',[engine,'--headless',*(['--main-pack',str(a.exe.with_suffix('.pck'))] if a.exe else ['--path',str(project)]),'--script',str(HERE/'disk.gd'),'--',str(a.fixture),str(out/'saves'),str(out/'result.json')],out,sim.isolated_environment(out/'profile'),180)
    sim.check_snapshot(project,source)
    sim.write_json(out/'source.json',source)
    print(json.dumps(sim.read_json(out/'result.json')),flush=True)
if __name__=='__main__':main()
