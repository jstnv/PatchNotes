"""Never write to the original save or use the production checkpoint lease."""
from pathlib import Path
import argparse,importlib.util,json,shutil
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
HOME=Path('C:/Users/64jus/AppData/Local/Temp/pn-sidestreet-canonical-20261023-v5')
def main():
    p=argparse.ArgumentParser();p.add_argument('--tag',required=True);p.add_argument('--save',required=True,type=Path);p.add_argument('--exe',type=Path);p.add_argument('--width',type=int,default=1152);a=p.parse_args()
    spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
    from stream_process import bind
    bind(sim)
    out=HOME/a.tag;out.mkdir(exist_ok=False)
    shutil.copy2(HERE/'cold.gd',out/'test-source.gd')
    env=sim.isolated_environment(out/'profile')
    name='Patch Notes Demo' if a.exe else 'Patch Notes'
    destination=Path(env['APPDATA'])/'Godot/app_userdata'/name/'saves/studio'/a.save.name
    destination.parent.mkdir(parents=True,exist_ok=False);shutil.copy2(a.save,destination)
    before=sim.sha(a.save);assert before==sim.sha(destination)
    sim.write_json(out/'original.json',{'source':str(a.save),'destination':str(destination),'sha256':before})
    project=HOME/'prefix/project';source=sim.source_hashes(project)
    sim.write_json(out/'source.json',source)
    engine='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
    sim.run_process('cold',[engine,'--max-fps','60',*(['--main-pack',str(a.exe.with_suffix('.pck'))] if a.exe else ['--path',str(project)]),'--script',str(HERE/'cold.gd'),'--',str(out/'result.json'),str(a.width)],out,env,180)
    assert sim.sha(a.save)==before and sim.sha(destination)==before,'Original generation changed'
    sim.check_snapshot(project,source)
    if a.exe:sim.write_json(out/'artifacts.json',{p.name:sim.sha(p) for p in [a.exe,a.exe.with_suffix('.pck')]})
    print(json.dumps({'tag':a.tag,'failures':sim.read_json(out/'result.json')['failures']}),flush=True)
if __name__=='__main__':main()
