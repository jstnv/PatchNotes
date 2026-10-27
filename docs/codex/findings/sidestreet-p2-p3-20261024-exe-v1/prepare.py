from pathlib import Path
import importlib.util,json,shutil
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
HOME=Path('C:/Users/64jus/AppData/Local/Temp/pn-p4-execution-20261024-v1')
def load(name,path):
    s=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
def main():
    sim=load('sim',ROOT/'tools/simulate.py');load('stream',ROOT/'docs/codex/findings/sidestreet-p2-p3-20261023-v1/stream_process.py').bind(sim)
    out=HOME/'p2-p3-route-v2';out.mkdir(exist_ok=False)
    manifest=sim.read_json(HOME/'p2-p3-export/build-manifest.json');pack=Path(manifest['workspace'])/'demo/Patch Notes Demo.pck'
    policy=ROOT/'docs/codex/threads/contracts/studies'
    prefix=policy/'sidestreet-commission-p1-20261023-v1/prefix_policy.gd';full=policy/'sidestreet-full-delivery-20261023-v1/policy.gd'
    for path in [HERE/'prepare.gd',prefix,full]:shutil.copy2(path,out/path.name)
    sim.write_json(out/'inputs.json',{str(p):sim.sha(p) for p in [pack,HERE/'prepare.gd',prefix,full]})
    sim.run_process('prepare',['C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe','--headless','--main-pack',str(pack),'--script',str(HERE/'prepare.gd'),'--',str(out),str(prefix),str(full)],out,sim.isolated_environment(out/'profile'),300)
    print((out/'result.json').read_text(encoding='utf8'))
if __name__=='__main__':main()
