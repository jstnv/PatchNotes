"""Run a source-pinned external check against an already isolated project."""
from pathlib import Path
import argparse,importlib.util,shutil
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
def load(name,path):
    spec=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
def main():
    p=argparse.ArgumentParser();p.add_argument('--project',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--script',type=Path,required=True);p.add_argument('args',nargs='*');a=p.parse_args()
    a.output.mkdir(exist_ok=False)
    sim=load('sim',ROOT/'tools/simulate.py');load('stream',ROOT/'docs/codex/findings/sidestreet-p2-p3-20261023-v1/stream_process.py').bind(sim)
    source=sim.source_hashes(a.project);sim.write_json(a.output/'source.json',source);shutil.copy2(a.script,a.output/'test-source.gd')
    try:sim.run_process('check',['C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe','--headless','--path',str(a.project),'--script',str(a.script),'--',*a.args,str(a.output/'result.json')],a.output,sim.isolated_environment(a.output/'profile'),120)
    finally:sim.check_snapshot(a.project,source)
if __name__=='__main__':main()
