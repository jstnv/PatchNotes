"""Isolated, source-pinned usability checks. Never touches player profiles."""
from pathlib import Path
import importlib.util, json, os, subprocess, sys

ROOT = Path(__file__).resolve().parents[4]
HOME = Path('C:/Users/64jus/AppData/Local/Temp/pn-usability-20261024-v1')
PYTHON = sys.executable
GODOT = Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
spec = importlib.util.spec_from_file_location('sim', ROOT/'tools/simulate.py')
sim = importlib.util.module_from_spec(spec); spec.loader.exec_module(sim)

def freeze():
    HOME.mkdir(exist_ok=False)
    source = sim.copy_snapshot(ROOT/'patch-notes', HOME/'baseline/project')
    sim.write_json(HOME/'baseline/source.json', source)
    sim.write_json(HOME/'baseline/git.json', {
        'head': subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
        'branch': subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),
        'status': subprocess.check_output(['git','status','--porcelain=v1'],cwd=ROOT,text=True)})

def run(name, script, native=False, input_path=None):
    native = native in (True,'native','true','True')
    out=HOME/name; out.mkdir(exist_ok=False)
    before=sim.copy_snapshot(ROOT/'patch-notes',out/'project')
    if name=='bank-red-v2':
        import shutil
        for rel in ['scripts/finance/bank_loan.gd','scripts/finance/studio_finance_ledger.gd']:
            shutil.copy2(HOME/'baseline/project'/rel,out/'project'/rel)
        sim.write_json(out/'red-instrumentation.json',{'scope':'Restore the two exact baseline Bank implementation files, retain only current verifier/frozen-reader dependencies.'})
        before=sim.source_hashes(out/'project')
    sim.write_json(out/'source.json',before)
    env=sim.isolated_environment(out/'profile'); env['PN_CHECKPOINT_TEST_PORT']='47734'
    env['PN_USABILITY_PREVIOUS_ROOT']='C:/Users/64jus/AppData/Local/Temp/pn-p4-execution-20261024-v1'
    sim.import_project(GODOT,out/'project',out,env,180)
    command=[str(GODOT),'--path',str(out/'project')]
    if not native: command+=['--headless']
    if not script.startswith('res://'):
        import shutil
        harness=out/'harness.gd';shutil.copy2(Path(script),harness);script=str(harness)
        sim.write_json(out/'harness-source.json',{'sha256':sim.sha(harness)})
    command+=['--script',script,'--','--out='+str(out)]
    if input_path: command+=['--input='+input_path]
    with (out/'run.log').open('w',encoding='utf8') as log:
        p=subprocess.Popen(command,cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT)
        import time
        start=time.monotonic()
        while p.poll() is None:
            if time.monotonic()-start>150 or 'SCRIPT ERROR' in (out/'run.log').read_text(encoding='utf8',errors='replace'):
                p.kill(); break
            time.sleep(.25)
        p.wait()
    print((out/'run.log').read_text(encoding='utf8',errors='replace'))
    return p.returncode

if __name__=='__main__':
    if sys.argv[1]=='freeze': freeze()
    else: raise SystemExit(run(*sys.argv[1:]))
