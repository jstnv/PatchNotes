"""Prove the review finding with private verifier-only mutations, not UI edits."""
from pathlib import Path
import importlib.util,json
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
def module(name,path):
    s=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
def main():
    sim=module('mutation_sim',ROOT/'tools/simulate.py')
    module('mutation_stream',ROOT/'docs/codex/findings/sidestreet-p2-p3-20261023-v1/stream_process.py').bind(sim)
    home=Path('C:/Users/64jus/AppData/Local/Temp/pn-chooser-mutation-20261024-v1');home.mkdir(exist_ok=False)
    godot=Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
    rows=[]
    for mode in ['old-count-guard','exact-id-guard']:
        out=home/mode;out.mkdir();project=out/'project'
        sim.copy_snapshot(ROOT/'patch-notes',project)
        path=project/'scripts/debug/verify_sidestreet_contract.gd'
        text=path.read_text(encoding='utf8')
        anchor='\tfor index in range(chooser.item_count):\n'
        injection='\t# Verifier-only mutation: remove Brief row, retain cash/other publisher rows.\n\tfor remove_index in range(chooser.item_count-1,-1,-1):\n\t\tif not brief.is_empty() and chooser.get_item_metadata(remove_index) == brief.offer_id: chooser.remove_item(remove_index)\n'
        assert text.count(anchor)==1;text=text.replace(anchor,injection+anchor,1)
        if mode=='old-count-guard':text=text.replace('cash_index >= 0 and brief_index >= 0 and cash_index != brief_index','cash_index >= 0 and chooser.item_count >= 2',1)
        path.write_text(text,encoding='utf8')
        source=sim.import_project(godot,project,out,sim.isolated_environment(out/'import-profile'),180)
        sim.write_json(out/'source.json',source)
        command=[str(godot),'--headless','--path',str(project),'--script','res://scripts/debug/verify_sidestreet_contract.gd']
        failed=False
        try:sim.run_process('probe',command,out,sim.isolated_environment(out/'profile'),120)
        except RuntimeError:failed=True
        log=(out/'probe.log').read_text(encoding='utf8')
        if mode=='old-count-guard':assert not failed and 'SideStreet contract verification: 0 failures' in log
        else:assert failed and 'FAIL: Separate Reputation Brief and cash Contract are offered' in log and 'SideStreet contract verification: 1 failures' in log
        sim.check_snapshot(project,source)
        rows.append({'mode':mode,'expected_failure':mode=='exact-id-guard','failed':failed,'log':str(out/'probe.log'),'log_sha256':sim.sha(out/'probe.log'),'verifier_sha256':sim.sha(path)})
    sim.write_json(HERE/'chooser-mutation.json',{'pass':True,'scope':'Private test-only row removal: old count guard misses absent Brief; corrected exact-ID guard detects it. No canonical UI or gameplay mutation.','probes':rows})
    print(json.dumps({'pass':True,'probes':rows}),flush=True)
if __name__=='__main__':main()
