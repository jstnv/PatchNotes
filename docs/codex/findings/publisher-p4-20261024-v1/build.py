"""Fresh current P4 export; reuse the audited exporter without altering it."""
from pathlib import Path
import importlib.util,json
ROOT=Path(__file__).resolve().parents[4]
HOME=Path('C:/Users/64jus/AppData/Local/Temp/pn-p4-execution-20261024-v1')
def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
def main():
    sim=module('sim',ROOT/'tools/simulate.py')
    helper=ROOT/'docs/codex/findings/sidestreet-p2-p3-20261024-exe-v1/build.py'
    build=module('build',helper)
    # Its inner output leaf is retained for reproducibility; distinct parent.
    target=HOME/'p4-build-v1';target.mkdir(exist_ok=False)
    build.HOME=target;build.main()
    out=target/'p2-p3-export'
    sim.write_json(out/'helper-source.json',{'path':str(helper),'sha256':sim.sha(helper),'scope':'Current P4 source; earlier exporter wrapper reused unchanged.'})
    print(json.dumps({'build':str(out),'release_ready':False}))
if __name__=='__main__':main()
