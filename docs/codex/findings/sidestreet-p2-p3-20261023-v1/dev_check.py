"""Mutable isolated iteration bed. Final acceptance uses a fresh frozen copy."""
from pathlib import Path
import argparse, importlib.util, shutil, json
ROOT=Path(__file__).resolve().parents[4]
def main():
    p=argparse.ArgumentParser();p.add_argument('--tag',required=True);p.add_argument('--tests',nargs='*',default=[]);a=p.parse_args()
    spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
    home=Path('C:/Users/64jus/AppData/Local/Temp/pn-sidestreet-adoption-20261023-dev')
    project=home/'project'
    if not project.exists():sim.copy_snapshot(ROOT/'patch-notes',project)
    else:
        for relative,source in sim.source_files(ROOT/'patch-notes').items():
            destination=project/relative
            if not destination.exists() or sim.sha(source)!=sim.sha(destination):
                destination.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,destination)
    out=home/a.tag;out.mkdir(exist_ok=False)
    sim.write_json(out/'source.json',sim.source_hashes(project))
    g='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
    sim.run_process('import',[g,'--headless','--editor','--path',str(project),'--import','--quit'],out,sim.isolated_environment(home/'import-profile'),180)
    tests=[('transactions',str(Path(__file__).with_name('transactions.gd')))] + [(t,'res://scripts/debug/'+t+'.gd') for t in a.tests]
    results=[]
    for name,script in tests:
        env=sim.isolated_environment(out/(name+'-profile'));env['PN_CARD_FRAME_OUTPUT']=str(out/(name+'-artifact.json'))
        try:
            sim.run_process(name,[g,'--path',str(project),'--script',script,'--',str(out/(name+'.json'))],out,env,180);ok=True
        except RuntimeError as e:print(str(e),flush=True);ok=False
        results.append({'name':name,'pass':ok});print(json.dumps(results[-1]),flush=True)
    sim.write_json(out/'result.json',results)
    return 0 if all(r['pass'] for r in results) else 1
if __name__=='__main__':raise SystemExit(main())
