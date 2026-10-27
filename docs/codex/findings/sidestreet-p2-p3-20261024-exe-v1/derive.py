from pathlib import Path
import argparse,importlib.util,shutil
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
HOME=Path('C:/Users/64jus/AppData/Local/Temp/pn-p4-execution-20261024-v1')
def load(name,path):
    s=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--campaign',action='store_true');args=parser.parse_args()
    sim=load('sim',ROOT/'tools/simulate.py');load('stream',ROOT/'docs/codex/findings/sidestreet-p2-p3-20261023-v1/stream_process.py').bind(sim)
    out=HOME/('p2-p3-later-campaign-v2' if args.campaign else 'p2-p3-short-names-v3');out.mkdir(exist_ok=False)
    pack=Path(sim.read_json(HOME/'p2-p3-export/build-manifest.json')['workspace'])/'demo/Patch Notes Demo.pck'
    shutil.copy2(HERE/'derive.gd',out/'test-source.gd')
    sim.write_json(out/'inputs.json',{str(p):sim.sha(p) for p in [pack,HERE/'derive.gd',HOME/'p2-p3-route-v2/route.tape.json']})
    sim.run_process('derive',['C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe','--headless','--main-pack',str(pack),'--script',str(HERE/'derive.gd'),'--',str(HOME/'p2-p3-route-v2'),str(out),*(['campaign'] if args.campaign else [])],out,sim.isolated_environment(out/'profile'),300)
    print((out/'result.json').read_text(encoding='utf8'))
if __name__=='__main__':main()
