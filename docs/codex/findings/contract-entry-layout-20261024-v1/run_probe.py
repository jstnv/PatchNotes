"""Render actual first Contract entry from legal first-release state, isolated."""
from pathlib import Path
import argparse, importlib.util, json, shutil

ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
GODOT=Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')

def load(name,path):
    spec=importlib.util.spec_from_file_location(name,path)
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    return module

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--output',type=Path,required=True);parser.add_argument('--project',type=Path)
    args=parser.parse_args();out=args.output;out.mkdir(exist_ok=False)
    sim=load('layout_sim',ROOT/'tools/simulate.py')
    load('layout_stream',ROOT/'docs/codex/findings/sidestreet-p2-p3-20261023-v1/stream_process.py').bind(sim)
    project=args.project or out/'project'
    source=sim.source_hashes(project) if args.project else sim.copy_snapshot(ROOT/'patch-notes',project)
    sim.write_json(out/'canonical-source.json',source)
    env=sim.isolated_environment(out/'profile')
    frozen=source if args.project else sim.import_project(GODOT,project,out,env,180)
    shutil.copy2(HERE/'probe.gd',out/'probe-source.gd')
    try:
        result=sim.run_process('probe',[str(GODOT),'--rendering-method','gl_compatibility','--path',str(project),'--script',str(HERE/'probe.gd'),'--',str(out)],out,env,120)
        sim.write_json(out/'result.json',{'pass':True,'run':result,'probe':json.loads((out/'probe.json').read_text(encoding='utf8')),'canonical_unchanged':source==sim.source_hashes(ROOT/'patch-notes')})
    finally: sim.check_snapshot(project,frozen)
    print((out/'result.json').read_text(encoding='utf8'))

if __name__=='__main__':main()
