from pathlib import Path
import importlib.util, json

ROOT=Path(__file__).resolve().parents[5]
spec=importlib.util.spec_from_file_location('runner',ROOT/'docs/codex/findings/card-presentation-v2/run.py')
runner=importlib.util.module_from_spec(spec);spec.loader.exec_module(runner)
scripts=['verify_design_phase','verify_alpha_phase','verify_beta_planning','verify_alpha_finalization','verify_beta_finalization_and_launch','verify_alpha_exit_arrears','verify_alpha_host_playtest','verify_beta_host_playtest','verify_atomic_selected_redraw','verify_redraw_class_parity','verify_shared_redraw_and_priority_adjustment','verify_candidate_retention','verify_first_game_scripted_tutorial','verify_gameplay_transition','verify_primitive_run_initialization','verify_design_command','verify_alpha_command','verify_beta_command','verify_gameplay_hud_overlay','verify_card_motion','verify_development_replay','verify_development_protocol']
results=[]
for script in scripts:
    label='m2d-check-'+script
    try:
        runner.run(label,script+'.gd')
        results.append({'script':script,'passed':True,'label':label})
    except BaseException as exc:
        results.append({'script':script,'passed':False,'label':label,'error':str(exc)})
    Path(__file__).with_name('check-results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
print('SUMMARY',sum(r['passed'] for r in results),'/',len(results),flush=True)
