"""Bounded P4 checks on fresh isolated source/profile snapshots."""
from pathlib import Path
import argparse, importlib.util, json, subprocess, time, shutil
ROOT=Path(__file__).resolve().parents[4]
HOME=Path('C:/Users/64jus/AppData/Local/Temp/pn-p4-execution-20261024-v1')
GODOT=Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
def main():
    parser=argparse.ArgumentParser();parser.add_argument('label');parser.add_argument('--tests',nargs='+',default=['verify_publisher_support']);parser.add_argument('--route',action='store_true');parser.add_argument('--world',action='store_true');parser.add_argument('--probe',type=Path);parser.add_argument('--input',type=Path);parser.add_argument('--native',action='store_true');a=parser.parse_args()
    sim=module('sim',ROOT/'tools/simulate.py');out=HOME/a.label;out.mkdir(exist_ok=False)
    before=sim.copy_snapshot(ROOT/'patch-notes',out/'project');sim.write_json(out/'source.json',before)
    frozen=sim.import_project(GODOT,out/'project',out,sim.isolated_environment(out/'import-profile'),180)
    rows=[]
    for name in a.tests:
        cmd=[str(GODOT),'--headless','--path',str(out/'project'),'--script','res://scripts/debug/'+name+'.gd']
        if a.route:
            cmd=[str(GODOT),'--headless','--path',str(out/'project'),'--script',str(Path(__file__).parent/'route.gd'),'--',str(out),str(HOME/'p2-p3-short-names-v2')]
        elif a.world:
            study=ROOT/'docs/codex/threads/contracts/studies'
            cmd=[str(GODOT),'--headless','--path',str(out/'project'),'--script',str(Path(__file__).parent/'world.gd'),'--',str(study/'sidestreet-commission-p1-20261023-v1/prefix_policy.gd'),str(study/'sidestreet-full-delivery-20261023-v1/policy.gd'),str(out/'world-result.json')]
        elif a.probe:
            cmd=[str(GODOT),'--headless','--path',str(out/'project'),'--script',str(a.probe.resolve()),'--',str(out),str(a.input.resolve())]
        if a.route or a.world or a.probe:
            original=Path(cmd[cmd.index('--script')+1]);frozen_harness=out/'harness.gd'
            shutil.copy2(original,frozen_harness);cmd[cmd.index('--script')+1]=str(frozen_harness)
            sim.write_json(out/'harness-source.json',{'original_path':str(original),'frozen_path':str(frozen_harness),'sha256':sim.sha(frozen_harness)})
        if a.native: cmd.remove('--headless')
        log=out/(name+'.log')
        with log.open('wb') as f:
            environment=sim.isolated_environment(out/(name+'-profile'))
            environment['PN_CARD_FRAME_OUTPUT']=str(out/'native')
            child=subprocess.Popen(cmd,env=environment,cwd=out,stdout=f,stderr=subprocess.STDOUT)
            start=time.monotonic();reason=''
            while child.poll() is None:
                content=log.read_text(encoding='utf8',errors='replace')
                if time.monotonic()-start>600 or 'SCRIPT ERROR' in content:
                    reason='timeout' if time.monotonic()-start>600 else 'SCRIPT ERROR';child.kill();break
                time.sleep(.25)
            child.wait()
        content=log.read_text(encoding='utf8',errors='replace')
        errors=[x for x in content.splitlines() if ('SCRIPT ERROR' in x or x.startswith('ERROR:') or 'FAIL:' in x) and 'root certificate store' not in x]
        rows.append({'name':name,'command':cmd,'exit':child.returncode,'errors':errors,'termination':reason,'pass':child.returncode==0 and not errors})
        print(json.dumps(rows[-1]),flush=True)
    sim.check_snapshot(out/'project',frozen)
    result={'checks':rows,'canonical_unchanged':sim.source_hashes(ROOT/'patch-notes')==before,'release_ready':False}
    result['pass']=all(x['pass'] for x in rows) and result['canonical_unchanged'];sim.write_json(out/'result.json',result)
    return 0 if result['pass'] else 1
if __name__=='__main__':raise SystemExit(main())
