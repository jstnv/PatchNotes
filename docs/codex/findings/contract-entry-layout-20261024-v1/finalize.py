"""Fence the small UI delta and aggregate separately bounded test evidence."""
from pathlib import Path
import importlib.util,json,shutil,subprocess
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
TASK=Path('C:/Users/64jus/AppData/Local/Temp/pn-contract-layout-20261024-v1')
def read(path):return json.loads(path.read_text(encoding='utf8'))
def main():
    spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
    source=sim.source_hashes(ROOT/'patch-notes')
    native=sim.source_hashes(TASK/'native-final/project')
    assert source==native,'Canonical bytes must match the rendered isolated project, including the new verifier UID'
    first=read(TASK/'green/result.json');assert first['pass'] and len(first['checks'])==8
    final=read(TASK/'final-checks/result.json')
    assert len(final['checks'])==5 and all(row['pass'] for row in final['checks'])
    assert set(final['missing'])=={'verify_publisher_commission_migration','verify_publisher_relationship_migration','verify_rival_world_checkpoint'}
    selected=read(TASK/'final-checks/canonical-source.json')
    delta={key for key in set(source)|set(selected) if source.get(key)!=selected.get(key)}
    assert delta=={'scripts/debug/verify_card_fan_entry_layout.gd.uid'},delta
    maintained=[row['name'] for row in final['checks']]
    for tag,name in [('final-rival','verify_rival_world_foundation'),('final-relationships','verify_publisher_relationships'),('final-codec','verify_checkpoint_codec')]:
        command=read(TASK/tag/'check.command.json')
        assert command['exit']==0 and not command['errors']
        assert read(TASK/tag/'source.json')==source
        maintained.append(name)
    assert len(set(maintained))==8
    compat=read(TASK/'compat-final/result.json')
    assert compat['checks']==32 and compat['failures']==0
    assert read(TASK/'compat-final/source.json')==source
    probe=read(TASK/'native-final-v2/result.json')
    assert probe['pass'] and read(TASK/'native-final-v2/canonical-source.json')==source
    assert len(probe['probe'])==2 and all(row['tooltips'] for row in probe['probe'])
    # At native execution time canonical lacked only the generated debug UID.
    # It is now copied unchanged; the evidence is not relabeled or overwritten.
    before=sim.source_hashes(TASK/'project')
    changes={key:{'before':before.get(key),'after':source.get(key)} for key in sorted(set(source)|set(before)) if source.get(key)!=before.get(key)}
    runtime_changes={key:value for key,value in changes.items() if not key.startswith('scripts/debug/') and not key.endswith(('.uid','.import'))}
    assert set(runtime_changes)=={'scripts/ui/card_fan.gd','scripts/market/rival_world_checkpoint.gd'}
    sim.write_json(HERE/'source.json',source)
    sim.write_json(HERE/'runtime-delta.json',runtime_changes)
    sim.write_json(HERE/'verification.json',{'pass':True,'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'source':compat['source'],'maintained_final':maintained,'entry':'38 checks / 0 failures','upper_fan':'1740 / 0','world_foundation':'156 / 0','relationships':'43 / 0','codec':'46 / 0','actual_prior_worlds':compat,'native':probe['probe'],'source_boundary':'Native project and all external final checks match canonical bytes exactly after copying only the generated verifier UID. Five maintained runs predate that debug UID only. Original result.json canonical_unchanged=false is retained, not rewritten.','retained_initial_failures':{'entry':'30 checks / 14 failures','tooltip':'32 checks / 2 failures','compat':'24 checks / 4 failures','harness':'probe and compatibility parse errors retained; fixed explicit Variant/RefCounted/String annotations'},'runner_missing_jobs':{'not_run':final['missing'],'corrected_checks':maintained[-3:],'note':'Original aggregate remains false because nonexistent suite names were requested. All five executed checks passed; the actual relevant suites above and unmodified old-world checks passed separately.'},'release_ready':False,'limits':['No new export or actual release EXE interaction.','Existing missing artwork warnings and six ObjectDB shutdown instances remain.','P4 mechanics remain unimplemented; latest Contract correction took precedence.']})
    artifacts={}
    for tag in ['red','probe-v2','green','compat-red','compat-red-v2','compat-red-v3','tooltip-red','native-final','native-final-v2','final-checks','compat-final','final-rival','final-relationships','final-codec']:
        folder=TASK/tag
        for path in folder.iterdir():
            if path.is_file() and path.suffix in {'.log','.json','.png','.gd'}:
                artifacts[path.relative_to(TASK).as_posix()]={'bytes':path.stat().st_size,'sha256':sim.sha(path)}
    for kind in ['world-operator','compiled-world']:
        for suffix in ['.fixture.json','.operator-fixture.json']:
            path=Path('C:/Users/64jus/AppData/Local/Temp/pn-sidestreet-canonical-20261023-v5')/kind/('result.json'+suffix)
            artifacts[str(path)]={'bytes':path.stat().st_size,'sha256':sim.sha(path)}
    sim.write_json(HERE/'external-artifacts.json',{'root':str(TASK),'files':artifacts})
    for leaf in ['entry-1152.png','tooltip-1280.png']:
        shutil.copy2(TASK/'native-final-v2'/leaf,HERE/leaf)
    print(json.dumps({'pass':True,'maintained':len(maintained),'compat_checks':32,'source':compat['source'],'runtime_paths':sorted(runtime_changes)}))
if __name__=='__main__':main()
