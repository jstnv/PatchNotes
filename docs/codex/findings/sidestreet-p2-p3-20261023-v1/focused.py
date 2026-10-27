"""Affected maintained verifiers in a frozen project and isolated profiles."""
from pathlib import Path
import argparse,importlib.util,json,os,shutil
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
TASK=Path('C:/Users/64jus/AppData/Local/Temp/pn-sidestreet-canonical-20261023-v5')
GODOT='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
DEFAULT=['verify_begin_project_extraction','verify_contract_extraction','verify_launch_extraction','verify_beta_finalization_and_launch','verify_sales_earning_and_settlement','verify_publisher_relationships','verify_contract_definitions','verify_contract_challenge_runtime','verify_contract_challenge_publishers','verify_contract_challenge_matrix','verify_contract_presentation','verify_publisher_browser_states','verify_publisher_list_progression','verify_publisher_connections_ui','verify_publisher_trial_cash','verify_publisher_trial_offers','verify_publisher_trial_promotion','verify_publisher_trial_liquidity','verify_bank_finance','verify_bank_integration','verify_checkpoint_runtime','verify_studio_checkpoint','verify_campaign_session','verify_campaign_live_parity','verify_campaign_continuation','verify_rival_world_foundation','verify_legacy_world','verify_legacy_gameplay','verify_founder_foundation']
def module(name,path):
    s=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
def main():
    p=argparse.ArgumentParser();p.add_argument('--tag',required=True);p.add_argument('--tests',nargs='+',default=DEFAULT);a=p.parse_args()
    sim=module('sim',ROOT/'tools/simulate.py');gate=module('gate',ROOT/'tools/release_gate.py')
    out=TASK/a.tag;out.mkdir(exist_ok=False);project=out/'project';sim.copy_snapshot(ROOT/'patch-notes',project)
    auxiliary={}
    for leaf in ['m2a-v1','m2b-v1','m2c-v1','m2d-v1','m3a-v1','m3b-v1']:
        folder=ROOT/'docs/codex/threads/simulation-engine'/leaf
        for source in folder.rglob('*'):
            if source.is_file() and source.suffix in {'.gd','.json','.uid','.tscn'}:
                rel=source.relative_to(ROOT);destination=out/rel;destination.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,destination);auxiliary[rel.as_posix()]=sim.sha(source)
    sim.write_json(out/'auxiliary-source.json',auxiliary)
    source=sim.import_project(Path(GODOT),project,out,sim.isolated_environment(out/'import-profile'),180)
    checks=module('checks',ROOT/'docs/codex/findings/checkpoint-runtime-v1/run_checks.py')
    checks.HERE=out;checks.REPO=out;checks.PROJECT=project;checks.GODOT=GODOT;checks.PROFILE=out/'profiles'
    os.environ['PN_CHECKPOINT_TEST_PORT']='47733'
    selected=set(a.tests);report=[]
    for name,path in gate.verifier_jobs():
        if name not in selected:continue
        env=gate.verifier_environment(out,name)
        os.environ.update(env)
        artifact=out/'verifier-artifacts'/name;artifact.mkdir(parents=True,exist_ok=True)
        wrapper,meta=gate.checkpoint_wrapper(path,out/'wrappers')
        profile=gate.continuation_profile(out,'verify_rival_gameplay_activation') if name=='verify_rival_gameplay_cold_continue' else None
        try:checks.run(name,gate.verifier_arguments(out,name,str(wrapper)),timeout=600,profile=profile);ok=True
        except Exception as error:print(str(error),flush=True);ok=False
        report.append({'name':name,'pass':ok,'wrapper':meta});sim.write_json(out/'summary.json',report)
    sim.check_snapshot(project,source)
    missing=selected-{r['name'] for r in report}
    sim.write_json(out/'result.json',{'pass':not missing and all(r['pass'] for r in report),'checks':report,'missing':sorted(missing),'release_ready':False})
    return 0 if not missing and all(r['pass'] for r in report) else 1
if __name__=='__main__':raise SystemExit(main())
