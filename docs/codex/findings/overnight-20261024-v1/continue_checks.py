"""Explicit source-fenced continuation of the interrupted fresh matrix."""
from pathlib import Path
import importlib.util,json,sys
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
TEMP=Path('C:/Users/64jus/AppData/Local/Temp')
def load(name,path):
    spec=importlib.util.spec_from_file_location(name,path);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module
def read(path):return json.loads(path.read_text(encoding='utf8'))
def main():
    sim=load('continuation_sim',ROOT/'tools/simulate.py')
    gate=load('continuation_gate',ROOT/'tools/release_gate.py')
    first=TEMP/'pn-overnight-20261024-v1'
    affected=TEMP/'pn-overnight-20261024-affected-v1'
    out=TEMP/'pn-overnight-20261024-continuation-v1'
    original=read(first/'canonical-source.json');current=sim.source_hashes(ROOT/'patch-notes')
    delta={p for p in set(original)|set(current) if original.get(p)!=current.get(p)}
    assert delta=={'scripts/debug/verify_design_phase.gd','scripts/debug/verify_cult_following.gd'},delta
    fixed=read(affected/'result.json');assert fixed['pass'] and len(fixed['checks'])==8
    fixed_source=read(affected/'canonical-source.json')
    assert {p for p in set(fixed_source)|set(current) if fixed_source.get(p)!=current.get(p)}=={'scripts/debug/verify_cult_following.gd'}
    names={name for name,path in gate.verifier_jobs()}
    replaced={row['name'] for row in fixed['checks']}
    retained={row['name'] for row in read(first/'result.json')['checks'] if row['pass']}-replaced
    assert 'verify_cult_following' not in retained
    pending=sorted(names-retained-replaced)
    assert retained.isdisjoint(replaced) and len(names)==len(retained)+len(replaced)+len(pending)
    selection={'first':str(first),'affected':str(affected),'continuation':str(out),'total':len(names),'retained_unchanged':sorted(retained),'retained_fixed_dependency_closure':sorted(replaced),'pending':pending,'only_project_changes':sorted(delta),'source_fence':current,'limits':'First run interrupted on missing external education fixtures; those input fixtures are copied and hashed in the continuation. Original failed logs remain. Only test-only files changed; current gameplay bytes match the original matrix.'}
    sim.write_json(HERE/'selection.json',selection)
    print(json.dumps({k:len(v) if isinstance(v,list) else v for k,v in selection.items() if k not in {'source_fence'}}),flush=True)
    runner=load('continuation_runner',HERE/'all_checks.py')
    sys.argv=['all_checks.py','--output',str(out),'--tests',*pending]
    return runner.main()
if __name__=='__main__':raise SystemExit(main())
