"""Fresh presentation-corrected build for direct EXE P2/P3 acceptance."""
from pathlib import Path
import importlib.util,json,re,runpy,shutil,sys
ROOT=Path(__file__).resolve().parents[4]
HOME=Path('C:/Users/64jus/AppData/Local/Temp/pn-p4-execution-20261024-v1')
def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
def main():
    sim=module('sim',ROOT/'tools/simulate.py');export=module('export',ROOT/'docs/codex/findings/export-queue-v3/export.py')
    out=HOME/'p2-p3-export';out.mkdir(exist_ok=False)
    export.OUT=out;export.ROOT=ROOT/'patch-notes';before=sim.source_hashes(export.ROOT)
    names=[]
    for block in re.split(r'(?m)^\[',(export.ROOT/'export_presets.cfg').read_text(encoding='utf8')):
        if not re.match(r'preset\.\d+\]',block):continue
        name=re.search(r'(?m)^name="([^"]+)"',block)
        if 'platform="Windows Desktop"' in block and name:names.append(name[1])
    assert len(names)==1,names
    original=export.run
    def run(label,argv,env,cwd,timeout=180):
        argv=list(argv)
        if '--export-release' in argv:argv[argv.index('--export-release')+1]=names[0]
        return original(label,argv,env,cwd,timeout)
    export.run=run;sys.argv=[str(__file__)];export.main();sim.check_snapshot(export.ROOT,before)
    shutil.copy2(ROOT/'docs/codex/findings/export-queue-v3/inspect.py',out/'inspect.py');runpy.run_path(str(out/'inspect.py'),run_name='__main__')
    manifest=sim.read_json(out/'build-manifest.json');manifest['selected_current_windows_preset']=names[0];sim.write_json(out/'build-manifest.json',manifest)
    exe=Path(manifest['workspace'])/'demo/Patch Notes Demo.exe'
    for label,extra in [('headless',['--headless']),('graphical',[])]:
        run(label+'-startup',[exe,*extra,'--quit-after','90'],sim.isolated_environment(out/(label+'-profile')),out,120)
    sim.write_json(out/'source.json',before)
    print(json.dumps({'exe':str(exe),'package_pass':True,'startups_pass':True,'release_ready':False}),flush=True)
if __name__=='__main__':main()
