"""Fresh source/profile transaction checks; never uses a player save."""
from pathlib import Path
import argparse, importlib.util, json, sys

ROOT = Path(__file__).resolve().parents[4]
GODOT = Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')

def main():
    p = argparse.ArgumentParser()
    p.add_argument('--source', type=Path, default=ROOT/'patch-notes')
    p.add_argument('--output', type=Path, required=True)
    p.add_argument('--expected-red', action='store_true')
    args = p.parse_args()
    spec = importlib.util.spec_from_file_location('sim', ROOT/'tools/simulate.py')
    sim = importlib.util.module_from_spec(spec); spec.loader.exec_module(sim)
    out = args.output.resolve(); out.mkdir(parents=True,exist_ok=False)
    manifest = sim.copy_snapshot(args.source,out/'project')
    sim.write_json(out/'source.json',manifest)
    report = {'pass':False,'expected_red':args.expected_red}
    try:
        sim.run_process('import',[str(GODOT),'--headless','--editor','--path',str(out/'project'),'--import','--quit'],out,sim.isolated_environment(out/'import-profile'),180)
        argv=[str(GODOT),'--headless','--path',str(out/'project'),'--script',str(Path(__file__).with_name('transactions.gd')),'--',str(out/'transactions.json')]
        try:
            sim.run_process('transactions',argv,out,sim.isolated_environment(out/'profile'),120)
            ok=True
        except RuntimeError:
            ok=False
        result=json.loads((out/'transactions.json').read_text(encoding='utf8'))
        report.update(result=result,pass_=ok)
        report['pass'] = (not ok and result['failures']>0) if args.expected_red else ok
        sim.check_snapshot(out/'project',manifest)
    finally:
        sim.write_json(out/'result.json',report)
    print(json.dumps({'pass':report['pass'],'output':str(out)}))
    return 0 if report['pass'] else 1

if __name__=='__main__': sys.exit(main())
