"""Run pinned acceptance harnesses against the actual exported PCK."""
from pathlib import Path
import argparse,importlib.util,json,shutil
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
HOME=Path('C:/Users/64jus/AppData/Local/Temp/pn-p4-execution-20261024-v1')
GODOT='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
def main():
    p=argparse.ArgumentParser();p.add_argument('label');p.add_argument('--probe',default='route');p.add_argument('--input',type=Path);p.add_argument('--native',action='store_true');a=p.parse_args()
    sim=module('sim',ROOT/'tools/simulate.py');module('stream',ROOT/'docs/codex/findings/sidestreet-p2-p3-20261023-v1/stream_process.py').bind(sim)
    out=HOME/a.label;out.mkdir(exist_ok=False)
    manifest=sim.read_json(HOME/'p4-build-v1/p2-p3-export/build-manifest.json');pack=Path(manifest['workspace'])/'demo/Patch Notes Demo.pck'
    source=HERE/(a.probe+'.gd');harness=out/'harness.gd';shutil.copy2(source,harness)
    if a.probe=='native':
        # The package intentionally omits debug entry points. Freeze external
        # test inheritance and replace only its catalog bootstrap adapter, as
        # in the accepted P2/P3 compiled-native runner.
        base=ROOT/'patch-notes/scripts/debug/verify_campaign_live_parity.gd'
        parent=ROOT/'docs/codex/findings/sidestreet-p2-p3-20261023-v1/native.gd'
        base_text=base.read_text(encoding='utf8').replace('res://scripts/debug/campaign_replay_cli.gd','res://scripts/simulation/run_factory.gd').replace('recipe,root.get_node("CardDatabase")','recipe,root.get_node("CardDatabase").get_development_catalog()')
        (out/'native-base.gd').write_text(base_text,encoding='utf8')
        parent_text=parent.read_text(encoding='utf8').replace('res://scripts/debug/verify_campaign_live_parity.gd',(out/'native-base.gd').as_posix())
        (out/'native-parent.gd').write_text(parent_text,encoding='utf8')
        harness.write_text(source.read_text(encoding='utf8').replace(parent.as_posix(),(out/'native-parent.gd').as_posix()),encoding='utf8')
        sim.write_json(out/'native-helper-source.json',{'original':{str(p):sim.sha(p) for p in [base,parent,source]},'external':{str(p):sim.sha(p) for p in [out/'native-base.gd',out/'native-parent.gd',harness]},'scope':'External debug inheritance; production runtime stays inside the audited PCK. Only the existing test bootstrap passes the catalog directly to RunFactory.'})
    study=ROOT/'docs/codex/threads/contracts/studies'
    if a.probe=='route':args=[str(out),str(HOME/'p2-p3-short-names-v2')]
    elif a.probe=='world':args=[str(study/'sidestreet-commission-p1-20261023-v1/prefix_policy.gd'),str(study/'sidestreet-full-delivery-20261023-v1/policy.gd'),str(out/'world-result.json')]
    else:
        assert a.input is not None
        args=[str(out),str(a.input.resolve())]
    command=[GODOT,*([] if a.native else ['--headless']),'--main-pack',str(pack),'--script',str(harness),'--',*args]
    environment=sim.isolated_environment(out/'profile');environment['PN_CARD_FRAME_OUTPUT']=str(out/'native')
    sim.write_json(out/'inputs.json',{'pck':str(pack),'pck_sha256':sim.sha(pack),'harness_sha256':sim.sha(harness),'source':str(source),'scope':'Editor runtime using actual exported PCK; direct release EXE input is separate.'})
    sim.run_process('compiled',command,out,environment,600)
    print(json.dumps({'pass':True,'output':str(out),'release_ready':False}),flush=True)
if __name__=='__main__':main()
